# Habitar — Especificación de prototipo para desarrollo

> Documento de referencia para el rediseño completo de la app (14 semanas, por etapas). Esta es la
> especificación tal como la entregó el prototipo — ver **Correcciones a la especificación**, al final,
> para lo que no aplica tal cual a la app real y por qué.

## Contexto del producto

Habitar es una app móvil que acompaña rutinas diarias de niños y adolescentes con TEA y TDAH mediante
perfiles familiares conectados. Un adulto crea rutinas; el chico las completa desde su dispositivo paso a
paso; otros adultos de la familia siguen el progreso.

Principio rector: sin castigos, sin comparaciones, sin presión por rachas. No hay puntos, estrellas,
medallas ni recompensas. El logro se reconoce, no se premia.

Idioma: español rioplatense (voseo: "creá", "elegí", "podés"). Plataforma objetivo: mobile-first
390×844px.

## Sistema de diseño

### Paleta

| Token | Hex | Uso |
|---|---|---|
| cream | `#FDFBF3` | Fondo de pantalla |
| white | `#FFFFFF` | Tarjetas y superficies |
| green | `#3B6D11` | Botones primarios, activo en nav, acento |
| greenDark | `#173404` | Títulos, texto principal |
| greenLight | `#EAF3DE` | Tarjetas destacadas, fondo de ícono activo |
| greenMedium | `#C0DD97` | Bordes suaves, segmentos pendientes |
| amber | `#FAC775` | Ícono de rutina de tarde |
| amberText | `#412402` | Texto sobre amber |
| amberLight | `#FAEEDA` | Ícono de rutina de mañana |
| amberLightText | `#854F0B` | Texto sobre amberLight |
| violet | `#EEEDFE` | Ícono de rutina de noche |
| violetText | `#26215C` | Texto sobre violet |
| gray | `#5F5E5A` | Texto secundario, etiquetas, placeholders |

### Tipografía

- Títulos y serifs: Fraunces (Google Fonts) — opsz variable, pesos 400/500/600
- Cuerpo e interfaz: Nunito (Google Fonts) — pesos 400/500/600/700/800
- Tamaños: títulos 22–28px serif, cuerpo 13–15px, etiquetas uppercase 10–12px con
  `letter-spacing: 0.06–0.1em`
- Sentence case siempre. Nunca Title Case. Mayúsculas solo en etiquetas chicas.

### Formas

- Tarjetas: `border-radius: 12–14px`, sin sombra
- Botones primarios: `border-radius: 14px`, altura mínima 44px (56px en espacio del chico)
- Íconos de rutina: cuadrado 38–40px, `border-radius: 10px`, fondo de color suave, ícono en tono oscuro
  de esa familia
- Sin gradientes, sin sombras, sin efectos. Superficies planas.
- Separación entre tarjetas: 8–10px gap

### Componentes reutilizables

- **SegmentedBar** — Barra de progreso por segmentos. Props: `total: number`, `done: number`. Cada
  segmento es `flex: 1`, altura 4px (adulto) o 6px (chico), `border-radius: 2–3px`. Color: greenMedium si
  pendiente, green si completado.
- **EstadoPill** — Pastilla de estado de rutina. Props: `estado: 'Completada' | 'En curso' | 'Programada'`.
  Estilos: Completada → bg greenLight, color green. En curso → bg green, color white. Programada → bg
  `#EFEFEF`, color gray.
- **Toggle** — Interruptor booleano. Ancho 44px, alto 24px, `border-radius: 12px`. Bg green si activo,
  `#D1D1D1` si inactivo. Pastilla interior 20px circular, blanca, transición de posición.
- **NavBar** — Barra de navegación inferior adulto. 4 tabs: Inicio, Rutinas, Progreso, Familia. Tab
  activo: color green, ícono relleno. Tabs inactivos: color gray, ícono outline. Etiquetas 10px,
  `letter-spacing: 0.04em`. Borde superior 1px en greenMedium. Fondo cream.
