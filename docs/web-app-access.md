# Habitar - Acceso web de la app

Habitar tendrá dos superficies públicas en el mismo dominio:

- Sitio público: `https://habitarpy.com`
- App web: `https://habitarpy.com/app/`

## Qué incluye la app web

La app web publica la misma experiencia Flutter del MVP:

- Registro adulto.
- Login adulto.
- Selector de perfiles.
- Espacio adulto.
- Modo niño.
- Modo adolescente.
- Rutinas.
- Hábitos.
- Check-in de bienestar.
- Privacidad y términos dentro de la app.

## Cómo se publica

El workflow `Habitarpy Pages` compila Flutter Web con:

```powershell
flutter build web --release --base-href /app/
```

Después copia el resultado a:

```text
sites/habitarpy/app/
```

GitHub Pages publica todo junto en `habitarpy.com`.

## Estado actual importante

La app web MVP usa Supabase Auth cuando se compila con `SUPABASE_URL` y
`SUPABASE_ANON_KEY`. Los datos de familia, perfiles, rutinas, hábitos y
check-ins se guardan localmente en el navegador hasta que implementemos los
repositorios Supabase de datos.

Para que una persona tenga la misma cuenta en web, Android e iOS, necesitamos:

1. Supabase Auth de producción.
2. Build web con `SUPABASE_URL` y `SUPABASE_ANON_KEY`.
3. Build Android/iOS con los mismos `dart-define`.
4. Repositorios Supabase para familias, perfiles, rutinas, hábitos y bienestar.
5. Reglas de acceso por usuario/familia.
6. Revisión actualizada de privacidad y data safety.

## Variables de GitHub Pages

Configurar en GitHub:

- `SUPABASE_URL` como repository variable.
- `SUPABASE_ANON_KEY` como repository secret.

El workflow `Habitarpy Pages` inyecta esas variables durante el build web.

Ver pasos detallados en `docs/supabase-activation.md`.

## Decisión de producto

Habitar puede ser móvil primero y también tener acceso web. La web no reemplaza
Android/iOS; sirve para familias, tutores y profesionales que prefieren gestionar
rutinas desde computadora o navegador.
