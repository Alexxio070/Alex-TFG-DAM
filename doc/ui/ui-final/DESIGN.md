# Diseño final de la interfaz

> **Estado: definitivo.** Refleja el código real de `App-movil/lib/`, verificado leyendo cada pantalla el 15/10/2026. Sustituye a [`../ui-v1/DESIGN.md`](../ui-v1/DESIGN.md) y [`../ui-v2/DESIGN.md`](../ui-v2/DESIGN.md) como referencia de diseño; esos dos documentos se conservan como **historial** de cómo se llegó hasta aquí (el prototipo inicial y la primera especificación de Notas).

## 0. Cómo leer este documento

- Cada pantalla se describe tal como está implementada hoy, no como se planeó. Donde el código y un diseño anterior discrepaban, gana el código, y se anota el porqué.
- **Qué es simulado:** todos los datos vienen de repositorios `Fake...` en memoria (sección 8). El agente Python no existe todavía.
- El diseño de la terminal del agente (sesiones con tmux, terminal vacía, pestañas) vive en [`../../agente/terminal-sesiones-tmux.md`](../../agente/terminal-sesiones-tmux.md) y **no está implementado en la app**; la sección 5 describe lo que hay hoy.

## 1. Estructura general

- Pantalla base: `Scaffold` con `AppBar` propia arriba, cuerpo con la sección activa debajo, y el drawer y su scrim superpuestos en un `Stack`.
- **AppBar:** 64 dp + el margen superior del sistema, fondo `surface`, borde inferior 1 dp `border`. Botón de menú 44×44, título 18 sp/700, `letterSpacing -0.18`.
- **Drawer** (`AppDrawer`, 280 dp de ancho, fondo `surface`, sombra lateral):
  - Se abre con el botón de menú, **o arrastrando desde una franja de 24 dp en el borde izquierdo**, y se cierra arrastrando hacia la izquierda (sobre el drawer o el scrim) o tocando el scrim. El panel sigue al dedo; al soltar, se completa la apertura o el cierre según la posición (>50 %) o la velocidad (>365 dp/s, con `AnimationController.fling`).
  - Animación de 280 ms, curva `Cubic(0.2, 0.8, 0.2, 1)`; el scrim (negro al 45 %) se desvanece en los primeros 240 ms.
  - Cabecera (64 dp + margen superior): botón X + nombre de la sección activa.
  - Opciones: Inicio, Métricas, Terminal, Notas (48 dp de alto, radio 12; la activa va en color de acento con texto blanco).
  - Pie: botón de engranaje (abre Ajustes) a la izquierda, estado de conexión a la derecha (punto verde + «Conectado» o punto gris + «Sin emparejar»).
  - Elegir una sección cierra el drawer.
- Navegación por un `switch` sobre `ShellViewModel.active` (`Section`: `home`, `metrics`, `terminal`, `notes`, `settings`), sin rutas con nombre.

## 2. Tema y colores

Tokens claro/oscuro (`AppTokens`), igual que en v1: `bg`, `surface`, `ink`, `muted`, `muted2`, `border`, `line`, `borderStrong`, `field`, `off`, `segOn`, además de `greenText` para el estado «Conectado» y las constantes `kRed` (`#B42318`) y `kGreen` (`#1F9D55`).

**Color de acento:** 6 opciones (`kAccentColors`), elegibles en Ajustes. **En tema oscuro se usa una versión más clara de cada uno** (`kAccentColorsDark`), calculada el 15/10/2026 aclarando solo la luminosidad (mismo tono y saturación) hasta llegar a un contraste de ~4,5:1 contra el fondo oscuro `#111316` (fórmula de contraste WCAG):

| Acento | Claro / original | Oscuro (aclarado) | Contraste logrado |
|---|---|---|---|
| Verde azulado | `#0F6B63` | `#148C81` | 4,52 |
| Azul | `#3346C7` | `#6675D8` | 4,52 |
| Frambuesa | `#B4235A` | `#DA437D` | 4,50 |
| Naranja | `#C2410C` | `#DE4A0E` | 4,51 |
| Violeta | `#6D28D9` | `#9462E3` | 4,53 |
| Grafito | `#3F4652` | `#717E92` | 4,52 |

Antes de este ajuste, el contraste del acento en oscuro rondaba 2:1–3:1 (hasta 1,96 en Grafito).