- **IconoRutina** — Cuadrado redondeado. Mañana: bg amberLight, color amberLightText, ícono sol. Tarde:
  bg amber, color amberText, ícono mochila. Noche: bg violet, color violetText, ícono luna.

### Estructura de navegación

```
onboarding → registro → a-inicio
onboarding → login → a-inicio
onboarding → codigo → a-inicio

a-inicio ←→ a-rutinas ←→ a-progreso ←→ a-familia   (nav inferior)
a-rutinas → a-crear-momento → a-crear-confirmar → a-editar
a-familia → a-cuenta

a-inicio → c-inicio (botón "Avisarle a Nico")
c-inicio → c-paso → [pasos sucesivos] → c-logro → c-inicio
```

El espacio del chico no tiene navegación inferior. El adulto siempre tiene NavBar con 4 tabs.

## Pantallas

### 1. Onboarding

Layout: columna. Foto superior de altura fija (~320px), contenido en scroll debajo.

Foto: imagen cálida de niño jugando (Unsplash `photo-1565886593760-8e80f074d1f7`),
`object-fit: cover`. Sobre la foto, overlay gradiente sutil de transparente a `rgba(23,52,4,0.3)` hacia
abajo. En top-left sobre la foto: logotipo "habitar" en Fraunces 20px blanco.

Contenido (padding 28px 24px):

- `<h1>` Fraunces 26px greenDark: "Hábitos posibles para familias reales"
- `<p>` 14px gray: "Rutinas visuales con pasos pequeños, pensadas para chicos con TEA y TDAH."
- Franja verde: bg greenLight, `border-radius: 12px`, padding 14/16px. Texto 13px green bold: "Sin
  castigos, comparaciones ni presión por rachas."
- Botón primario: "Crear mi espacio" → registro
- Botón secundario (outline green): "Ya tengo una cuenta" → login
- Link discreto gray 13px: "Tengo un código de invitación" → codigo

### 2. Registro

Layout: columna con botón "Volver" arriba.

Encabezado: `<h1>` Fraunces 24px "Creá tu espacio" + subtítulo 14px gray "Después invitás a tu familia."

Campos (gap 14px entre ellos). Cada campo tiene label 12px uppercase letter-spacing 0.06em gray bold, e
input border 1.5px solid greenMedium, `border-radius: 12px`, padding 14/16px, 15px Nunito, greenDark.
Campos: Tu nombre, Nombre de la familia, Correo electrónico (`type=email`), Contraseña (`type=password`).

Botón primario: "Crear mi espacio" → a-inicio

Pie: texto 13px gray centrado: "Al continuar aceptás los términos de uso."

### 3. Login

Layout: columna. Ilustración centrada arriba, luego campos.

Ilustración: SVG de casa simple. Tejado con path, cuerpo rectangular, dos ventanas, puerta. Colores:
relleno greenLight, trazo green. Tamaño ~64×64px.

Encabezado centrado: `<h1>` Fraunces 26px "Volvamos a tu espacio"

Campos: Correo electrónico, Contraseña.

Botón primario: "Entrar" → a-inicio

Links debajo: "Olvidé mi contraseña" (13px gray) — "Crear un espacio nuevo" → registro (13px green bold)

### 4. Código de invitación

Layout: columna centrada con padding generoso.

Ícono: SVG de llave. Círculo fondo greenLight, llave trazada en green. ~64×64px.

Texto: `<h1>` Fraunces 24px "Ingresá tu código" + párrafo 14px gray: "Alguien de tu familia te compartió
un código por WhatsApp para unirte a su espacio."

Input grande: placeholder "ABC - 123 - XYZ", 22px, letter-spacing 0.1em, bold, centrado. Border 2px
greenMedium, `border-radius: 14px`, padding 20/16px.

Nota bajo input: 12px gray centrado: "El código tiene 9 caracteres"

Botón primario: "Aceptar invitación" → a-inicio

### 5. Inicio del adulto

Layout: AdultoLayout (NavBar en bottom, scroll en contenido). Padding 20px.

