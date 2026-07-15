# Habitar

Aplicacion movil de acompanamiento de habitos, rutinas y autonomia para ninos y adolescentes con perfiles AuDHD.

El nombre del producto es provisional y no esta acoplado al codigo. La base tecnica usa un monorepo con Flutter para la app movil principal y paquetes Dart separados para dominio, aplicacion, datos, accesibilidad, notificaciones y sistema de diseno.

## Estado de Fase 1

Implementado:

- Monorepo inicial.
- App Flutter base en `apps/mobile`.
- Separacion `domain`, `application`, `data`, `presentation` y preparacion de integraciones de plataforma.
- Modelos iniciales del dominio.
- Politica de activacion gradual de habitos nuevos.
- Flujo base de registro adulto y creacion de perfil infantil/adolescente.
- Navegacion base con GoRouter.
- Tokens de diseno y tema de baja estimulacion.
- Contratos para autenticacion, perfiles, almacenamiento local y Supabase.
- Migracion inicial de Supabase con Row Level Security.
- Pruebas unitarias de la politica central de habitos.
- Motor de rutina guiada con sesiones persistibles.
- Crear rutina de 3 pasos desde la app.
- Ejecutar rutina paso a paso con Ahora / Despues.
- Acciones de rutina: hecho, mas tiempo, pausa, ayuda, posponer y omitir.
- Motor de habitos con limite gradual de 2 a 3 habitos nuevos.
- Pantalla de habitos con version minima y panel semanal simple.
- Configuracion de recordatorios con consentimiento, intensidad y solicitudes programadas simuladas.
- Check-in emocional opcional con apoyos breves.
- Biblioteca demo de cuentos con lector, preguntas, actividad y progreso.
- Preparacion de watchOS y Wear OS con contratos de snapshots y acciones rapidas.
- Persistencia local inicial con `FileLocalStore` y repositorios locales para entidades centrales.

Simulado/preparado:

- Persistencia local: store JSON durable implementado para desarrollo; Drift/SQLite queda como destino final.
- Persistencia de rutina: funciona en memoria y esta preparada para Drift/Supabase.
- Supabase: configuracion, migracion y adaptador inicial preparados; requiere variables de entorno reales.
- Auditoria de excepciones de habitos: regla de producto implementada, escritura real en `audit_logs` pendiente.
- Notificaciones nativas: planificador implementado, integracion `flutter_local_notifications` pendiente.
- Audio de cuentos: marcado como pendiente.
- Wearables nativos: contratos y UI preparatoria implementados; targets nativos pendientes.
- Recordatorios locales: paquete preparado; implementacion completa queda para Fase 4.

Pendiente:

- Generacion Drift real y base local SQLite.
- Integracion Supabase ejecutada contra proyecto real.
- Pruebas de widgets e integracion completas.
- watchOS, Wear OS, Live Activities, widgets y notificaciones avanzadas.

## Requisitos

- Flutter SDK estable.
- Dart SDK incluido con Flutter.
- Un proyecto Supabase para sincronizacion real.

## Comandos

Ver guia de previsualizacion en `docs/preview.md`.

```powershell
cd apps/mobile
flutter pub get
flutter analyze
flutter test
flutter run
```

Ejecutar todos los checks locales:

```powershell
.\scripts\checks.ps1
```

Estado MVP: `docs/mvp-status.md`.

Para paquetes puros:

```powershell
cd packages/domain
dart test
```

## Variables de entorno

Copiar `.env.example` a `.env` y completar:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

No se deben versionar secretos reales.
