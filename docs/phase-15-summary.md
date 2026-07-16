# Fase 15: Supabase Auth real en Flutter

## Implementado

- Dependencia `supabase_flutter` agregada a la app mobile.
- Gateway real `FlutterSupabaseAuthGateway` usando `SupabaseClient.auth`.
- Inicializacion opcional con `Supabase.initialize` cuando existen `SUPABASE_URL` y `SUPABASE_ANON_KEY`.
- Fallback a `LocalAuthRepository` cuando no se pasan variables de entorno.
- Uso de `publishableKey` para compatibilidad con las keys nuevas de Supabase.

## Como ejecutar con Supabase

```powershell
cd apps/mobile
flutter run `
  --dart-define=SUPABASE_URL=https://frmgwpbstezqjwbcshbw.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_REEMPLAZAR
```

## Pendiente

- Crear flujo de login/logout.
- Ejecutar migraciones SQL en Supabase.
- Conectar familias/perfiles remotos con RLS.
- Persistir sesion remota junto con recuperacion local.