Top bar: izquierda "habitar" Fraunces 18px greenDark; derecha selector de perfil (bg greenLight,
`border-radius: 20px`, padding 6/12/6/6px, círculo 28px bg green con inicial "N" blanca 13px bold, texto
"Nico ▾" 13px greenDark bold).

Saludo: `<h2>` Fraunces 22px 500 "Buenos días, Andrea" + subtítulo 13px gray "Hoy es martes 11 de
septiembre."

Tarjeta "AHORA" — bg greenLight, `border-radius: 14px`, padding 18/16px: etiqueta "AHORA" 10px uppercase
letter-spacing 0.1em green bold; row con ícono de rutina (40px, mañana: amberLight/amberLightText) +
nombre "Rutina de mañana" 15px bold greenDark + subtítulo "Siguiente: ducharse" 12px gray; SegmentedBar
`total=5, done=2` + texto "2 de 5 pasos completados" 11px gray; botón 100% bg green blanco 13px bold
`border-radius: 12px` padding 11px: "Avisarle a Nico" → c-inicio.

Actividad reciente: título sección 12px uppercase letter-spacing 0.06em gray bold; 3 tarjetas blancas
`border-radius: 12px` padding 12/14px, cada una con ícono de rutina (36px), texto "Nico terminó [Nombre]"
13px bold greenDark, hora relativa 11px gray, chevron derecho.

### 6. Rutinas

Layout: AdultoLayout, tab activo "rutinas".

Header: `<h1>` Fraunces 22px "Rutinas" + botón "Nueva rutina" con ícono `+` (bg green, blanco,
`border-radius: 20px`, padding 8/14px, 13px bold) → a-crear-momento.

Lista de rutinas (gap 8px). Cada tarjeta: bg white, `border-radius: 14px`, padding 14/16px. Si está "En
curso": `border: 2px solid green`. Las demás: `border: 2px solid transparent`.

Contenido de cada tarjeta: ícono de rutina 40px; columna con nombre en Fraunces 16px 500 greenDark +
horario y cantidad de pasos 11px gray; EstadoPill al extremo derecho.

Datos mock: Mañana / 7:00 am / 5 pasos / En curso / borde verde activo — Tarde / 4:00 pm / 4 pasos /
Programada — Noche / 8:00 pm / 5 pasos / Completada.

Cada tarjeta → a-editar

### 7. Crear rutina — elegir momento

Layout: columna simple con "Volver".

Encabezado: `<h1>` Fraunces 24px "¿Qué momento del día?" + subtítulo 14px gray "Elegí uno y listo. Después
ajustás."

3 tarjetas grandes (bg white, `border-radius: 14px`, padding 18/20px, cada una → a-crear-confirmar):
ícono 48px `border-radius: 12px` + nombre Fraunces 18px 500 + subtítulo "X pasos listos" 12px gray +
chevron. Mañana: bg amberLight, color amberLightText, ícono sol. Tarde: bg amber, color amberText, ícono
mochila. Noche: bg violet, color violetText, ícono luna.

Opción "Empezar de cero": `border: 2px dashed greenMedium`, fondo transparente, bg ícono `#F5F5F5`, color
gray.

### 8. Crear rutina — confirmar

Layout: columna con "Volver".

Header: ícono de rutina 44px + `<h1>` Fraunces 24px "Rutina de mañana" (en fila).

Filas configurables (bg white, `border-radius: 12px`, padding 14/16px, gap 2px): Horario "7:00 am" +
chevron → editable; Días "Lunes a viernes" + chevron → editable.

Sección "Pasos incluidos": label sección 11px uppercase gray; lista de pasos (bg white,
`border-radius: 10px`, padding 12/14px, número en círculo greenLight 22px + nombre 13px greenDark). Pasos:
Despertar y estirarse, Ir al baño, Ducharse, Desayunar, Preparar la mochila.

Footer: botón primario 100% "Crear rutina" → a-editar; texto 12px gray centrado: "Todo lo demás se ajusta
después."

