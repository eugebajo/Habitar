# Deploy

## Web

La web se publica con GitHub Pages desde:

```text
.github/workflows/habitarpy-pages.yml
```

El workflow:

1. Instala Flutter.
2. Compila la app web con base `/app/`.
3. Copia el build a `sites/habitarpy/app`.
4. Publica `sites/habitarpy` en GitHub Pages.

URLs:

- Landing: `https://habitarpy.com`
- App web: `https://habitarpy.com/app/`
- Privacidad: `https://habitarpy.com/privacy/`
- Términos: `https://habitarpy.com/terms/`

## Android

La preparación Android vive en:

- `apps/mobile/android`
- `scripts/android_build_release.ps1`
- `docs/play-console-upload-steps.md`
- `docs/phase-21-play-store-readiness.md`

Google Play Console sigue siendo requisito externo para publicar. Mientras la cuenta esté en verificación, se puede preparar el paquete, documentación, capturas y prueba cerrada, pero no completar publicación pública.

## iOS

La publicación iOS requiere preparar App Store Connect, certificados, identificador de bundle, perfiles de firma y revisión de privacidad.

## Dominios

Habitar usa `habitarpy.com`. No mezclar este dominio con ASULUGAR para evitar confusión de marca.
