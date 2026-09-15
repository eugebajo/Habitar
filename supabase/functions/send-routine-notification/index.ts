// Etapa 3 (notificaciones push entre dispositivos) - Parte 2.
//
// Disparo: NO un trigger de base de datos. La llama un cron externo a
// Supabase (GitHub Actions, cada 5 minutos - ver
// .github/workflows/send-routine-notifications.yml) que le hace un POST
// vacío a esta URL. Se decidió así, y no con pg_net + un trigger + un
// secreto de service_role guardado en Supabase Vault, después de pesar el
// riesgo explícitamente: esta app maneja datos de menores, y cada secreto
// que vive DENTRO de la base es una superficie de ataque permanente si
// alguna vez alguien logra ejecutar SQL arbitrario ahí. Sin trigger, sin
// pg_net, sin Vault - la base de datos no tiene ninguna capacidad de
// iniciar una conexión de red saliente. El costo real es la inmediatez
// (hasta 5 minutos de demora) y que esta función tiene que resolver sus
// propios reintentos con notification_attempts en vez de que Postgres se
// lo garantice atómicamente - ver claim_pending_routine_notifications en
// supabase/migrations/0015_device_tokens.sql.
//
// Cada corrida:
//   1. Reclama hasta 50 eventos pendientes (claim_pending_routine_
//      notifications) - esto ya incrementa notification_attempts de cada
//      uno, así que un evento que esta corrida no llegue a marcar como
//      enviado (por un crash, un timeout, lo que sea) simplemente vuelve
//      a aparecer en la próxima, hasta agotar el tope de intentos o la
//      ventana de 6 horas que la migración ya define - acá no hay que
//      reimplementar ningún límite de reintentos.
//   2. Por cada evento, resuelve destinatarios (resolve_routine_
//      notification_recipients) - ya excluye a quien completó la rutina,
//      respeta push_enabled y el horario silencioso.
//   3. Manda un mensaje FCM HTTP v1 por token.
//   4. Token que FCM reporta UNREGISTERED o INVALID_ARGUMENT: se borra de
//      device_tokens ahí mismo - si no, la tabla se llena de basura y
//      cada corrida se hace más lenta con cada envío fallido repetido.
//   5. Marca el evento como procesado (mark_routine_notification_sent) -
//      tanto si mandó al menos un push como si no había ningún
//      destinatario (las dos cuentan como "ya no hay nada más que hacer
//      con este evento").
//
// Variables de entorno que esta función necesita (ver README.md al lado
// de este archivo para los pasos exactos de carga):
//   FIREBASE_SERVICE_ACCOUNT_JSON  - el JSON completo de la cuenta de
//                                    servicio de Firebase, como un solo
//                                    string. Nunca se guarda en el repo,
//                                    nunca la ve Flutter.
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY - NO hace falta cargarlas:
//                                    Supabase las inyecta solas en el
//                                    entorno de toda Edge Function.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const FCM_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';
const MAX_EVENTS_PER_RUN = 50;

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

interface ClaimedEvent {
  event_id: string;
  family_id: string;
  profile_display_name: string;
  routine_title: string;
  routine_id: string | null;
  profile_id: string;
  created_by: string | null;
  notification_attempts: number;
}

interface Recipient {
  recipient_user_id: string;
  token: string;
  platform: string;
}

