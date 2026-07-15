# Fase 4: Notifications

## Implementado

- Contratos de permisos, consentimiento, intensidad y acciones de recordatorio.
- Planificador de recordatorio de inicio de rutina.
- Acciones previstas: empezar rutina, 5 minutos mas, necesito ayuda, omitir con motivo.
- Intensidades: discreta, visible, insistente permitida, silenciosa y solo smartwatch.
- Scheduler en memoria para desarrollo sin fingir integracion nativa.
- Pantalla de configuracion de recordatorios.
- Tabla `notification_preferences` en Supabase con Row Level Security.
- Tests unitarios del planificador.

## Simulado

- `flutter_local_notifications` no esta integrado todavia.
- Permisos Android/iOS se representan como estado manual en la UI.
- Notificacion persistente Android y Live Activity iOS estan preparados como features de plataforma, no implementados.
- Alarmas exactas quedan marcadas por `requiresExactAlarm`, pero no se solicitan permisos nativos aun.

## Pendiente para Fase 5

- Check-in emocional.
- Acciones de apoyo.
- Biblioteca y lector de cuentos demo.
- Progreso de cuentos.
