# ADR 0003: Alcance de wearables

## Estado

Aceptada para Fase 6.

## Decision

Preparar integraciones separadas para:

- watchOS mediante target nativo y WatchConnectivity cuando corresponda.
- Wear OS mediante modulo nativo y Data Layer API.

No se intentara soportar "cualquier smartwatch" Bluetooth generico en el MVP.

## Motivo

Apple Watch y Wear OS tienen modelos de integracion, permisos, transporte y UI distintos. Un contrato comun de snapshots y comandos permite compartir logica sin ocultar diferencias de plataforma.