**Tipografía:** Plus Jakarta Sans para toda la interfaz (`fontFamily` del `ThemeData`). JetBrains Mono se usa en los sitios con `mono: true` de `AppTextField` (el campo de comando de una macro) y en textos sueltos con `fontFamily: 'JetBrainsMono'` (el `$ comando` de los avisos y diálogos, el punto de montaje en Métricas). La terminal real y su vista previa en Ajustes usan la fuente del sistema (ver sección 5).

## 3. Inicio — cuadrícula de macros

**Modelo:** `Macro { id, label, command, kind: volume|lock|moon|bolt, confirm }`, `Folder { id, name, color, children: [Macro] }`.

**Geometría** (`MacroGrid`): 2 columnas, separación 18 dp, margen lateral 20 dp, margen superior 24 dp. La altura de la zona de la cuadrícula es proporcional al alto disponible (misma proporción que el diseño original, 576/780). El tamaño de cada ficha se calcula a partir del ancho real del móvil. Scroll vertical solo si hay más de 6 elementos. Radio de las fichas: 24.

**Ficha** (`ItemTile`): macro con icono (64, color de acento, grosor 1.6) y nombre centrado (15 sp/600); carpeta con fondo de su color, hasta 4 miniaturas blancas arriba y nombre + «N macros» en blanco.

**Gestos** (implementados con `Listener` + posiciones absolutas, sin librería de arrastre):

| Gesto | Umbral / resultado |
|---|---|
| Mantener pulsado | 420 ms levanta el elemento (si antes se mueve más de 8 px, se interpreta como scroll) |
| Soltar sobre otro hueco | Reordena con animación de 220 ms |
| Soltar una macro sobre el centro de otra (±52 dp) | Crea una carpeta «Carpeta» con las dos |
| Soltar una macro sobre una carpeta | La añade a la carpeta |
| Mantener una carpeta 1500 ms en total (1080 ms tras el levantamiento) | Cancela el arrastre y abre la edición (nombre + 6 colores) |
| Arrastrar a la papelera (radio 52 dp, centrada abajo) | Elimina el elemento; con una carpeta **que tiene macros**, antes pregunta «¿Qué hacer con «nombre»?» (mover los macros a Sin grupo / cancelar / borrar carpeta y contenido). Una carpeta vacía se borra directamente |
| Cerca del borde superior/inferior de la cuadrícula (50 px) | Autoscroll |

**Botón «+»:** circular, 60 dp, 20 dp del borde derecho, 28 dp del fondo (más el margen inferior del sistema). Oculto mientras se arrastra. Con 40 elementos o más, muestra el aviso «No caben más botones» (1,6 s) en vez de abrir el diálogo.

**Diálogo «Nueva macro»:**
- Nombre: obligatorio, **máximo 50 caracteres**, y **no puede coincidir** (sin distinguir mayúsculas) con el nombre de otra macro o carpeta ya existente en el nivel superior de la cuadrícula. Mensaje de error bajo el campo.
- Comando: monoespaciado, sin autocorrección.
- **Icono:** fila de 4 opciones (volumen, candado, luna, rayo — las mismas que usan las macros), con la seleccionada resaltada; por defecto, rayo.
- Interruptor «Pedir confirmación».
- «Crear» deshabilitado hasta que nombre, comando e icono sean válidos.

**Ejecución:** aviso inferior oscuro (`Ejecutando «nombre»` + `$ comando`), 2,2 s, con vibración ligera (`HapticFeedback.lightImpact`). Si la macro pide confirmación, antes se muestra el diálogo «¿Ejecutar «nombre»?» con el comando.

**Carpeta:** tocarla abre un diálogo con sus macros en cuadrícula de 2 columnas, que se ejecutan igual al tocarlas.

## 4. Métricas

Lista con scroll (`ListView`, padding 16/16/16/32+margen inferior del sistema) con 4 tarjetas, separadas 16 dp:

1. **Uso de CPU** — 0–100 %.
2. **Temperatura de CPU** — escala 30–100 °C u 86–212 °F según el ajuste; si la alerta está activa y se supera el límite, valor en rojo (`kRed`) con la etiqueta «Alta». **Si el agente no encuentra sensor** (`cpu_temp_c: null`), la tarjeta se sustituye por un aviso: «No se ha podido mostrar la temperatura».
3. **Uso de RAM** — «usado / total», en GB o GiB según el ajuste.
4. **Uso de disco** (`DiskCard`): barra de progreso, usado/libre y %, con chip de partición (mantener pulsado el chip o la tarjeta 1 s —la tarjeta se encoge a 0,97 con borde de acento— abre el menú de particiones, superpuesto con `OverlayPortal`).

