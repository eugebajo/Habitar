# Fase 6: Wearables

## Implementado

- Paquete `habitar_wearable_bridge`.
- Contratos de plataforma: watchOS y Wear OS.
- Capacidades por plataforma.
- Transportes previstos: backend, notificaciones, WatchConnectivity y Wear Data Layer.
- Snapshot compacto de rutina activa.
- Comandos rapidos: completar, mas tiempo, ayuda, posponer, pausa y reanudar.
- Gateway en memoria para desarrollo.
- Pantalla Wearables en la app movil.
- Directorios preparatorios `apps/watchos` y `apps/wearos`.
- Tests unitarios del puente wearable.

## Simulado

- No hay target Xcode watchOS real todavia.
- No hay modulo Wear OS real todavia.
- No se sincroniza con relojes fisicos.
- El snapshot queda en memoria.

## Pendiente

- Crear target watchOS en Xcode.
- Crear modulo Wear OS.
- Implementar WatchConnectivity.
- Implementar Data Layer API.
- Pruebas en emuladores y dispositivos.
