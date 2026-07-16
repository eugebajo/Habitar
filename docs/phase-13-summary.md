# Fase 13: Supabase Auth

## Implementado

- `SupabaseAuthGateway` como puerto minimo para `signUp` y usuario actual.
- `SupabaseAuthRepository` que adapta el usuario de Supabase al dominio `User`.
- Pruebas con gateway falso para registro y recuperacion de usuario actual.
- `SupabaseConfig.fromEnvironment()` sigue siendo la fuente de `SUPABASE_URL` y `SUPABASE_ANON_KEY`.

## Pendiente

- Agregar `supabase_flutter` en mobile cuando el proyecto Supabase real este creado.
- Implementar el gateway concreto usando `Supabase.instance.client.auth`.
- Unir Auth real con creacion/lectura de familia y RLS en la base remota.
- Pantallas de login/logout y recuperacion de sesion remota.
