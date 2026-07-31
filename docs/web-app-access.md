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

La app web MVP usa almacenamiento local/in-memory en navegador si no se compila
con Supabase de producción. Esto permite probar funciones, pantallas y flujo,
pero no garantiza sincronización real entre dispositivos.

Para que una persona tenga la misma cuenta en web, Android e iOS, necesitamos:

1. Supabase de producción.
2. Reglas de acceso por usuario/familia.
3. Build web con `SUPABASE_URL` y `SUPABASE_ANON_KEY`.
4. Build Android/iOS con los mismos `dart-define`.
5. Revisión actualizada de privacidad y data safety.

## Decisión de producto

Habitar puede ser móvil primero y también tener acceso web. La web no reemplaza
Android/iOS; sirve para familias, tutores y profesionales que prefieren gestionar
rutinas desde computadora o navegador.
