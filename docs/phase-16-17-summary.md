# Fases 16 y 17 - Experiencia inicial y sesion

## Fase 16: identidad visual inicial

Implementado:

- Bienvenida propia en `/onboarding` para primer uso.
- Ajuste del tema con superficies mas calidas, botones consistentes y campos con borde.
- Cabecera visual en registro y panel semanal.
- Panel semanal con resumen de intencion para el dia.

## Fase 17: onboarding, login y logout

Implementado:

- `AuthRepository` ahora expone `signIn` y `signOut`.
- `SessionService` encapsula entrada y salida de sesion.
- Repositorios en memoria y locales soportan login/logout.
- Supabase Auth soporta `signInWithPassword` y `signOut`.
- Ruta `/login` con formulario y manejo de error.
- Boton de cerrar sesion en el panel semanal.
- Restauracion inicial: sin usuario lleva a onboarding; con datos locales sigue recuperando familia, perfil y sesion activa.

Notas:

- Supabase valida credenciales reales cuando se ejecuta con `SUPABASE_URL` y `SUPABASE_ANON_KEY`.
- Familias, perfiles y rutinas siguen persistiendo localmente. La lectura/escritura remota de esas tablas queda como siguiente integracion.
- La clave publishable de Supabase no debe guardarse en el repositorio.

## Verificacion esperada

- `dart analyze packages/application`
- `dart analyze packages/data`
- `dart test packages/data`
- `flutter analyze apps/mobile`
- `flutter test apps/mobile`
- `flutter build web --debug`
