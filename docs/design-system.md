# Sistema de diseño de Habitar

Este documento mide la **distancia** entre lo que ya existe en `packages/design_system/lib/design_system.dart`
(el único archivo del paquete, 938 líneas) y su uso en `apps/mobile/lib/src/features/`, contra la dirección
visual de las 9 referencias guardadas en `docs/design-refs/`. No es un sistema inventado desde cero: la base
actual ya está bastante más cerca del objetivo de lo que parece a simple vista.

Las 9 imágenes son mockups generados con IA — aspiracionales, no implementables tal cual (ilustraciones
pintadas a mano, layouts que no consideran overflow ni estados vacíos, textos y navegación con pequeñas
inconsistencias entre sí). Se usan acá como referencia de dirección: paleta, tono, jerarquía, tipografía,
forma. Cuando dos mockups se contradicen entre sí, este documento elige una lectura y la explica — no repite
la inconsistencia.

**Hallazgo general, antes de entrar en detalle:** el código ya usa varios patrones que las referencias también
muestran, con la misma paleta, casi el mismo texto y a veces la misma heurística de íconos. La distancia real
está concentrada en pocos lugares: falta una tipografía serif para títulos (hoy todo es Roboto), la navegación
inferior usa el indicador de Material 3 en vez de un estilo plano, y faltan 3-4 componentes puntuales
(badge de estado, chip de perfil, fila de ajustes). El resto es, sobre todo, aplicar con más consistencia
lo que ya existe.

---

## 1. Principios

**Contexto que manda sobre el resto de las decisiones:** Habitar acompaña a chicos con TEA y TDAH. La claridad
visual es función, no decoración — cada decisión de este documento se puede justificar por "esto reduce carga
cognitiva" o se descarta.

- **Un paso a la vez.** El reproductor de rutina ya solo muestra el paso activo más un adelanto de "Después"
  (`routine_player_screen.dart`) — no listar todos los pasos pendientes a la vez.
- **Previsibilidad.** El mismo tipo de tarjeta, el mismo ícono y el mismo color deben significar lo mismo en
  toda la app. Hoy hay dos lugares que muestran "estado de una rutina" con lógicas visuales distintas
  (`family_dashboard_screen.dart:_RoutineDayRow` sin ícono, `portal_screens.dart:_RoutineListTile` con ícono
  y badge) — unificar eso es más importante que agregar decoración nueva.
- **Sin castigos, sin rachas, sin comparación.** Ya es una promesa explícita del onboarding
  (`onboarding_screen.dart:34`, "Sin castigos, comparaciones ni presión por rachas.") y ya es cierto en el
  código: no hay ningún contador de racha ni ranking implementado. La sección de Progreso ya dice
  "Una mirada simple, sin comparaciones ni castigos" (`portal_screens.dart:674`). Mantenerlo así al agregar
  cualquier componente nuevo de estado o de logro.
- **Calidez sin infantilizar.** La paleta orgánica (verdes, cremas, dorado) y las ilustraciones suaves se usan
  igual para el adulto que para el chico — lo que cambia entre uno y otro es la cantidad de información por
  pantalla y el tamaño de los botones, no el lenguaje visual.
- **Bajo estímulo como opción.** `buildHabitarTheme()` ya acepta `lowStimulation` (`design_system.dart:45`) y
  cuando está en `true` cambia las transiciones de página a algo más suave. Hoy nadie lo usa: `app.dart:197`
  llama `buildHabitarTheme()` sin argumentos. No lo resolvemos en esta pasada de diseño, pero queda anotado
  como una función ya construida y no conectada — más barata de activar que de construir de nuevo.
- **Qué evitamos activamente:** iconografía de trofeo/medalla como mecánica central de motivación (existe una
  feature real de recompensas en `rewards_screen.dart`, no la tocamos ni la copiamos como patrón visual
  default), lenguaje de rendimiento ("mejoraste", "récord", "posición"), badges de alerta agresivos — el rojo
  `HabitarColors.danger` se reserva para algo que realmente requiere atención (rutina no iniciada, sesión con
  error), nunca para presionar.

---

## 2. Tokens

### 2.1 Color

La paleta actual ya calza con las referencias — mismos verdes profundos, mismo crema cálido de fondo, mismo
dorado de acento. **No se propone cambiar ningún valor hex.**

