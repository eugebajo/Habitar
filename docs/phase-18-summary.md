# Fase 18 - Perfiles visibles y progreso

Implementado:

- Nueva ruta `/profiles` para ver perfiles familiares.
- Panel por nino/adolescente con:
  - progreso visible,
  - metas cumplidas,
  - tareas pendientes,
  - rutina activa,
  - proximo paso,
  - accesos a rutina y habitos.
- Selector de perfil activo desde la lista.
- Acceso a perfiles desde el panel semanal.
- `ProfileService` ahora construye un resumen de progreso usando repositorios existentes.
- El panel infantil/adolescente no ofrece crear habitos ni rutinas.

Reglas de calculo:

- Metas cumplidas combina pasos de rutina completados y versiones minimas registradas.
- Tareas pendientes combina pasos restantes de la rutina activa y habitos activos/propuestos sin registro.
- El progreso es una orientacion visual, no una racha ni una puntuacion competitiva.
- Ninos y adolescentes ven tareas, progreso y habitos asignados; la creacion y edicion corresponde a padres, tutores, profesionales medicos o profesores.

Pendiente:

- Edicion de perfil desde la pantalla de detalle.
- Preferencias sensoriales/accesibilidad por perfil.
- Historial mas completo por semana.
- Sincronizacion remota Supabase de perfiles y progreso.