**Tarjeta** (`MetricSurface`): radio 20, borde 1 dp `border`, padding 16. El gráfico de área (`AreaChart`) lo dibuja un `CustomPainter` propio: 110 dp de alto, 3 líneas guía al 25/50/75 % y una línea base, sin librería de gráficos. Pie con «Hace 60 s · escala · Ahora». Actualización cada 1 s (`MetricsViewModel.watch()`).

**Datos:** `HttpMetricsRepository` pide `GET http://<dirección>/metrics` al agente (ver sección 8). Las particiones (`DiskCard`) se leen una vez al abrir la app (`loadInfo()`), no en cada segundo junto con las gráficas: si cambian mientras la app está abierta, no se reflejan hasta reabrirla (simplificación asumida, no un error).

## 5. Terminal

**Estados** (`TerminalSessionState`): `empty` (sin sesión), `creating` (creándose) y `ready` (prompt real). Aplica el diseño de ciclo de vida de `doc/agente/terminal-sesiones-tmux.md` §4 sobre un `FakeTerminalRepository` (maqueta sin agente: no hay ventana del PC ni medidas reales de latencia).

- **`empty`:** pantalla con el aviso **«Toca para abrir una terminal en tu PC»**, centrado. Dispara la creación de sesión el primer toque sobre esa zona, o la primera tecla que no sea un modificador solo (CTRL, ALT, SHIFT, META).
- **`creating`:** la terminal real ya está montada y enfocada por debajo (para no perder lo que se teclee con un teclado físico, que se guarda en cola y se envía en orden al quedar lista), pero se superpone un indicador con el texto **«Abriendo terminal…»**. En la maqueta, el retraso es un `Future.delayed` fijo de 600 ms.
- **`ready`:** `xterm.dart` (`TerminalView`) sobre el `Terminal` del `TerminalViewModel`, con el shell simulado del repositorio. Escribir `exit` o Ctrl+D con la línea vacía cierra la sesión (vuelve a `empty`, con una `Terminal` nueva).
- **Fuente: la del sistema** (decisión del 15/10/2026). No se pasa `fontFamily`, así que se usa el valor por defecto del paquete, `'monospace'`, que en Android resuelve a la fuente del dispositivo. Se descartan tanto JetBrains Mono como una Nerd Font.
  - **Conflicto con el espejo de la sesión** (cuando exista el agente): la ventana del PC y la app mostrarán el mismo contenido, pero no el mismo aspecto — la ventana del PC usa la fuente que tenga el usuario ahí (posiblemente una Nerd Font, con iconos de prompts como Starship), y la app la fuente del sistema Android. Discrepancia visual aceptada, documentada en `../XTERM_DART.md`.
- **Cursor sin parpadeo** (decisión del 15/10/2026: se descarta implementarlo).
- Fila de teclas extra (`ExtraKeysBar`, 44 dp de alto, solo visible con el teclado abierto en `ready`): ESC, TAB, CTRL y ALT (se quedan pulsadas y afectan a la siguiente tecla: CTRL+letra manda el código de control, ALT antepone `ESC`), `-`, `/`, ↑/↓ (historial) y ocultar teclado.
- Tamaño de fuente configurable en Ajustes (10–22, por defecto 13).
- **Simplificaciones de la maqueta:** el disparador por tecla física solo abre la sesión, sin reconstruir qué carácter era (un `KeyEvent` crudo no equivale de forma fiable a texto de IME); en un móvil sin teclado físico el toque es el disparador real. No verificado en emulador si el teclado en pantalla pierde pulsaciones durante los 600 ms de `creating`.

## 6. Notas

Implementación ya verificada contra el código y corregida el 15/10/2026; el detalle completo está en [`../ui-v2/DESIGN.md`](../ui-v2/DESIGN.md), que sigue siendo preciso. Resumen:

- Lista con búsqueda (debounce 300 ms), recarga al deslizar y tarjetas de texto **seleccionable** (`SelectableText.rich`, 13 sp) con los enlaces detectados en cualquier parte del contenido, pulsables y subrayados en color de acento.
- El tipo de nota (texto/enlace) lo calcula el agente, no la app; el modelo `Note` del cliente ni siquiera tiene ese campo.
- Pie de cada tarjeta: origen + fecha relativa, y dos iconos (copiar, siempre con el aviso «Copiado»; editar).
- Formulario de un único campo (`surface`, 16 sp, mínimo 6 líneas), sin selector de tipo; «Eliminar» solo al editar, con confirmación.

## 7. Ajustes

Lista de grupos (`SettingsGroup`, radio 20, cabecera 13 sp `muted`), cada fila con mínimo 60 dp de alto:

