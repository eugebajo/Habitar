# Flujo de datos

## Resumen

Habitar usa repositorios definidos en `packages/application` y sus implementaciones viven en `packages/data`.

```text
Pantalla
  -> servicio de aplicación
  -> contrato de repositorio
  -> implementación local o gateway
  -> almacenamiento
```

## Persistencia local

En plataformas con sistema de archivos, la app usa almacenamiento local preparado con Drift/SQLite.

En web, la app usa almacenamiento del navegador para conservar una experiencia usable en `https://habitarpy.com/app/`.

## Supabase

Supabase Auth está integrado para registro, login y logout cuando la app recibe:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

La sincronización remota completa de datos de familia, perfiles, rutinas, hábitos, bienestar y progreso sigue pendiente.

## Datos sensibles

No se deben commitear:

- Service role keys de Supabase.
- Keystores de Android.
- Archivos `.env` reales.
- Credenciales de Play Store o Apple.

La publishable key de Supabase puede usarse en cliente, pero debe configurarse por entorno para evitar copiarla en código fuente.
