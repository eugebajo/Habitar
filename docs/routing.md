# Rutas

La navegación principal vive en `apps/mobile/lib/src/app.dart` y usa GoRouter.

## Rutas públicas y de acceso

- `/`
- `/onboarding`
- `/login`
- `/register`
- `/recover`
- `/privacy`
- `/terms`

## Familia y perfiles

- `/profile`
- `/profiles`
- `/adult-pin`
- `/dashboard`

## Espacio adulto

- `/routines`
- `/progress`
- `/habits/list`
- `/rewards`
- `/settings`
- `/habits`
- `/notifications`
- `/routine/create`
- `/routine/player`
- `/wellbeing`
- `/stories`
- `/wearables`

## Espacio infantil

- `/child`
- `/kid`
- `/child/achievements`
- `/child/stories`
- `/child/emotions`

## Espacio adolescente

- `/teen`
- `/teen/habits`
- `/teen/progress`
- `/teen/reflection`
- `/teen/privacy`

## Restricciones

La app web se publica bajo `/app/`, por lo que el build debe mantener:

```powershell
flutter build web --release --base-href /app/
```

No cambiar rutas sin revisar también:

- Capturas de tienda.
- Links de la landing.
- GitHub Pages.
- Tests de navegación.
- Documentación pública.
