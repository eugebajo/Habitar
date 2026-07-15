# ADR 0001: Arquitectura inicial

## Estado

Aceptada para Fase 1.

## Contexto

La logica de habitos, rutinas y perfiles no debe depender de Flutter, Supabase ni APIs de plataforma. El producto debe funcionar offline y sincronizar cuando haya backend disponible.

## Decision

Usar monorepo por paquetes:

- `domain`: entidades, reglas y politicas puras.
- `application`: casos de uso y puertos.
- `data`: adaptadores locales/remotos.
- `design_system`: tokens y temas Flutter.
- `accessibility`: preferencias y contratos de accesibilidad.
- `notifications`: contratos de recordatorios e integraciones.
- `apps/mobile`: presentacion Flutter y composicion de dependencias.

## Consecuencias

Las features pueden evolucionar sin mezclar UI con reglas centrales. Supabase, Drift, notificaciones y wearables se agregan como adaptadores.
