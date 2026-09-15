// Etapa 3 (notificaciones push). Orquesta lo que ninguna capa de mas abajo
// puede hacer sola: pedir el token real a Firebase, guardarlo con
// DeviceTokenRepository, escuchar su rotacion, pedir permiso en el momento
// adecuado (nunca al arrancar), y re-mostrar como notificacion local un
// push que llega con la app en primer plano. Vive en apps/mobile porque
// mezcla a proposito cosas especificas de esta app (go_router, el gateway
// de Firebase, LocalStore) - mismo criterio que local_restore.dart, que
// tampoco vive en un paquete compartido.

import 'dart:io';

import 'package:habitar_application/application.dart';
import 'package:habitar_data/data.dart';
import 'package:habitar_notifications/notifications.dart' as notifications;
import 'package:flutter/material.dart';

import 'platform/push_messaging_gateway.dart';

class PushNotificationService {
  PushNotificationService({
    required this.gateway,
    required this.deviceTokenRepository,
    required this.reminderScheduler,
    this.localStore,
  });

  final PushMessagingGateway gateway;
  final DeviceTokenRepository deviceTokenRepository;
  final notifications.LocalReminderScheduler reminderScheduler;
  final LocalStore? localStore;

  String? _currentToken;
  String? _currentUserId;
  Stream<String>? _tokenRefreshBroadcast;
  bool _listening = false;

  static const _permissionPromptedFlagId = 'push_permission_prompted';

  /// Se llama al iniciar sesión y en cada arranque de la app con una
  /// sesión ya activa (ver startup_screen.dart) - las dos veces es
  /// intencional: cubre tanto el login recien hecho (necesita el token
  /// guardado ya, sin esperar al proximo reinicio) como el caso, mucho
  /// mas comun, de reabrir la app con la sesión ya iniciada de antes
  /// (donde no hay ningun evento de "login" que hookear en esta misma
  /// corrida de la app).
  /// Deliberadamente best-effort: quien llama a esto lo hace desde un
  /// flujo de login/arranque que tiene que poder seguir aunque el
  /// registro del token falle por lo que sea (sin red, Firebase sin
  /// inicializar bien, lo que sea) - mismo criterio que la purga
  /// aislada en su propio bloque en 0014_family_deletion.sql: nunca
  /// dejar que una funcionalidad secundaria tumbe una primaria.
  Future<void> registerCurrentDevice(String userId) async {
    _currentUserId = userId;
    try {
      final token = await gateway.getToken();
      if (token == null) {
        // Sin permiso resuelto todavia, o sin conexión la primera vez -
        // no es un error, simplemente no hay nada que guardar todavía.
        return;
      }
      _currentToken = token;
      await deviceTokenRepository.registerToken(
        userId: userId,
        token: token,
        platform: _platformName(),
      );
      _ensureListeningForTokenRefresh();
    } catch (_) {
      // Best-effort - ver el comentario de arriba.
    }
  }

  void _ensureListeningForTokenRefresh() {
    if (_listening) return;
    _listening = true;
    (_tokenRefreshBroadcast ??= gateway.onTokenRefresh.asBroadcastStream())
        .listen((newToken) async {
      final userId = _currentUserId;
      if (userId == null) return;
      _currentToken = newToken;
      try {
        await deviceTokenRepository.registerToken(
          userId: userId,
          token: newToken,
          platform: _platformName(),
        );
      } catch (_) {
        // Best-effort, igual que registerCurrentDevice.
      }
    });
  }

