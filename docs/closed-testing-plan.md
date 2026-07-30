# Habitar - Paquete de prueba cerrada Android

Objetivo: estar listos para iniciar la prueba cerrada apenas Google Play Console
termine de verificar la cuenta desarrolladora.

## Objetivo de la prueba

Validar que una familia pueda entender y usar Habitar sin explicación externa:

- Crear un espacio adulto.
- Crear un perfil infantil o adolescente.
- Preparar una rutina simple.
- Preparar un hábito pequeño.
- Entrar al modo niño/adolescente.
- Confirmar que el espacio adulto está separado y protegido.
- Detectar confusiones de texto, navegación, diseño o confianza.

## Alcance de esta primera prueba

La primera prueba cerrada usa el AAB local-first actual:

```text
apps/mobile/build/app/outputs/bundle/release/app-release.aab
```

Esto significa:

- Cada tester prueba en su propio dispositivo.
- La cuenta se crea localmente en el dispositivo.
- No dependemos de Supabase ni sincronización remota para esta ronda.
- No se debe prometer sincronización entre dispositivos todavía.

## Perfil de testers

Buscar al menos 12 testers activos.

Prioridad:

1. Madres, padres o tutores.
2. Docentes o profesionales que acompañan niños/adolescentes.
3. Personas que viven rutinas familiares intensas.
4. Personas con Android como teléfono principal.

Evitar para esta ronda:

- Personas que solo quieren mirar la idea sin instalar.
- Testers sin tiempo para usarla durante varios días.
- Niños/adolescentes probando sin adulto responsable.

## Datos a pedir a cada tester

- Nombre.
- Email Gmail que usa en Google Play.
- Modelo de teléfono Android.
- País.
- Rol: madre/padre/tutor/docente/profesional/otro.
- Edad aproximada del niño/adolescente para quien imagina usar Habitar.
- Disponibilidad para probar durante 14 días.

## Cronograma sugerido

### Día 0

- Crear lista de testers en Play Console.
- Subir AAB a prueba cerrada o interna.
- Enviar invitación con link.
- Confirmar que cada tester acepta la invitación.

### Días 1 a 3

- Testers instalan y hacen el primer flujo.
- Pedir feedback inicial de instalación, registro y comprensión.

### Días 4 a 10

- Pedir que creen al menos una rutina y un hábito.
- Pedir que prueben modo niño/adolescente.
- Recoger fricciones reales.

### Días 11 a 14

- Pedir feedback final.
- Registrar bugs críticos y mejoras de lanzamiento.
- Decidir si se sube una nueva versión o se solicita producción.

## Criterios de éxito

La prueba es suficientemente buena si:

- Al menos 12 testers aceptaron y mantuvieron acceso.
- Al menos 8 testers completaron el flujo inicial.
- Al menos 5 testers enviaron feedback útil.
- No hay bugs críticos en registro, navegación, modo niño/adolescente o PIN.
- La mayoría entiende que los adultos crean rutinas y los niños solo ven lo asignado.

## Bugs críticos

Bloquean lanzamiento:

- La app no abre.
- No se puede crear espacio adulto.
- No se puede crear perfil.
- No se puede navegar al modo niño/adolescente.
- El espacio adulto queda accesible sin confirmación.
- Textos rotos, ilegibles o con caracteres raros.
- La app promete funciones que todavía no existen.

## Decisión después de la prueba

Opciones:

1. Enviar a producción Android si los problemas son menores.
2. Subir una segunda versión cerrada si hay ajustes medianos.
3. Rehacer un flujo si hay confusión fuerte en onboarding, perfiles o modo niño.

## Archivos relacionados

- `docs/tester-invitation-message.md`
- `docs/tester-instructions.md`
- `docs/tester-feedback-form.md`
- `docs/play-console-final-review-checklist.md`
