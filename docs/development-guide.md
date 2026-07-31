# Guía de desarrollo

## Rama de trabajo

Para refactors de organización usar:

```powershell
git switch refactor/code-organization
```

No hacer refactors grandes directamente en `master`.

## Flujo recomendado

1. Revisar estado:

```powershell
git status --short --branch
```

2. Ejecutar checks antes del cambio.
3. Hacer un cambio pequeño.
4. Formatear y analizar.
5. Ejecutar tests relevantes.
6. Revisar diff.
7. Commit pequeño y descriptivo.

## Reglas de refactor

- No cambiar diseño visual durante refactors técnicos.
- No renombrar rutas sin necesidad.
- No mover lógica y cambiar comportamiento en el mismo commit.
- No tocar credenciales ni archivos ignorados.
- No mezclar landing pública y app Flutter.
- Mantener `/app/` como base de la app web.

## Archivos a tratar con cuidado

- `apps/mobile/lib/src/app.dart`
- `apps/mobile/lib/src/features/portal/portal_screens.dart`
- `apps/mobile/lib/src/dependencies.dart`
- `packages/data/lib/src/local_repositories.dart`
- `packages/design_system/lib/design_system.dart`
- `.github/workflows/habitarpy-pages.yml`
