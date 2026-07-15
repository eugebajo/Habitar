# Fase 2: Routine engine

## Implementado

- Motor puro de sesiones de rutina en `packages/routine_engine`.
- Inicio de rutinas con minimo 3 pasos.
- Avance paso a paso.
- Vista Ahora / Despues.
- Temporizador visual aproximado.
- Mas tiempo.
- Pausa sensorial.
- Reanudar sin perder progreso.
- Ayuda.
- Posponer 5 minutos.
- Omitir paso.
- Repositorios en memoria para desarrollo offline.
- Tabla `routine_sessions` preparada para sincronizacion Supabase con RLS.
- Tests unitarios del motor central.

## Simulado

- Persistencia offline real queda simulada en memoria hasta integrar Drift.
- Temporizador visual no cuenta segundos reales todavia; muestra tiempo estimado y estado de pausa.
- Ayuda queda registrada en sesion, sin notificacion al adulto todavia.
- Posponer guarda estado y hora sugerida, sin programar recordatorios locales.

## Pendiente para Fase 3

- Motor de habitos completo.
- Estados y progreso sin rachas punitivas.
- Limite operativo de 2 a 3 habitos nuevos desde UI.
- Panel semanal con tendencias reales.
