# Fase 3: Habit engine

## Implementado

- Motor de habitos con activacion gradual.
- Limite recomendado operativo: 2 habitos nuevos en perfil infantil y 3 en adolescente.
- Confirmacion explicita del adulto para excepciones.
- Habitos con version minima.
- Registro simple de progreso sin rachas.
- Resumen semanal con mensajes de apoyo.
- Repositorios en memoria para desarrollo offline.
- Tabla `habit_progress` en Supabase con Row Level Security.
- Pantalla de gestion de habitos conectada al panel familiar.

## Simulado

- Auditoria de excepciones todavia no crea filas reales de `audit_logs`.
- Panel semanal usa registros manuales simples, no tendencias profundas.
- Persistencia offline real sigue pendiente de Drift.

## Pendiente para Fase 4

- Notificaciones locales.
- Canales, permisos e intensidad.
- Acciones desde notificacion.
- Notificacion persistente durante rutina activa en Android.
- Live Activity basica en iOS.