  /// Se llama al cerrar sesión, con el token de ESTE dispositivo -
  /// deliberadamente no borra los tokens de otros dispositivos de la
  /// misma cuenta (ver el comentario de DeviceTokenRepository.deleteToken).
  /// gateway.deleteToken() ademas invalida el token del lado de Firebase,
  /// para que el proximo registro (otra cuenta, u otra sesión) obtenga
  /// uno nuevo en vez de reusar uno que ya quedo huerfano en nuestra base.
  ///
  /// Best-effort de punta a punta, igual que registerCurrentDevice: cerrar
  /// sesión tiene que poder completarse aunque esto falle (sin red al
  /// momento de cerrar sesión, por ejemplo) - el token queda huérfano en
  /// device_tokens en ese caso, pero se auto-limpia solo la próxima vez
  /// que la Edge Function le intente mandar algo y FCM lo rechace.
  Future<void> unregisterCurrentDevice() async {
    final token = _currentToken;
    _currentUserId = null;
    _currentToken = null;
    if (token == null) return;
    try {
      await deviceTokenRepository.deleteToken(token);
      await gateway.deleteToken();
    } catch (_) {
      // Best-effort - ver el comentario de arriba.
    }
  }

  /// Explica brevemente por qué antes de mostrar el diálogo del sistema, y
  /// solo lo hace una vez por dispositivo (no por usuario: el permiso es
  /// del sistema operativo, no de la cuenta) - ver
  /// docs/prototipo-habitar.md y el pedido de la etapa 3: pedirlo al
  /// arrancar baja mucho la aceptación. Se llama desde la primera entrada
  /// a Familia o al crear una rutina.
  Future<void> requestPermissionIfNeeded(BuildContext context) async {
    if (await _alreadyPrompted()) return;
    if (!context.mounted) return;
    final proceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Avisos para toda la familia'),
            content: const Text(
              'Si los activás, vas a enterarte cuando alguien termine una '
              'rutina, sin tener que abrir Habitar todo el tiempo. Podés '
              'cambiar esto cuando quieras desde Cuenta.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Ahora no'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Activar avisos'),
              ),
            ],
          ),
        ) ??
        false;
    await _markPrompted();
    if (!proceed) return;
    await gateway.requestPermission();
  }

  /// Sin LocalStore no hay forma de recordar si ya se preguntó - tratarlo
  /// como "todavía no" mostraría el diálogo en cada build, algo mucho peor
  /// que la molestia que esto mismo busca evitar. En producción
  /// (app_environment_io.dart) siempre hay un LocalStore real; esto solo
  /// importa en tests/web, donde el default es null - y ahí el
  /// comportamiento correcto es igual "no preguntar nunca sin poder
  /// recordar la respuesta", no una casualidad conveniente para testear.
  Future<bool> _alreadyPrompted() async {
    final store = localStore;
    if (store == null) return true;
    final record =
        await store.get(LocalStoreCollections.appFlags, _permissionPromptedFlagId);
    return record != null;
  }

  Future<void> _markPrompted() async {
    final store = localStore;
    if (store == null) return;
    await store.put(
      LocalStoreCollections.appFlags,
      _permissionPromptedFlagId,
      {'prompted_at': DateTime.now().toUtc().toIso8601String()},
    );
  }

  /// Cablea los tres estados de recepción - se llama una sola vez, desde
  /// _HabitarMobileAppState.initState(). [onNotificationTapped] recibe el
  /// payload (routine_id/profile_id) armado por la Edge Function.
  void listenForMessages({
    required void Function(Map<String, String> data) onNotificationTapped,
  }) {
    // App abierta: FCM no la muestra solo (a diferencia de segundo
    // plano/cerrada) - hay que decidir que hacer, y acá se decide
    // re-mostrarla como notificación local, vía el mismo plugin que ya
    // usan los recordatorios de rutina.
    gateway.onMessage.listen((message) async {
      await reminderScheduler.showNow(
        id: 'push-${DateTime.now().microsecondsSinceEpoch}',
        title: message.title ?? '¡Rutina completada! 🎉',
        body: message.body ?? '',
        channelId: 'push_notifications',
      );
    });

    // App en segundo plano, el usuario toca la notificación del sistema.
    gateway.onMessageOpenedApp.listen((message) {
      onNotificationTapped(message.data);
    });

    // App cerrada del todo, se abrió porque el usuario tocó la
    // notificación - se resuelve una sola vez, al arrancar.
    gateway.getInitialMessage().then((message) {
      if (message != null) onNotificationTapped(message.data);
    });
  }

  String _platformName() {
    if (Platform.isIOS) return 'ios';
    return 'android';
  }
}