| Token | Hex | Uso hoy | Coincide con la referencia |
|---|---|---|---|
| `ink` | `#243330` | Texto de cuerpo, texto principal | Sí — texto oscuro verdoso, no negro puro |
| `mutedInk` | `#65746F` | Texto secundario/metadata | Sí — gris verdoso de subtítulos |
| `surface` | `#FFFCF6` | Fondo de pantalla | Sí — el crema de fondo de las 9 imágenes |
| `surfaceWarm` | `#FFF5DE` | Fondo de pill/tarjeta cálida | Sí — fondo del pill "Después", del ícono de "Mañana" |
| `surfaceMist` | `#EAF3EA` | Fondo de pill/tarjeta verde suave | Sí — fondo del pill "Ahora", tarjetas verdes claras |
| `card` | `#FFFEFA` | Fondo de `HabitarCard` | Sí |
| `line` | `#E7DAC7` | Bordes sutiles | Sí — los bordes casi invisibles de las tarjetas |
| `sunlit` | `#E7B747` | Acento dorado (sol, punto decorativo) | Sí — el sol del ícono del paso, el punto tras el título |
| `deepGreen` | `#315E41` | Títulos, texto sobre fondo claro | Sí — el verde de los títulos serif |
| `primaryGreen` | `#537E5A` | Semilla del `ColorScheme`, barras de progreso | Sí |
| `calmGreen` | `#8EA787` | Acentos suaves, ilustraciones | Sí |
| `warmGold` | `#E5B857` | Badge "Pendiente", chips de alerta media | Sí |
| `softBlue` | `#9DB6C7` | Sin uso visible hoy | Disponible para íconos de higiene/agua |
| `supportRose` | `#EAA17E` | Badge de "ayuda solicitada" (`_AttentionTile`) | Sí — el naranja de "Ayuda solicitada" en Inicio adulto |
| `lavender` | `#C7BDD9` | Sin uso visible hoy | Coincide con el badge "Programada" de Rutinas |
| `danger` | `#C96055` | Errores | Sí — el rojo de "Rutina no iniciada" |

Lo que falta no son colores nuevos: son **variantes pálidas de los que ya existen**, para fondos de íconos y
badges. `_AttentionTile` ya hace exactamente esto (`color.withValues(alpha: .18)`,
`family_dashboard_screen.dart:543`) — ese es el patrón a repetir, no un token nuevo por cada combinación.

### 2.2 Tipografía — la brecha más grande

Hoy `buildHabitarTheme()` fija `fontFamily: 'Roboto'` para todo (`design_system.dart:57`) y define un
`textTheme` completo con tamaños y pesos ya bien calibrados (los tamaños ya son proporcionalmente parecidos a
las referencias). La distancia no está en los tamaños — está en que **no hay ninguna serif**. Las 9 imágenes
usan consistentemente una serif con terminaciones redondeadas y trazo cálido para títulos (7 de 9: onboarding,
login, progreso, rutinas, editar rutina, reproductor de paso, inicio adulto), con una sans neutra para cuerpo
y etiquetas. Solo la imagen del espacio del niño (3) parece usar una sans redondeada más gruesa en el título —
se lee como una inconsistencia del generador más que como una decisión de sistema (el resto de pantallas
dirigidas al chico, como el reproductor de paso en la imagen 8, sí usan la misma serif). Se estandariza en
**una sola pareja tipográfica para toda la app**, adulto y chico incluidos — es más simple, más barata de
mantener, y siete de nueve referencias ya convergen ahí.

**Propuesta concreta:**