### 9. Editar rutina

Layout: columna con "Volver" y título "Editar rutina" centrado.

Header: ícono de rutina 44px + nombre Fraunces 20px en fila.

Sección Configuración (label 11px uppercase): filas (bg white, `border-radius: 12px`, padding 13/14px,
gap 2px) Nombre / Horario / Duración estimada / Aviso previo, cada una con valor bold greenDark + chevron.

Fila especial "Días de la semana": 7 círculos 34px. Activos: bg green, color white. Inactivos: bg
greenLight, color gray. Estado inicial: L, Ma, Mi, J, V activos. Interactivos (toggle individual).

Sección Pasos (label 11px uppercase): lista reordenable (bg white, `border-radius: 10px`, gap 4px). Cada
ítem: manija ≡ (color `#C0D0B0`) + nombre 13px + chevron. Botón "Agregar paso":
`border: 1.5px dashed greenMedium`, bg transparente, color green, ícono `+`.

Sección Apoyos (label 11px uppercase): contenedor white, `border-radius: 12px`, divisores 1px greenLight.
4 filas con Toggle: Permitir pedir ayuda (default true), Permitir pausa (default true), Vibración
(default false), Sonido (default false).

Acciones al pie: botón primario "Guardar cambios"; botón destructivo "Eliminar rutina" — bg none, color
`#C0392B`, sin borde, más abajo.

### 10. Progreso

Layout: AdultoLayout, tab activo "progreso".

`<h1>` Fraunces 22px "Progreso de Nico"

Tarjeta principal (bg white, `border-radius: 16px`, padding 24/20px, centrado): anillo SVG, `r=50`,
`strokeWidth=14`. Track: greenLight. Fill: green, `stroke-dasharray` calculado al 82%. Transformado
`rotate(-90 60 60)` para partir desde arriba. Centro: Fraunces 26px bold "82%". Debajo: "Esta semana" 15px
bold + "49 de 60 pasos completados" 13px gray.

Grid 3 columnas (gap 8px). Cada métrica: bg white, `border-radius: 12px`, padding 14/10px. Valor Fraunces
24px bold greenDark, label 10px gray centrado multi-línea: 14 / Rutinas completadas — 49 / Pasos
completados — 3 / Ajustes del día.

Fila de botones (gap 10px): "Descargar PDF" (bg greenLight, color green, ícono descarga); "Compartir" (bg
greenLight, color green, ícono compartir).

Sin rachas, sin comparaciones con otras familias.

### 11. Familia

Layout: AdultoLayout, tab activo "familia".

Header: "Familia García" Fraunces 22px + link "Mi cuenta" → a-cuenta.

Sección Adultos (label 11px uppercase): 2 tarjetas (bg white, `border-radius: 12px`, padding 13/14px):
círculo inicial 38px bg greenLight, inicial green 15px bold + nombre 14px bold + rol 11px gray. Andrea
García / Organizadora principal — Marcos García / Acompañante.

Botón "Invitar adulto" bg greenLight color green ícono `+` — al hacer click aparece la tarjeta de código.

Tarjeta de código (aparece al invitar, bg white, `border-radius: 14px`, padding 20/16px): título "Código
de invitación" 13px bold + texto explicativo 12px gray; código en caja greenLight, `border-radius: 10px`:
"FAM-847-XKL" 22px bold letter-spacing 0.15em; fila con botón "Copiar" (outline, toggle a "¡Copiado!" con
bg greenLight) + botón "Compartir" (bg green blanco).

Invitaciones pendientes (label 11px uppercase): tarjeta white con código "FAM-321-QWE" 13px bold +
"Enviado hace 2 horas" 11px gray + botón "Cancelar" `#C0392B` sin borde.

### 12. Cuenta

Layout: columna simple con "Volver".

Header: avatar círculo 52px bg green, inicial "A" 22px bold blanca + nombre Fraunces 20px + email 12px
gray.

