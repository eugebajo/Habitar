# Play Console - Pasos para cargar Habitar

Guía operativa para avanzar con Google Play aunque la cuenta siga en
verificación.

## 1. Crear o abrir la app

1. Entrar a Google Play Console.
2. Ir a **Todas las apps**.
3. Abrir **Habitar** o crear una app nueva si todavía no existe.
4. Usar estos datos:

- Nombre: `Habitar`
- Idioma predeterminado: Español
- Tipo: App
- Gratis o paga: Gratis para MVP inicial

## 2. Ficha principal de tienda

Ir a **Presencia en Google Play > Ficha de Play Store principal**.

Copiar desde:

- `docs/play-store-listing-draft.md`

Cargar:

- Descripción corta.
- Descripción completa.
- Icono: `docs/store-assets/habitar-icon-512.png`
- Gráfico destacado: `docs/store-assets/habitar-feature-graphic-1024x500.png`
- Capturas: `docs/store-assets/screenshots/`

Capturas recomendadas para subir primero:

1. `01-onboarding.png`
2. `05-adult-dashboard.png`
3. `04-profile-selector.png`
4. `06-child-mode.png`
5. `07-teen-mode.png`
6. `08-routine-create.png`
7. `09-habit-setup.png`
8. `10-wellbeing-checkin.png`

## 3. Contacto y URLs

Usar:

- Sitio web: `https://habitarpy.com`
- Política de privacidad: `https://habitarpy.com/privacy/`
- Términos: `https://habitarpy.com/terms/`
- Email de soporte: `soporte@habitarpy.com`

## 4. Contenido de la app

Ir a **Política y programas > Contenido de la app**.

Usar como guía:

- `docs/play-console-app-content-answers.md`
- `docs/android-data-safety-draft.md`

Puntos importantes:

- Sin anuncios.
- Sin compras integradas en MVP inicial.
- Público principal: adultos cuidadores, tutores, docentes o profesionales.
- Niños y adolescentes usan modos separados y no administran hábitos ni rutinas.
- No presentar Habitar como diagnóstico, tratamiento ni terapia.

## 5. Acceso para revisión

Si Google pide acceso:

```text
Habitar requiere una cuenta adulta para crear espacios familiares, perfiles,
rutinas y hábitos. Los modos de niño y adolescente están separados y solo
muestran contenido asignado por el adulto.

Para revisión, pueden usar las credenciales de prueba provistas o crear una
nueva cuenta adulta. PIN demo para entrar al espacio adulto protegido: 1234.
```

Pendiente antes de enviar a revisión:

- Crear una cuenta demo estable.
- Confirmar que esa cuenta puede entrar en la app instalada.
- Anotar email y contraseña demo en Play Console, no en el repositorio.

## 6. Release de prueba interna

Este paso puede esperar hasta que Google termine de verificar la cuenta.

Cuando esté habilitado:

1. Ir a **Pruebas > Prueba interna**.
2. Crear una lista de testers.
3. Subir el primer `.aab`.
4. Completar notas de versión.
5. Enviar a revisión interna.

Notas de versión sugeridas:

```text
Primera versión de prueba de Habitar: rutinas guiadas, perfiles familiares,
modo infantil, modo adolescente, hábitos cuidados y check-in de bienestar.
```

## Bloqueado por Google

No podremos publicar ni completar algunos pasos finales hasta que Google termine
la verificación de identidad y contacto de la cuenta desarrolladora.
