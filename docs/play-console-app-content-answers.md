# Play Console - Respuestas de contenido

Borrador práctico para completar Google Play Console. Revisar antes de enviar.

## Acceso a la app

Si Google pregunta si toda o parte de la funcionalidad está restringida:

- Respuesta: parte de la funcionalidad está restringida.
- Instrucciones para revisores:

```text
Habitar requiere una cuenta adulta para crear espacios familiares, perfiles,
rutinas y hábitos. Los modos de niño y adolescente están separados y solo
muestran contenido asignado por el adulto.

Para revisión, pueden usar las credenciales de prueba provistas o crear una
nueva cuenta adulta. PIN demo para entrar al espacio adulto protegido: 1234.
```

## Anuncios

- ¿La app contiene anuncios? No.

## Clasificación de contenido

Habitar es una app de organización familiar y acompañamiento cotidiano. No
incluye violencia, contenido sexual, apuestas, contenido público generado por
usuarios ni compras integradas en el MVP.

## Público objetivo

Intención de producto:

- Usuario principal / titular de cuenta: persona adulta cuidadora, madre, padre,
  tutor, docente o profesional autorizado.
- Perfiles de niños/adolescentes: modos separados para ver rutinas asignadas,
  progreso y apoyos.

Pregunta sensible:

Habitar debe presentarse como app administrada por adultos con modos infantiles
y adolescentes separados. Evitar declararla como app donde niños crean su propio
contenido o administran rutinas.

## Seguridad de datos

Datos que puede recolectar:

- Dirección de email.
- ID de usuario.
- Nombres o nombres visibles.
- Actividad dentro de la app.
- Contenido opcional de check-in de bienestar.

Finalidades:

- Funcionalidad de la app.
- Administración de cuenta.
- Sin publicidad.
- Sin analítica de terceros en el MVP, salvo que se agregue un SDK más adelante.

Compartición:

- No se venden datos personales.
- Los datos pueden ser procesados por proveedores de infraestructura como
  Supabase, Google Play y Apple App Store.

Seguridad:

- Datos cifrados en tránsito.
- La persona usuaria puede solicitar eliminación de datos por soporte hasta que
  exista eliminación automática dentro de la app.

## URLs

- Sitio web: `https://habitarpy.com`
- Política de privacidad: `https://habitarpy.com/privacy/`
- Términos: `https://habitarpy.com/terms/`

## Pendiente antes de revisión

- Crear o reenviar `soporte@habitarpy.com`.
- Definir credenciales de prueba para Google Play.
- Confirmar que Supabase de producción tenga reglas de acceso por cuenta/familia.