Lista de acciones (bg white, `border-radius: 14px`, overflow hidden): "Transferir mi rol de organizadora"
+ chevron; "Eliminar mi cuenta" + chevron (color `#C0392B`). Divisor 1px greenLight entre ellas.

Zona peligrosa (bg `#FFF5F5`, `border: 1.5px solid #FFCDD2`, `border-radius: 14px`, padding 16px): título
"Zona peligrosa" 13px bold `#C0392B`. Texto explicativo: "Esto elimina el espacio familiar completo. Todos
los adultos y las rutinas de Nico se borran para siempre." Estado inicial: botón outline `#C0392B`
"Eliminar todo el espacio familiar". Al hacer click, se reemplaza por: texto "¿Estás segura? Esta acción
no se puede deshacer." bold `#C0392B` centrado; botón rojo lleno "Sí, eliminar todo" (bg `#C0392B` blanco
14px bold); link "Cancelar" gray (restaura estado inicial).

### 13. Inicio del chico

Sin NavBar inferior.

Layout: columna, padding 24px horizontal, contenido centrado verticalmente con `justify-content: center`.

SegmentedBar en top (`total=4, done=0`, height 6px) — full width.

Saludo: `<h1>` Fraunces 28px bold "Hola, Nico" + "Te quedan cuatro pasos." 16px gray.

Tarjeta grande rutina (bg greenLight, `border-radius: 20px`, padding 28/24px, centrada): ícono emoji 🎒 en
cuadrado 64px `border-radius: 16px` bg amber; etiqueta "AHORA" 11px uppercase letter-spacing 0.08em green;
`<h2>` Fraunces 24px "Rutina de tarde"; botón "Empezar" 100% bg green blanco 18px bold
`border-radius: 16px` padding 18px → c-paso.

Pie: "Tu día, a tu ritmo." 12px gray centrado.

### 14. Paso en curso

Sin NavBar inferior.

Estado interno: `pasoActual` (0 a 3). Avanzar → si hay más pasos, incrementa. Si es el último → c-logro.

SegmentedBar arriba (`total=4, done=pasoActual`, height 6px).

Tarjeta del paso (bg greenLight, `border-radius: 20px`, padding 32/24px, centrada): ícono emoji en
cuadrado 80px `border-radius: 20px` bg white, 40px font-size; `<h2>` Fraunces 26px nombre del paso;
duración 13px gray.

Pasos disponibles:

| # | Nombre | Duración | Emoji |
|---|---|---|---|
| 0 | Llegar a casa | 5 min | 🏠 |
| 1 | Guardar la mochila | 5 min | 🎒 |
| 2 | Merendar | 15 min | 🍎 |
| 3 | Ordenar el cuarto | 10 min | 🧹 |

Botón "Listo": 100% bg green blanco 18px bold `border-radius: 16px` padding 18px, ícono check (✓).
`onClick` → avanzar.

Grid 3 columnas de botones secundarios (mismo peso visual entre sí). Cada uno: bg white,
`border: 1.5px solid greenMedium`, `border-radius: 12px`, padding 12/8px, ícono + label 12px. Sin
jerarquía visual entre ellos: Más tiempo (ícono temporizador), Ayuda (ícono signo de pregunta), Pausa
(ícono pausa).

"Después" (visible si hay siguiente paso): separado por 1px greenLight. Emoji del siguiente paso +
"Después: [nombre]" 12px gray.

### 15. Logro

Sin NavBar inferior.

Layout: columna centrada, padding 24px.

SegmentedBar full (`total=4, done=4`, todos en green).

Ícono central: círculo grande SVG 120×120px, relleno greenLight. Dentro: tallo vertical + dos hojas (una
izquierda, una derecha) en green. Semejante a un brote o planta. Sin estrellas, sin confeti, sin trofeos.

Texto: `<h1>` Fraunces 28px "Terminaste la tarde" + "Cuatro pasos, uno por uno." 15px gray.

