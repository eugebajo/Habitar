# Fase 11: Recuperacion local al abrir

## Implementado

- Pantalla inicial `/` que restaura datos guardados antes de decidir el flujo.
- Recuperacion de usuario actual, familia, primer perfil disponible y sesion activa.
- Navegacion automatica a registro, creacion de perfil o dashboard segun el estado local.
- Indicador en el dashboard para distinguir datos guardados en este dispositivo de modo temporal.
- Pruebas de restauracion con estado vacio y con familia/perfil guardados.

## Decisiones

- La recuperacion vive en la app movil para actualizar providers de UI sin acoplar el paquete `application` a Riverpod.
- Se elige primero un perfil infantil y luego adolescente cuando hay mas de un perfil.
- El indicador local no expone datos sensibles; muestra solo el identificador tecnico del perfil activo durante MVP.

## Pendiente

- Selector de perfil cuando exista mas de un perfil por familia.
- Recuperar automaticamente la pantalla de rutina si hay sesion activa y el adulto lo confirma.
- Ocultar o humanizar identificadores tecnicos antes de beta publica.
- Agregar estado de ultima sincronizacion cuando exista cola local-remota.
