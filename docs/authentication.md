# Autenticación

## Estado actual

La app soporta Supabase Auth a través de `packages/data` y el gateway Flutter en:

- `packages/data/lib/src/supabase_config.dart`
- `packages/data/lib/src/supabase_auth_repository.dart`
- `apps/mobile/lib/src/platform/supabase_flutter_auth_gateway.dart`

La app puede funcionar sin Supabase configurado usando fallback local, útil para desarrollo y pruebas.

## Variables requeridas

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

En GitHub Pages, `SUPABASE_URL` debe configurarse como variable y `SUPABASE_ANON_KEY` como secreto del entorno `github-pages`.

## Registro

El registro de adulto crea una cuenta de autenticación cuando Supabase está configurado. Si el correo ya existe, Supabase puede rechazar el registro; la app muestra un mensaje amigable para que la persona intente entrar o revise los datos.

## Pendiente

- Recuperación de contraseña conectada completamente al proveedor.
- Escritura remota de familia y perfiles.
- Políticas RLS verificadas con pruebas de integración.
- Manejo de sesión multi-dispositivo.