Tarjeta próxima rutina (bg greenLight, `border-radius: 14px`, padding 16/20px, en fila): ícono luna 36px
bg violet; "Después, a las 20:00" 12px gray + "Noche" 14px bold greenDark.

Cierre: Fraunces 17px gray: "Nos vemos entonces."

Botón link "Volver al inicio" → c-inicio — bg none, color green, 14px bold, sin borde.

## Flujos conectados requeridos

- onboarding → registro → a-inicio
- onboarding → login → a-inicio
- onboarding → codigo → a-inicio
- a-rutinas → a-crear-momento → a-crear-confirmar → a-editar
- a-inicio → c-inicio (botón "Avisarle a Nico")
- c-inicio → c-paso → [4 pasos sucesivos] → c-logro → c-inicio
- a-familia → [mostrar tarjeta código] → copiar/compartir
- a-familia → a-cuenta → [confirmar eliminar]

## Comportamientos interactivos clave

| Componente | Comportamiento |
|---|---|
| Toggle en Apoyos | Estado booleano local, animación CSS `transition` en posición y color |
| Días de la semana en Editar | Cada círculo togglea su índice en array de activos |
| Botón "Copiar" en Familia | Cambia a "¡Copiado!" con bg greenLight por 2 segundos, luego vuelve |
| Botón "Eliminar todo" en Cuenta | Primer click muestra confirmación; "Cancelar" restaura estado |
| Pasos en PasoScreen | `pasoActual` en estado, avanza con "Listo", lleva a Logro en el último |
| "Invitar adulto" en Familia | Muestra tarjeta de código de invitación generado |
| Tab activo en NavBar | El tab correspondiente a la pantalla actual tiene ícono relleno y color green |

---

## Correcciones a la especificación

El prototipo de origen es un mockup navegable, no la app real — tiene cosas que no aplican tal cual al
código de Habitar. Anotadas acá para que las etapas siguientes no las repliquen por accidente.

1. **Nombres y códigos de ejemplo.** "Andrea García", "familia García", `FAM-847-XKL` son placeholders del
   prototipo. La app real genera códigos de invitación de **32 caracteres hexadecimales** vía
   `create_family_invitation_with_code` (ver `supabase/migrations/0010_invitation_codes.sql`). **No se
   cambia ese formato** — la UI de las etapas siguientes tiene que mostrar el código real tal como lo
   devuelve esa función, no un formato corto tipo `FAM-XXX-XXX`.

2. **Emojis por paso.** El prototipo usa 🎒🏠🍎🧹 como ícono de cada paso de una rutina. Eso implica un
   campo que `routine_steps` **no tiene hoy** (`packages/domain/lib/src/entities.dart` no define ningún
   campo de ícono en `RoutineStep`). Está decidido agregar una columna de ícono — pero en una etapa
   posterior, junto con su propia migración de Supabase. Por ahora queda anotado como **pendiente**, no se
   inventa un campo en el dominio ni se persiste nada parecido a un ícono por paso en esta etapa.

3. **Porcentajes en Progreso.** El prototipo muestra "82%" en la pantalla de Progreso del adulto (pantalla
   10) y también evita cualquier número en el espacio del chico (pantallas 13-15, solo `SegmentedBar`).
   Eso **sí se mantiene tal cual**: Progreso es la pantalla del adulto, es su herramienta de seguimiento,
   puede mostrar porcentajes y números. El espacio del chico sigue sin números en ningún lado — solo
   segmentos.

4. **"Avisarle a Nico" (pantalla 5) no navega al espacio del chico.** En el prototipo ese botón navega
   directamente a `c-inicio` (pantalla 13). En la app real eso es incorrecto: el adulto y el chico usan
   dispositivos distintos, así que ese botón tiene que **enviar una notificación al dispositivo del niño**,
   no navegar localmente a su pantalla. El envío de notificaciones llega en la etapa 3 del plan de 14
   semanas. Hasta entonces, el botón queda **sin acción real** (deshabilitado o con un
   `TODO`/anotación explícita en el código), nunca navegando a `/child` como si fuera la misma sesión.
