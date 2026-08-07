# Play Console - Checklist final antes de enviar a revisión

Usar esta lista cuando Google termine de verificar la cuenta desarrolladora.

## Estado listo

- Dominio: `https://habitarpy.com`
- Política de privacidad: `https://habitarpy.com/privacy/`
- Términos: `https://habitarpy.com/terms/`
- Email de soporte: `soporte@habitarpy.com`
- Package Android: `com.habitarpy.app`
- Bundle local generado:
  `apps/mobile/build/app/outputs/bundle/release/app-release.aab`
- Icono Play Store:
  `docs/store-assets/habitar-icon-512.png`
- Gráfico destacado:
  `docs/store-assets/habitar-feature-graphic-1024x500.png`
- Capturas:
  `docs/store-assets/screenshots/`

## Antes de subir el AAB

1. Confirmar que Google Play Console ya no muestre tareas pendientes de
   verificación de identidad o teléfono.
2. Crear la app `Habitar` si todavía no existe.
3. Crear una lista de prueba interna con tu correo y cualquier tester inicial.
4. Revisar si vamos a subir el AAB local-first actual o reconstruir con
   Supabase de producción.
5. Preparar la prueba cerrada usando `docs/closed-testing-plan.md`.

## Variante recomendada para la primera prueba interna

Usar el AAB local-first actual.

Motivo:

- Permite probar flujo, pantallas, políticas y ficha sin depender de backend.
- Google puede crear una cuenta adulta directamente en el dispositivo.
- Reduce riesgo mientras todavía estamos cerrando reglas de Supabase.

Instrucciones para revisión:

```text
Habitar permite crear un espacio adulto directamente desde la app.

Pasos sugeridos:
1. Abrir la app.
2. Tocar "Crear mi espacio".
3. Usar cualquier correo de prueba y contraseña.
4. Crear un perfil de niño o adolescente.
5. Entrar al modo niño/adolescente desde el selector de perfiles.

PIN adulto configurado por la familia.
```

## Ficha de tienda

Completar usando:

- `docs/play-store-listing-draft.md`
- `docs/store-assets-checklist.md`
- `docs/play-console-upload-steps.md`

Subir primero estas capturas:

1. `01-onboarding.png`
2. `05-adult-dashboard.png`
3. `04-profile-selector.png`
4. `06-child-mode.png`
5. `07-teen-mode.png`
6. `08-routine-create.png`
7. `09-habit-setup.png`
8. `10-wellbeing-checkin.png`

## Contenido de la app

Completar usando:

- `docs/play-console-app-content-answers.md`
- `docs/android-data-safety-draft.md`

Respuestas clave:

- Anuncios: no.
- Compras integradas: no en MVP inicial.
- Público principal: adultos cuidadores, tutores, docentes o profesionales.
- Niños/adolescentes: modos separados, no administran rutinas ni hábitos.
- Claims médicos: evitar. Habitar no diagnostica ni trata.

## Después de subir a prueba interna

1. Instalar desde el enlace de tester.
2. Crear una cuenta adulta nueva.
3. Crear un perfil infantil.
4. Crear una rutina de tres pasos.
5. Entrar al modo niño y confirmar que solo ve acciones asignadas.
6. Probar PIN adulto configurado por la familia.
7. Revisar que privacidad y términos abran correctamente.

## Paquete de prueba cerrada

- Plan: `docs/closed-testing-plan.md`
- Invitación: `docs/tester-invitation-message.md`
- Instrucciones: `docs/tester-instructions.md`
- Formulario de feedback: `docs/tester-feedback-form.md`

## Antes de producción pública

- Decidir si producción sale local-first o con Supabase.
- Si sale con Supabase, reconstruir el AAB con dart defines de producción.
- Confirmar reglas de acceso por familia/cuenta.
- Preparar iOS después de Android interno estable.