- **Serif de títulos:** [Fraunces](https://fonts.google.com/specimen/Fraunces) — variable, con eje `SOFT`
  para una versión más redondeada/cálida que su corte por defecto. Es exactamente el tipo de serif "con
  carácter pero amable" que muestran las referencias, y es de uso frecuente en marcas de crianza/bienestar.
  Alternativa más conservadora si Fraunces resulta demasiado expresiva en pantalla chica: **Lora**.
- **Sans de cuerpo:** [Nunito Sans](https://fonts.google.com/specimen/Nunito+Sans) — cálida, buena
  legibilidad en tamaños chicos, sin el aire corporativo de Roboto. Alternativa: **Inter** (más neutra, si se
  prefiere minimizar el cambio de textura respecto a lo actual).

**Escala** (mismos tamaños/pesos de hoy, solo cambia la familia — `design_system.dart:58-93`):

| Nivel | Uso | Tamaño | Peso | Familia propuesta |
|---|---|---|---|---|
| `displayLarge` | Título de pantalla grande (poco usado) | 48 | 900 | Fraunces |
| `displaySmall` | Título de pantalla (la mayoría de headers) | 36 | 900 | Fraunces |
| `headlineSmall` | Título de tarjeta destacada | 28 | 900 | Fraunces |
| `titleLarge` | Título de ítem de lista (nombre de rutina) | 22 | 800 | Fraunces |
| `titleMedium` | Subtítulo de tarjeta, "Siguiente paso" | 17 | 800 | Fraunces (o Nunito Sans 800 si se quiere bajar el peso serif en listas largas) |
| `bodyLarge` | Cuerpo principal | 17 | 400 | Nunito Sans |
| `bodyMedium` | Cuerpo secundario | 15 | 400 | Nunito Sans |
| `labelLarge` | Botones, etiquetas | — | 800 | Nunito Sans |

**Cómo conseguir las fuentes**, dos caminos:

1. **Archivos locales embebidos (recomendado).** Descargar los `.ttf` estáticos de Fraunces y Nunito Sans desde
   Google Fonts, ponerlos en `apps/mobile/assets/fonts/` (carpeta a crear — hoy no existe ninguna carpeta de
   assets en el proyecto), declarar la sección `flutter: fonts:` en `apps/mobile/pubspec.yaml`, y usar el
   nombre de familia directamente en `design_system.dart`. Cero dependencias nuevas, funciona offline, sin
   fetch de red en cada arranque — importante para una app familiar que no debería depender de conectividad
   para mostrar texto.
2. **Paquete `google_fonts`.** Más rápido para probar (una línea, sin bajar archivos), pero por default hace
   fetch a la CDN de Google la primera vez y cachea — hay que fijar `GoogleFonts.config.allowRuntimeFetching
   = false` y empaquetar igual los archivos si se quiere evitar la dependencia de red. Si se usa este camino,
   es solo para probar rápido antes de decidir; para producción migrar a la opción 1.

**Detalle de marca, opcional y barato:** varios títulos en las referencias terminan con un punto dorado después
del signo de puntuación ("Hábitos posibles para familias reales**.**", "Volvamos a tu espacio**.**",
"¿qué necesita tu familia hoy?**.**") — un guiño tipográfico simple de armar (un `Text` + un `Container`
circular de 6-8px en `HabitarColors.sunlit`) que le da identidad sin costo de ilustración.

### 2.3 Espaciado y radios

Ya calzan con las referencias — no se proponen cambios.

| Token | Valor | Uso |
|---|---|---|
| `HabitarSpacing.xs..xxl` | 4 / 8 / 16 / 20 / 32 / 48 | Igual que hoy |
| `HabitarRadius.sm` | 8 | Chips chicos |
| `HabitarRadius.md` | 18 | Botones, inputs — coincide con el radio de los botones en las referencias |
| `HabitarRadius.lg` | 28 | Tarjetas — coincide |
| `HabitarRadius.xl` | 36 | Ilustraciones grandes |
| `HabitarRadius.pill` | 999 | Pills y badges |

### 2.4 Sombra

Diferencia menor y opcional: `HabitarCard` hoy tiene una sombra suave pero visible
(`blurRadius: 22, alpha: .055, offset: (0,10)` — `design_system.dart:362-368`). Las referencias son más planas,
casi sin sombra, apoyadas más en el borde sutil (`line`) que en la elevación. Si se quiere acercar, bajar el
alpha a `~.03` o sacar el `boxShadow` directamente. No es prioritario — el efecto visual de sacar la sombra es
chico comparado con el de la tipografía o la navegación.

---

## 3. Componentes

Formato por componente: cómo se ve en la referencia, cuándo se usa, y si ya existe en el repo o hay que
crearlo.

### Ya existen y coinciden bien — reforzar su uso, no rehacerlos

- **`HabitarCard`** (`design_system.dart:338`) — tarjeta con borde `line`, radio `lg`, fondo configurable.
  Coincide con casi todas las tarjetas de las referencias. Seguir usándola como base de todo lo demás.
- **`HabitarPill`** (`:381`) — pill con ícono opcional. Ya es el pill "Hoy", "Ahora", "Después" de las
  referencias. Para pills de texto libre, seguir usándolo tal cual.
- **`HabitarAvatar`** (`:834`) — círculo con inicial y color. Base para el chip de perfil (ver más abajo).
- **`ProgressRing`** (`:870`) — anillo de progreso con porcentaje centrado. Coincide con el anillo simple de
  "Resumen semanal" en Inicio adulto (imagen 9). El donut de dos segmentos con leyenda de la pantalla de
  Progreso (imagen 2) es una variante más elaborada — no urgente, ver plan de etapas.
  el gap real ahí es el layout adjunto (stat tiles + leyenda), no el anillo en sí.
- **`HabitarConversationCard`** (`:786`) y **`HabitarMoment`** (`:744`) — ya mapean bien al "Consejo de
  Habitar" de la pantalla de Rutinas y a las tarjetas "Ahora"/"Después" del espacio del niño (que hoy usa su
  propia versión privada, `_ChildPriorityCard` en `portal_screens.dart:1450` — casi idéntica en estructura a
  `HabitarMoment`; se podría hacer que una use a la otra, pero es refactor interno, no un cambio visual).
- **`HabitarSoftIllustration`** (`:544`) — ilustraciones geométricas por `CustomPainter`. No reemplaza la
  calidad pictórica de las referencias (eso es ilustración a medida, ver Parte 6), pero es la pieza correcta
  para seguir extendiendo mientras tanto.

### Ya existen, con la lógica correcta, pero solo en un lugar de la app

- **Ícono de rutina en tarjeta cuadrada + badge de estado + fila de acciones.** Este patrón completo **ya
  existe** en `portal_screens.dart:395-488` (`_RoutineListTile` — nombre no exportado, es privado a ese
  archivo): tile de 68×68 con ícono y fondo `surfaceWarm`, `HabitarPill` de estado a la derecha, línea
  divisoria, y una fila de `_TileAction` (ícono + etiqueta: Editar, Duplicar, Hoy, Pausar, Eliminar) — es
  prácticamente el layout de la imagen 5 (Rutinas). Incluso el ícono ya se elige con una heurística por
  palabra clave en el título (`_icon`, `portal_screens.dart:395-407`: "noche"/"dorm" → luna,
  "escuela"/"mochila" → mochila, "mañana"/"despert" → sol) que coincide con los mismos íconos que muestra la
  imagen 5. **El gap no es construir esto — es que solo vive en esta pantalla** y no en
  `family_dashboard_screen.dart:_RoutineDayRow` (`:390-488`), que muestra el "hoy" del adulto sin ícono de
  rutina. Extraer esa heurística + el tile a un componente de `design_system` (`HabitarIconTile`, ver abajo) y
  usarlo en ambos lugares es la forma barata de cerrar esa distancia.
- **Badge de estado por color.** `_AttentionTile` (`family_dashboard_screen.dart:510-563`) ya mapea
  color+ícono por tipo de pedido (pausa → `warmGold` + ícono de pausa, ayuda → `supportRose` + mano, tiempo
  extra → `primaryGreen` + reloj) exactamente con el mismo criterio que usan los badges de las referencias.
  Lo que falta es un componente compartido en vez de esta lógica repetida a mano en cada pantalla (ver
  `HabitarStatusBadge` abajo).

### Nuevos — chicos, se apoyan en lo anterior

- **`HabitarIconTile`** — cuadrado redondeado (radio `md`), fondo pastel, ícono Material grande centrado.
  Generaliza el tile que ya existe en `portal_screens.dart:428-438`, pero parametrizable en color de fondo (no
  fijo a `surfaceWarm`). Set de 8-10 combinaciones para elegir al crear una rutina (íconos Material, sufijo
  `_rounded` para mantener la familia de íconos que ya usa todo el repo):

  | Categoría | Fondo (alpha ~.35 sobre blanco) | Ícono |
  |---|---|---|
  | Mañana / despertar | `sunlit` | `Icons.wb_sunny_rounded` |
  | Escuela / mochila | `supportRose` | `Icons.backpack_rounded` |
  | Salir / vestirse | `calmGreen` | `Icons.directions_walk_rounded` |
  | Noche / dormir | `lavender` | `Icons.nightlight_round` |
  | Comida | `warmGold` | `Icons.restaurant_rounded` |
  | Higiene / baño | `softBlue` | `Icons.bathtub_rounded` |
  | Tarea / estudio | `surfaceMist` (verde más saturado) | `Icons.menu_book_rounded` |
  | Ordenar / guardar | `warmGold` | `Icons.inventory_2_rounded` |
  | Tiempo libre / pantallas | `softBlue` | `Icons.sports_esports_rounded` |
  | Otro (default) | `line` | `Icons.star_rounded` |

  **Importante:** hoy el ícono de una rutina se *infiere* del título (heurística en
  `portal_screens.dart:395-407`); no hay ningún campo de ícono en `packages/domain/lib/src/entities.dart`, ni
  en el editor (`routine_setup_screen.dart` no tiene ningún selector de ícono ni color). Extender la
  heurística actual a esta tabla de 10 y usarla en ambas pantallas es trabajo chico (visual, sin tocar datos).
  Dejar que el adulto **elija** el ícono al crear la rutina es otra historia — necesita un campo nuevo en el
  dominio, migración de Supabase y UI de selección: eso es una feature, no un token de diseño (ver Parte 6).
- **`HabitarStatusBadge`** — pill con ícono, con un mapeo de color fijo por estado, para reemplazar los
  `HabitarPill` con color pasado a mano en cada pantalla:
  - Completada / Activa → `surfaceMist` fondo, `deepGreen` texto, ícono de check o play.
  - Pendiente → `surfaceWarm` fondo, `ink` texto (ver nota de color de texto abajo), ícono de reloj.
  - Programada → `lavender` al 25% fondo, `ink` texto, ícono de calendario.
  - Pausada → `warmGold` al 25%, `ink` texto, ícono de pausa.
  - Vencida / no iniciada → `danger` al 15% fondo, `danger` texto, ícono de alerta.

  Nota de texto: las referencias usan un texto marrón/dorado oscuro sobre fondo mostaza y uno gris azulado
  oscuro sobre fondo lavanda — no hay tokens para esos dos tonos exactos hoy. Para no inflar la paleta, se
  propone reusar `ink` (`#243330`, ya es un oscuro neutro, funciona razonablemente sobre ambos fondos) en vez
  de sumar dos tokens nuevos solo para esto. Si en el uso real se ve deslavado, ahí sí vale sumar un tono.
- **`HabitarProfileChip`** — avatar (reusa `HabitarAvatar`) + nombre + chevron, dentro de un contenedor pill
  con borde `line`. Es el selector "Tomi ⌄" que aparece en el header de Progreso, Dispositivos y Rutinas.
  Esfuerzo chico porque envuelve un componente que ya existe.
- **`HabitarSettingsRow`** — ícono circular (fondo `surfaceWarm` pálido) + label + trailing (valor, chevron o
  `Switch`), con línea divisoria fina entre filas dentro de una `HabitarCard`. Es el patrón de "Editar rutina"
  (imagen 7): Nombre / Horario / Días / Duración / Aviso antes, y más abajo los toggles de "Apoyos y
  preferencias". Se puede introducir de a poco en `routine_setup_screen.dart` sin tocar su lógica de
  formulario (786 líneas, la parte riesgosa de tocar es la validación y el guardado, no el layout).
- **`HabitarStatTile`** — ícono circular + número grande + label + sublabel, en fila de 3. Es el patrón de
  "18 Rutinas completadas" / "7 Hábitos en marcha" / "¡Muy bien!" de la pantalla de Progreso (imagen 2).
- **`HabitarDaySelector`** — fila de 7 chips circulares (L M Mi J V S D), seleccionado = relleno `deepGreen` +
  texto blanco, no seleccionado = borde `deepGreen` punteado + texto verde. Uso acotado (solo en el editor de
  rutina), prioridad baja.

### Ajustes de tema, no componentes nuevos

- **Navegación inferior.** No es un componente nuevo — es `navigationBarTheme` en `design_system.dart:161-183`
  más el widget que ya arma la barra en `apps/mobile/lib/src/components/adult_shell.dart:67-83`. Hoy usa el
  indicador de Material 3 (una píldora `surfaceMist` detrás del ícono activo). Las referencias son más planas:
  sin píldora, el activo se distingue solo por color (`deepGreen` vs `mutedInk`) e ícono relleno vs contorno.
  Cambiar `indicatorColor` a transparente y usar variantes `_rounded` (contorno) / sin sufijo (relleno) del
  mismo ícono según selección es el ajuste concreto.

  Nota sobre las etiquetas: las 9 imágenes no son consistentes entre sí en los nombres de la barra —
  "Progreso/Recursos/Cuenta" (imagen 2), "Progresos/Avisos/Más" (imagen 5), y
  "Inicio/Rutinas/Progreso/Biblioteca/Familia" (imagen 9). Esta última es exactamente igual a
  `AdultShell.destinations` en el código hoy (`adult_shell.dart:9-15`) — se toma como la referencia válida y
  las otras dos como ruido de generación. No se propone ningún cambio de información aquí, solo de estilo.
- **Botón terciario/suave (fondo pálido).** Aparece en "Descargar reporte PDF" de Inicio adulto (imagen 9):
  ni el verde sólido del primario ni el borde del secundario, sino un relleno pálido con texto y borde verde.
  Material 3 ya trae esto resuelto: `FilledButton.tonal`. Definir un `filledButtonTheme` tonal en
  `buildHabitarTheme()` en vez de inventar un widget nuevo.
- **Switch/Toggle.** No hay `switchTheme` explícito hoy — usa el default de Material. Las referencias muestran
  un switch verde con thumb blanco grande (pantalla de Dispositivos y "Apoyos y preferencias" del editor).
  Definir `switchTheme` con `activeColor: deepGreen` es chico y de bajo riesgo.

---

## 4. Patrones de pantalla

### Inicio del adulto (`family_dashboard_screen.dart`)

Ya tiene, con datos reales: tarjeta de "hoy" con progreso y siguiente paso (`_TodayCard`/`_RoutineDayRow`),
lista de "qué necesita mi atención" con badges por color (`_AttentionList`/`_AttentionTile`), resumen semanal
con anillo de progreso (`_ProgressCard`). La estructura ya es la de la imagen 9. Lo que cambia con este
sistema: tipografía serif en los títulos, ícono de rutina en `_RoutineDayRow` (hoy no lo tiene, `_RoutineListTile`
de `portal_screens.dart` sí), `HabitarStatusBadge` en vez de pills sueltas, chip de perfil en el header en vez
del texto plano actual.

### Lista de rutinas (`portal_screens.dart:_RoutinesSection`)

Es la pantalla más cerca del objetivo ya hoy — ver el detalle de `_RoutineListTile` en la Parte 3. El texto
"Organizá el día familiar con rutinas claras y previsibles" (`portal_screens.dart` línea del `subtitle`) ya es
casi idéntico al de la imagen 5 ("Organizá el día de Tomi..."). Cambios: tipografía, `HabitarIconTile` con la
paleta de 10 en vez de un tile siempre `surfaceWarm`, `HabitarStatusBadge` en vez de `HabitarPill` con color a
mano, tarjeta de "Consejo de Habitar" al final de la lista (patrón nuevo pero barato: es un `HabitarMoment` con
otro texto).

### Espacio del niño (`portal_screens.dart:ChildHomeScreen`)

Ya reproduce casi textualmente la imagen 3: "Hola, [nombre]" (`:1242`), pill "Ahora" (`:1276`, vía
`_ChildPriorityCard`), tarjeta "Después" para el siguiente paso, tarjeta "Pedir ayuda" con el texto exacto
"No tengo que hacerlo solo" (`:1303`), botón "Espacio adulto" al final. La distancia acá es casi puramente de
textura: tipografía, y la calidad de ilustración (`HabitarSoftIllustration` geométrica vs. las ilustraciones
pintadas de la referencia — ver Parte 6).

### Reproductor de paso (`routine_player_screen.dart`)

Es el patrón más maduro de todos: "Paso N de M", barra de progreso, tarjeta con pill "Ahora · N min aprox.",
título grande, ilustración, tarjeta "Después" con el siguiente paso, botón "Listo", y exactamente los mismos
tres botones secundarios que la imagen 8 ("Necesito más tiempo", "Necesito ayuda", "Necesito una pausa", con
los mismos íconos: reloj, mano, nube). El manejo de error y estado ocupado agregado recientemente
(`_isBusy`/`_error`, `routine_player_screen.dart:82-109`) ya resuelve algo que ni siquiera está en la
referencia (qué pasa si falla el guardado). No hay cambios estructurales que hacer acá — solo tipografía y
tarjetas.

---

## 5. Voz y textos

La voz ya está bastante bien establecida en el código existente — varios de los textos de las referencias ya
están, literalmente, en la app. Las reglas, para mantenerla:

- **Segunda persona, directa, sin relleno.** "Tu día, a tu ritmo" (`portal_screens.dart:1245`), "Organizá el
  día familiar con rutinas claras y previsibles". No "el usuario podrá organizar sus rutinas".
- **Nunca lenguaje de rendimiento o competencia.** No "récord", "racha", "mejor que ayer", "posición". Sí
  "Cada paso cuenta" (ya existe, `routine_player_screen.dart:177`), "a tu ritmo", "un paso a la vez".
- **Nombrar la ayuda sin culpa.** "No tengo que hacerlo solo" (no "no puedo solo"), "Necesito una pausa" (no
  "me rindo" ni "cancelar"). El botón de ayuda nunca se llama "SOS" ni usa signos de exclamación.
- **Confirmaciones cortas y concretas, no genéricas.** "Terminaste tus pasos de hoy. Cada paso cuenta." en vez
  de "¡Felicitaciones!" — ya es el patrón en `routine_player_screen.dart:177`.
- **Errores sin culpar a nadie, con salida clara.** "No pudimos guardar eso. Probá de nuevo en un momento."
  (`routine_player_screen.dart:103-104`) — no "hubo un error" ni un código técnico visible para el chico.
- **Privacidad explicada en una frase, no en jerga legal, cuando importa al usuario en ese momento.** "Tu
  información familiar no se muestra al niño desde esta entrada." (imagen 4, pantalla de login) — este texto
  específico no existe todavía en `login_screen.dart` y vale sumarlo, es exactamente el tipo de frase que baja
  ansiedad sin dar una clase de seguridad.
- **Lo que no hacemos:** signos de exclamación en exceso, diminutivos forzados ("tareita", "pasito" — ya se
  evita, se dice "paso" sin diminutivo), emojis en botones o títulos (las referencias no los usan en texto de
  interfaz, solo alguna vez como decoración de ilustración).

---

## 6. Qué queda fuera de alcance por ahora

Con menos de 5 horas por semana, estas piezas no entran en el plan de la Parte 7. Se anotan para no
perderlas, con una estimación honesta:

| Ítem | Por qué queda afuera | Esfuerzo estimado si se retoma |
|---|---|---|
| **Ilustración a medida por paso** (las mochilas, zapatillas y escenas pintadas de las referencias) | Es diseño de assets, no de sistema — necesita un ilustrador o una herramienta de generación consistente por estilo, más un pipeline de assets que hoy no existe (no hay carpeta `assets/` en `apps/mobile`) | Grande — probablemente más de 20h solo en producir 15-20 ilustraciones consistentes, más el trabajo de integrarlas |
| **Avatares con foto** (el círculo con foto real de "Tomi" en headers) | Hoy `HabitarAvatar` es solo iniciales sobre color — agregar foto real implica selección/recorte de imagen, almacenamiento (Supabase Storage no está en uso hoy para esto) y una política de privacidad para fotos de menores | Medio-grande — el almacenamiento y la política de privacidad pesan más que el componente visual en sí |
| **Selector de ícono/color al crear una rutina** (que el adulto elija, no que se infiera del título) | Requiere campo nuevo en `packages/domain/lib/src/entities.dart`, migración de Supabase, y UI de selección — es una feature de producto, no un token visual | Medio — 1 migración chica + 1 campo + 1 grilla de selección, pero cruza tres capas (domain/data/UI) |
| **Biblioteca de recursos** (la pestaña "Recursos"/"Biblioteca" ya existe como `story_library_screen.dart`, pero su rediseño visual completo no está cubierto por ninguna de las 9 referencias) | Ninguna imagen de referencia la muestra en detalle — no hay suficiente información para diseñarla con precisión todavía | Sin estimar — falta una referencia antes de poder dimensionar esto |
| **Recompensas** (`rewards_screen.dart`, el campo "Recompensa" del editor de rutina) | Es una feature real y ya implementada, pero su tratamiento visual no viene definido por ninguna de las 9 imágenes más que una fila suelta en "Editar rutina" | Chico si se hace junto con `HabitarSettingsRow`, pero no hay referencia suficiente para más que eso |
| **Pantalla de dispositivos** (imagen 6, smartwatch) | Es la única referencia de una pantalla ya implementada (`wearables_screen.dart`) que no se tocó en este análisis — el patrón de fila con ícono+estado+switch es el mismo `HabitarSettingsRow` de la Parte 3, pero la pantalla completa tiene su propia lógica de conexión BLE que no se audita acá | Chico-medio una vez que exista `HabitarSettingsRow`, pero no es parte de las primeras etapas |
| **Donut de dos segmentos con leyenda** (Progreso, imagen 2) | El anillo simple (`ProgressRing`) ya cubre el 80% del valor visual a una fracción del esfuerzo; el donut con leyenda + reporte PDF con barras por categoría es una variante más elaborada | Medio — nuevo `CustomPainter` de dos arcos + leyenda, sin tocar lo que ya funciona |
| **Modo de bajo estímulo conectado a un control de usuario** | `lowStimulation` ya existe en el theme pero no hay ningún switch de configuración que lo dispare | Chico (es casi enteramente conectar un `Provider` a un `Switch` existente en `notification_settings_screen.dart`), pero es una decisión de producto/accesibilidad, no de este documento — se anota para no perderla |

---

## 7. Plan de implementación por etapas

Ordenado por impacto visual dividido esfuerzo, para alguien con menos de 5 horas por semana. La intuición de
que tipografía y navegación son lo más rentable **se confirma** con un dato concreto: en
`apps/mobile/lib/src/features/`, hay **61 usos de `Theme.of(context).textTheme.*`** contra solo **4 usos de
`fontSize:` hardcodeado**. Eso significa que un cambio de tipografía centralizado en
`packages/design_system/lib/design_system.dart` se propaga solo, sin tocar pantalla por pantalla — es la
definición de alto impacto / bajo esfuerzo.

### Etapa 1 — Tipografía serif + sans
- **Qué toca:** `apps/mobile/assets/fonts/` (nuevo), `apps/mobile/pubspec.yaml` (sección `flutter: fonts:`),
  `packages/design_system/lib/design_system.dart` (`fontFamily` del `ThemeData` y de cada nivel del
  `textTheme`, más `appBarTheme.titleTextStyle`).
- **Riesgo:** bajo. Es un cambio puramente visual, sin lógica. El único riesgo real es que algún título largo
  desborde con la nueva métrica de fuente (revisar visualmente 2-3 pantallas con nombres largos de rutina
  después del cambio) y correr `flutter test`/`flutter analyze` como siempre.
- **Esfuerzo: chico.** Bajar 2-4 archivos de fuente, declarar el asset, cambiar ~10 líneas en un solo archivo.
- **Por qué primero:** se propaga a las 61 referencias de `textTheme` automáticamente. Es el cambio de mayor
  impacto por hora de trabajo de todo el plan.

### Etapa 2 — Navegación inferior plana
- **Qué toca:** `packages/design_system/lib/design_system.dart` (`navigationBarTheme`, líneas 161-183),
  `apps/mobile/lib/src/components/adult_shell.dart` (líneas 67-83, y el `NavigationRail` de escritorio para
  mantener consistencia con la barra móvil).
- **Riesgo:** bajo. Solo estilo, la lógica de navegación (`context.go`, selección por ruta) no cambia.
- **Esfuerzo: chico.** Cambiar el indicador y los íconos de contorno/relleno en dos archivos.
- **Por qué segundo:** es la pieza de UI visible en el 100% de las pantallas de adulto, todo el tiempo, y hoy
  es la que más "distingue" el estilo Material genérico de lo que muestran las referencias.

### Etapa 3 — Unificar el ícono de rutina en las dos pantallas donde falta
- **Qué toca:** extraer `_icon`/tile de `portal_screens.dart:395-438` a un `HabitarIconTile` en
  `design_system.dart`, ampliar la heurística a la tabla de 10 categorías de la Parte 3, usarlo también en
  `family_dashboard_screen.dart:_RoutineDayRow`.
- **Riesgo:** bajo-medio. Toca dos pantallas con datos reales, pero es agregar un elemento visual, no cambiar
  lógica de negocio. Correr los tests de `family_dashboard_activity_test.dart` y `todays_routines_list_test.dart`
  después.
- **Esfuerzo: medio.** Un componente nuevo + dos puntos de integración.
- **Por qué acá:** es la pieza que más "se siente" como progreso funcional (cada rutina se distingue de un
  vistazo) y ya existe la heurística que hace la mitad del trabajo.

### Etapa 4 — `HabitarStatusBadge` + tarjetas más planas
- **Qué toca:** `design_system.dart` (componente nuevo + reducir/sacar `boxShadow` de `HabitarCard`), aplicar
  en `family_dashboard_screen.dart` (`_AttentionTile`, `_TodayCard`) y `portal_screens.dart`
  (`_RoutineListTile`).
- **Riesgo:** bajo. Los tests actuales buscan texto (`find.text('Pendiente')`, etc.), no colores — el badge
  nuevo debería mantener las mismas etiquetas de texto para no romper nada.
- **Esfuerzo: medio.** Un componente + reemplazar ~4-5 usos de `HabitarPill` con color a mano.

### Etapa 5 — Botón tonal, switch theme, chip de perfil
- **Qué toca:** `design_system.dart` (`filledButtonTheme` tonal, `switchTheme`, `HabitarProfileChip` nuevo
  reusando `HabitarAvatar`), aplicar el chip en el header de `family_dashboard_screen.dart` y
  `profiles_screen.dart`.
- **Riesgo:** bajo. Aditivo — no reemplaza nada que ya funcione, solo lo prolija.
- **Esfuerzo: chico-medio.**

### Etapa 6 — `HabitarSettingsRow` en el editor de rutina
- **Qué toca:** `design_system.dart` (componente nuevo), `routine_setup_screen.dart` (786 líneas — tocar solo
  el layout de las filas, no el estado del formulario ni la validación).
- **Riesgo: medio.** Es el archivo más grande y con más lógica de formulario de toda la app. Cambiar el
  layout sin tocar `TextEditingController`s ni validadores existentes reduce el riesgo, pero conviene
  hacerlo en un cambio aparte y bien probado (`routine_setup_save_test.dart` ya cubre el guardado).
- **Esfuerzo: medio-grande**, por el tamaño del archivo más que por la dificultad del cambio en sí.
- **Por qué al final de las etapas "chicas":** es la pantalla con más riesgo de introducir un bug de guardado
  por un cambio de layout mal hecho, y el beneficio visual (aunque real) es menor que el de las etapas 1-4
  porque el adulto la visita con mucha menos frecuencia que el inicio o el reproductor.

### Resumen

| Etapa | Impacto | Esfuerzo | Riesgo |
|---|---|---|---|
| 1. Tipografía | Muy alto | Chico | Bajo |
| 2. Navegación inferior | Alto | Chico | Bajo |
| 3. Ícono de rutina unificado | Medio-alto | Medio | Bajo-medio |
| 4. Badge de estado + tarjetas planas | Medio | Medio | Bajo |
| 5. Botón tonal / switch / chip de perfil | Medio | Chico-medio | Bajo |
| 6. Fila de ajustes en editor de rutina | Medio | Medio-grande | Medio |

Las etapas 1 y 2 solas — probablemente una sola tarde de trabajo — ya deberían cambiar sustancialmente la
percepción de la app, porque tocan cada pantalla a la vez desde un solo lugar cada una.