| Grupo | Control | Rango / opciones |
|---|---|---|
| Unidades | Temperatura | Segmentado °C / °F |
| Unidades | Almacenamiento | Segmentado GB / GiB |
| Métricas | Alerta de temperatura | Interruptor |
| Métricas | Límite (si la alerta está activa) | Stepper 60–95 °C, pasos de 5 |
| Terminal | Tamaño de fuente | Stepper 10–22, con vista previa (misma fuente que la terminal real) |
| Apariencia | Tema | Segmentado Claro / Oscuro |
| Apariencia | Color de acento | Botón que abre una hoja inferior con los 6 colores |
| Dispositivo | Modo de conexión | Segmentado Local / iroh (`ConnectionFields`) |
| Dispositivo | Dirección del agente (modo Local) o identificador (modo iroh) | Campo de texto monoespaciado + botón «Guardar»; en Local valida el formato `host:puerto` |
| Dispositivo | Emparejar / Desemparejar | Botón; desemparejar pide confirmación |

Controles compartidos: `AppSwitch` (pista 50×30 en área táctil 56×44), `AppSegmented`, `AppStepper` (botones 44×44).

**Conexión con el PC** (`ConnectionFields`, grupo Dispositivo, encima de Emparejar/Desemparejar): selector Local/iroh con `AppSegmented` (no un desplegable nativo, para no introducir un componente que no se usa en ningún otro sitio). En Local, campo con la dirección `host:puerto` (por defecto `127.0.0.1:8443`); en iroh, campo con el identificador a mano — sin conexión real todavía (fase 2). Ambos valores se guardan a la vez en `SettingsRepository`, junto con el modo activo. Cambiar la dirección se aplica la próxima vez que se abre la app, no en caliente (misma simplificación que las particiones de disco, sección 4).

**Persistencia:** los ajustes se guardan localmente (`shared_preferences`) y se recuperan al reabrir la app. Mientras se cargan, la app muestra una pantalla en blanco de carga (placeholder temporal, sin diseño definitivo; ver sección 9).

## 8. Qué es simulado

| Repositorio | Implementación `Fake...` |
|---|---|
| `MacroRepository` | 4 macros de ejemplo en memoria; `run()` no hace nada |
| `TerminalRepository` | Shell simulado con `help`, `ls`, `pwd`, `whoami`, `uname`, `date`, `echo`, `clear`, historial con ↑/↓ y `Ctrl+C`/`Ctrl+L` |
| `NotesRepository` | 3 notas de ejemplo en memoria |
| `PairingRepository` | Emparejado por defecto; `pair()`/`unpair()` cambian un `ValueNotifier` local |

Todos se registran en `main.dart`; para conectar el agente real basta con escribir la implementación nueva y cambiarla ahí. `FakeMetricsRepository` (CPU/RAM aleatorias, temperatura derivada de la CPU, 3 particiones de ejemplo) sigue existiendo pero ya no se usa en `main.dart`: solo lo ven los tests.

**Repositorios ya no simulados:**
- `SettingsRepository`: `SharedPreferencesSettingsRepository` (persistencia local con `shared_preferences`), además de `InMemorySettingsRepository` para los tests.
- `MetricsRepository`: `HttpMetricsRepository` (nuevo) pide `GET http://<dirección>/metrics` al agente real (`feature/agent`, commit `8cf02c2`) y traduce su JSON (`cpu_percent`, `cpu_temp_c`, `ram_used_gb`, `ram_total_gb`, `partitions`) a los modelos de la app; `main.dart` lo construye con la dirección ya guardada en Ajustes. Probado contra un cliente HTTP simulado (`http/testing.dart`), no contra el agente real en marcha ni por USB.

## 9. Pendientes conocidos

Lista completa y actualizada en [`../../documentos-generales-del-proyecto/08-historial-de-cambios.md`](../../documentos-generales-del-proyecto/08-historial-de-cambios.md), sección «Pendiente». Los más relevantes para esta interfaz:

- Terminal: pestañas para varias sesiones a la vez; falta especificar la barra de pestañas en `doc/ui/` (ver `doc/agente/terminal-sesiones-tmux.md`, §10).
- Terminal: verificar en el emulador que el teclado en pantalla no pierde pulsaciones durante el retraso de creación de la sesión.
- Diseñar la pantalla de carga mientras se leen los ajustes guardados (hoy, placeholder blanco liso).
- Probar `HttpMetricsRepository` por USB con `adb reverse` contra el agente real (hoy solo probado con un cliente HTTP simulado).
