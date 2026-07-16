# MVP status

## Implementado

- Registro adulto con repositorio en memoria.
- Perfil infantil o adolescente.
- Rutina guiada de minimo 3 pasos.
- Vista Ahora / Despues.
- Pausa, ayuda, mas tiempo, posponer y omitir.
- Politica de habitos nuevos: 2 infantil, 3 adolescente.
- Check-in emocional opcional.
- Biblioteca demo de 3 cuentos.
- Configuracion simulada de recordatorios.
- Preparacion de wearables watchOS y Wear OS.
- Persistencia local inicial con store JSON durable para entidades centrales.
- Conexion de persistencia local durable al arranque de la app en plataformas moviles/escritorio.
- Persistencia local de notificaciones, bienestar, cuentos y snapshots wearable.
- Recuperacion local de familia, perfil y sesion activa al abrir la app.
- Cola de sincronizacion local-remota persistente.
- Adaptador de Auth Supabase preparado por gateway.
- Plan verificable de migracion JSON a Drift/SQLite.
- Drift/SQLite real activo como backend local en plataformas nativas/escritorio.
- Supabase schema inicial con Row Level Security.
- App Flutter con Android, iOS y web preview.
- Tests unitarios centrales.

## Simulado

- Gateway concreto de Auth real con `supabase_flutter`.
- Tablas Drift tipadas por entidad.
- Sincronizacion real con Supabase.
- Notificaciones nativas.
- Audio de cuentos.
- WatchConnectivity y Wear Data Layer nativos.
- Auditoria real de excepciones.

## Pendiente antes de beta

- Conectar Supabase Auth.
- Implementar worker de sincronizacion Supabase.
- Implementar Drift como persistencia final antes de beta.
- Conectar sincronizacion local-remota.
- Integrar `flutter_local_notifications`.
- Agregar permisos reales Android/iOS.
- Crear target watchOS.
- Crear modulo Wear OS.
- Ampliar pruebas de widgets e integracion.
- Agregar politica de privacidad provisional revisada.
- Revisar legalmente privacidad infantil.