Deno.serve(async (_request) => {
  const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_JSON');
  if (!serviceAccountJson) {
    console.error('send-routine-notification: falta FIREBASE_SERVICE_ACCOUNT_JSON');
    return new Response(
      JSON.stringify({ error: 'FIREBASE_SERVICE_ACCOUNT_JSON no configurada' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    );
  }
  let serviceAccount: ServiceAccount;
  try {
    serviceAccount = JSON.parse(serviceAccountJson);
  } catch (_error) {
    console.error('send-routine-notification: FIREBASE_SERVICE_ACCOUNT_JSON no es JSON válido');
    return new Response(
      JSON.stringify({ error: 'FIREBASE_SERVICE_ACCOUNT_JSON malformada' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    );
  }

  // SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY las inyecta la plataforma
  // sola en toda Edge Function - no son un secreto que el usuario tenga
  // que cargar acá (a diferencia de FIREBASE_SERVICE_ACCOUNT_JSON, que sí).
  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

  const { data: claimed, error: claimError } = await supabase.rpc(
    'claim_pending_routine_notifications',
    { p_max_events: MAX_EVENTS_PER_RUN },
  );
  if (claimError) {
    // Nunca volcar el objeto de error completo de Postgres tal cual - no
    // debería traer nada de un usuario, pero por las dudas se registra
    // solo el mensaje.
    console.error('send-routine-notification: fallo al reclamar eventos:', claimError.message);
    return new Response(JSON.stringify({ error: 'claim failed' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const events = (claimed ?? []) as ClaimedEvent[];
  if (events.length === 0) {
    return new Response(JSON.stringify({ processed: 0, sent: 0 }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  // Un solo access token de FCM para toda la corrida - dura una hora,
  // mucho más que lo que tarda procesar hasta 50 eventos.
  const accessToken = await getFcmAccessToken(serviceAccount);

  let sentCount = 0;
  let processedCount = 0;

  for (const event of events) {
    try {
      const { data: recipients, error: resolveError } = await supabase.rpc(
        'resolve_routine_notification_recipients',
        { p_event_id: event.event_id },
      );
      if (resolveError) {
        console.error(
          `send-routine-notification: fallo al resolver destinatarios para event_id=${event.event_id}:`,
          resolveError.message,
        );
        await recordFailure(supabase, event.event_id, 'resolve_failed');
        continue;
      }

      const title = '¡Rutina completada! 🎉';
      const body = `${event.profile_display_name} terminó '${event.routine_title}'.`;
      const data: Record<string, string> = {
        type: 'routine_completed',
        profile_id: event.profile_id,
      };
      if (event.routine_id) {
        data.routine_id = event.routine_id;
      }

      for (const recipient of (recipients ?? []) as Recipient[]) {
        const result = await sendFcmMessage({
          projectId: serviceAccount.project_id,
          accessToken,
          token: recipient.token,
          title,
          body,
          data,
        });

        if (result.outcome === 'sent') {
          sentCount++;
        } else if (result.outcome === 'invalid_token') {
          // FCM ya no reconoce este token (desinstalado, token rotado sin
          // que nadie lo haya vuelto a registrar, etc.) - se borra ahora,
          // no se deja para que otra corrida lo vuelva a intentar y
          // vuelva a fallar. Nunca se loguea el token en sí, solo que se
          // borró uno.
          const { error: deleteError } = await supabase
            .from('device_tokens')
            .delete()
            .eq('token', recipient.token);
          if (deleteError) {
            console.error(
              'send-routine-notification: fallo al borrar un token invalido (no se expone el token):',
              deleteError.message,
            );
          }
        } else {
          console.error(
            `send-routine-notification: fallo al enviar para event_id=${event.event_id}, recipient_user_id=${recipient.recipient_user_id}: ${result.errorCode ?? 'unknown'}`,
          );
        }
      }

      // Se marca "hecho" tanto si se mandó al menos un push como si no
      // había ningún destinatario (push_enabled=false para todos,
      // horario silencioso, o el único otro adulto sin ningún
      // dispositivo registrado todavía) - las dos son un resultado válido,
      // no un fallo a reintentar.
      const { error: markError } = await supabase.rpc(
        'mark_routine_notification_sent',
        { p_event_id: event.event_id },
      );
      if (markError) {
        console.error(
          `send-routine-notification: fallo al marcar event_id=${event.event_id} como procesado:`,
          markError.message,
        );
        // No se cuenta como procesado - queda para la próxima corrida.
        // notification_attempts ya se incrementó al reclamarlo, así que
        // esto también converge dentro del tope de 5 intentos.
        continue;
      }
      processedCount++;
    } catch (error) {
      // Un evento que revienta por algo inesperado nunca debe tumbar el
      // resto del lote - se registra y se sigue con el próximo.
      console.error(
        `send-routine-notification: excepción inesperada procesando event_id=${event.event_id}:`,
        error instanceof Error ? error.message : String(error),
      );
    }
  }

  return new Response(
    JSON.stringify({ processed: processedCount, sent: sentCount, claimed: events.length }),
    { status: 200, headers: { 'Content-Type': 'application/json' } },
  );
});

async function recordFailure(
  // deno-lint-ignore no-explicit-any
  supabase: any,
  eventId: string,
  reason: string,
) {
  const { error } = await supabase
    .from('family_activity_events')
    .update({ notification_last_error: reason })
    .eq('id', eventId);
  if (error) {
    console.error('send-routine-notification: fallo al registrar notification_last_error:', error.message);
  }
}

type SendOutcome = 'sent' | 'invalid_token' | 'other_error';

async function sendFcmMessage(options: {
  projectId: string;
  accessToken: string;
  token: string;
  title: string;
  body: string;
  data: Record<string, string>;
}): Promise<{ outcome: SendOutcome; errorCode?: string }> {
  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${options.projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${options.accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token: options.token,
          notification: { title: options.title, body: options.body },
          data: options.data,
          android: { priority: 'high' },
        },
      }),
    },
  );

  if (response.ok) {
    return { outcome: 'sent' };
  }

  let errorCode: string | undefined;
  try {
    const payload = await response.json();
    // FCM HTTP v1 devuelve el código en details[].errorCode, con el
    // status ('INVALID_ARGUMENT', 'UNREGISTERED', etc.) en
    // error.status - se busca en los dos lugares por las dudas.
    errorCode =
      payload?.error?.status ??
      payload?.error?.details?.find((d: { errorCode?: string }) => d.errorCode)?.errorCode;
  } catch (_error) {
    // Respuesta sin JSON - se sigue sin código, se clasifica como
    // 'other_error' más abajo.
  }

  if (errorCode === 'UNREGISTERED' || errorCode === 'INVALID_ARGUMENT') {
    return { outcome: 'invalid_token', errorCode };
  }
  return { outcome: 'other_error', errorCode };
}

// --- Autenticación de servidor a servidor con Firebase, sin dependencias
// --- externas de JWT: arma y firma el JWT a mano con Web Crypto (RS256),
// --- lo cambia por un access token en el endpoint OAuth2 de Google. Es el
// --- flujo estándar "self-signed JWT" que Google documenta para cuentas
// --- de servicio.

async function getFcmAccessToken(serviceAccount: ServiceAccount): Promise<string> {
  const nowSeconds = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT' };
  const claims = {
    iss: serviceAccount.client_email,
    scope: FCM_SCOPE,
    aud: 'https://oauth2.googleapis.com/token',
    iat: nowSeconds,
    exp: nowSeconds + 3600,
  };

  const encoder = new TextEncoder();
  const headerSegment = base64UrlEncode(encoder.encode(JSON.stringify(header)));
  const claimsSegment = base64UrlEncode(encoder.encode(JSON.stringify(claims)));
  const signingInput = `${headerSegment}.${claimsSegment}`;

  const privateKey = await importPrivateKey(serviceAccount.private_key);
  const signature = await crypto.subtle.sign(
    { name: 'RSASSA-PKCS1-v1_5' },
    privateKey,
    encoder.encode(signingInput),
  );
  const jwt = `${signingInput}.${base64UrlEncode(new Uint8Array(signature))}`;

  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });

  if (!tokenResponse.ok) {
    const text = await tokenResponse.text();
    throw new Error(`No se pudo obtener el access token de Firebase: ${tokenResponse.status} ${text}`);
  }

  const tokenPayload = await tokenResponse.json();
  return tokenPayload.access_token as string;
}

async function importPrivateKey(pem: string): Promise<CryptoKey> {
  const pemBody = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s+/g, '');
  const binaryDer = base64Decode(pemBody);
  return crypto.subtle.importKey(
    'pkcs8',
    binaryDer,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
}

function base64UrlEncode(bytes: Uint8Array): string {
  let binary = '';
  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function base64Decode(base64: string): ArrayBuffer {
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes.buffer;
}
