# Diseño final de la interfaz

> **Estado: definitivo.** Refleja el código real de `App-movil/lib/`, verificado leyendo cada pantalla el 20/10/2026; Métricas y la conexión de Ajustes, revisadas de nuevo el 14/11/2026; login y huella del certificado, el 18/11/2026. Sustituye a [`historico/ui-v1/design.md`](historico/ui-v1/design.md) y [`historico/ui-v2/design.md`](historico/ui-v2/design.md) como referencia de diseño; esos dos documentos se conservan como **historial** de cómo se llegó hasta aquí (el prototipo inicial y la primera especificación de Notas).

## 0. Cómo leer este documento

- Cada pantalla se describe tal como está implementada hoy, no como se planeó. Donde el código y un diseño anterior discrepaban, gana el código, y se anota el porqué.
- **Qué es simulado y qué no:** Inicio, Terminal y Notas siguen con repositorios `Fake...` en memoria (sección 8), porque esa parte del agente aún no existe. **Métricas, el login y Ajustes ya hablan con implementaciones reales:** por HTTPS (con la huella del certificado fijada) o por un túnel iroh, según el modo de Ajustes (ver secciones 4, 7 bis y 8), y `SharedPreferencesSettingsRepository` guarda los ajustes en el móvil.
- **Login (fase 3):** sin sesión, la app solo muestra `LoginView` (sección 7 bis); `ShellView` y todas las secciones solo aparecen con una sesión abierta.
- El diseño de la terminal del agente (sesiones con tmux) vive en [`../agente/terminal-sesiones-tmux.md`](../agente/terminal-sesiones-tmux.md) y **no está implementado en la app** (la sesión real y la ventana del PC son del agente, que todavía no tiene esa parte); la terminal vacía y las pestañas sí están implementadas sobre una maqueta sin agente. La sección 5 describe lo que hay hoy.

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

**Datos:** en modo local, `HttpMetricsRepository` pide `GET https://<dirección>/metrics` al agente, con la huella del certificado fijada y el token de sesión como `Bearer`; en modo iroh, `IrohMetricsRepository` envía la misma petición, también con el token, por un túnel iroh (ver `doc/iroh/`). Un `401` del agente no se muestra como fallo de conexión: sin sesión (`no_autenticado`) o con la sesión caducada (`sesion_caducada`) vuelve a la bienvenida, cada caso con su popup y, si el agente avisa de que ya no está emparejado (`desemparejado`), se olvida además la dirección, la huella y el identificador iroh. `ConnectionModeMetricsRepository` elige uno u otro según el modo de conexión de Ajustes, y lo reevalúa en cada llamada (ver sección 8). Las particiones (`DiskCard`) se leen una vez al abrir la app (`loadInfo()`), no en cada segundo junto con las gráficas: si cambian mientras la app está abierta, no se reflejan hasta reabrirla (simplificación asumida, no un error).

**Estados de la pantalla.** Mientras llegan los primeros datos, muestra un indicador con **«Conectando con el agente…»**. Si el agente no responde (tras 3 s de espera, o con cualquier otro fallo de conexión) y todavía no había datos, la pantalla muestra un aviso centrado, **«No se puede conectar con el agente»**, más el detalle del error y un botón **«Reintentar»** (`MetricsViewModel.retry()`). Si la conexión se pierde con los datos ya cargados, las tarjetas conservan los últimos valores y encima aparece el aviso **«Conexión perdida. Reintentando…»** con el detalle del error; no lleva botón, porque el sondeo sigue pidiendo una muestra cada segundo, y el aviso desaparece solo cuando vuelve a llegar una. Si el agente responde sin ninguna partición, la tarjeta de disco se sustituye por **«El agente no ha encontrado ninguna partición»** y el resto de tarjetas se muestra con normalidad. El sondeo se pausa al salir de la pantalla de Métricas o al pasar la app a segundo plano (`AppLifecycleListener`), y se reanuda al volver, para no seguir pidiendo datos al agente sin necesidad.

## 5. Terminal

**Dos niveles de estado.** `TerminalTabsViewModel` gestiona la lista de pestañas (cada una, un `TerminalViewModel` independiente con su propio `Terminal` de `xterm.dart` y su propio `TerminalRepository`); cada `TerminalViewModel` tiene su ciclo de vida (`TerminalSessionState`: `empty`, `creating`, `ready`). Aplica el diseño de `doc/agente/terminal-sesiones-tmux.md` §4 y §10 sobre un `FakeTerminalRepository` por pestaña (maqueta sin agente: no hay ventana del PC ni medidas reales de latencia).

**Sin pestañas** (lista vacía): pantalla completa con el aviso **«Toca para abrir una terminal en tu PC»**, centrado, sin barra de pestañas. Dispara la creación de la primera pestaña el primer toque sobre esa zona, o la primera tecla que no sea un modificador solo (CTRL, ALT, SHIFT, META).

**Con una o más pestañas:** barra de pestañas (`TerminalTabsBar`, 44 dp de alto, fondo `#15171A`, borde inferior `#2B2F34`, mismo lenguaje visual que `ExtraKeysBar`) encima de la terminal activa:
- Cada pestaña es un chip con su título y un icono «×» para cerrarla; la activa se resalta con fondo `#0D0F12`.
- **Título:** «Terminal 1», «Terminal 2»… (numeración secuencial, no reutilizada, no renombrable en esta versión — no hay nada de qué deducir un nombre, porque una pestaña nueva no empieza con ningún comando).
- Botón **«+»** al final de la barra: crea una pestaña nueva y **la deja creándose de inmediato** (sin pasar por su propio aviso «Toca para…»: pulsar «+» ya es la acción explícita de abrir una terminal).
- **Cerrar una pestaña (×) pide confirmación** («¿Cerrar esta pestaña?» / Cancelar / Cerrar) — se cierra igual tanto si hay algo en marcha como si no, porque la maqueta no puede saber si hay un proceso en primer plano (es del agente, «por verificar» en `terminal-sesiones-tmux.md`).
- **Escribir `exit` o Ctrl+D con la línea vacía cierra esa pestaña sola, sin confirmación** (ya es una acción explícita del usuario, a diferencia de tocar «×»).
- **Límite: 6 pestañas.** Al llegar al límite, «+» muestra el aviso «No caben más pestañas» (1,6 s), igual que el límite de macros en Inicio.
- Cerrar la última pestaña (por «×» o por `exit`) vuelve a la pantalla sin pestañas.
- **Cambiar de pestaña no corta nada:** todas las pestañas siguen su curso (en la maqueta, su shell simulado) estén o no en pantalla; no hay indicador de actividad en segundo plano en esta versión.
- **No se restaura ninguna pestaña al reabrir la app** (es una maqueta: ninguna sesión sobrevive a cerrarla).

**Dentro de cada pestaña** (`creating`/`ready`):
- **`creating`:** la terminal real ya está montada y enfocada por debajo (para no perder lo que se teclee con un teclado físico, que se guarda en cola y se envía en orden al quedar lista), pero se superpone un indicador con el texto **«Abriendo terminal…»**. En la maqueta, el retraso es un `Future.delayed` fijo de 600 ms.
- **`ready`:** `xterm.dart` (`TerminalView`) sobre el `Terminal` del `TerminalViewModel`, con el shell simulado del repositorio de esa pestaña.
- **Fuente: la del sistema** (decisión del 15/10/2026). No se pasa `fontFamily`, así que se usa el valor por defecto del paquete, `'monospace'`, que en Android resuelve a la fuente del dispositivo. Se descartan tanto JetBrains Mono como una Nerd Font.
  - **Conflicto con el espejo de la sesión** (cuando exista el agente): la ventana del PC y la app mostrarán el mismo contenido, pero no el mismo aspecto — la ventana del PC usa la fuente que tenga el usuario ahí (posiblemente una Nerd Font, con iconos de prompts como Starship), y la app la fuente del sistema Android. Discrepancia visual aceptada, documentada en `xterm-dart.md`.
- **Cursor sin parpadeo** (decisión del 15/10/2026: se descarta implementarlo).
- Fila de teclas extra (`ExtraKeysBar`, 44 dp de alto, solo visible con el teclado abierto en `ready`): ESC, TAB, CTRL y ALT (se quedan pulsadas y afectan a la siguiente tecla: CTRL+letra manda el código de control, ALT antepone `ESC`), `-`, `/`, ↑/↓ (historial) y ocultar teclado.
- Tamaño de fuente configurable en Ajustes (10–22, por defecto 13).
- **Simplificaciones de la maqueta:** el disparador por tecla física solo abre la sesión, sin reconstruir qué carácter era (un `KeyEvent` crudo no equivale de forma fiable a texto de IME); en un móvil sin teclado físico el toque es el disparador real. No verificado en emulador si el teclado en pantalla pierde pulsaciones durante los 600 ms de `creating`.

## 6. Notas

Implementación ya verificada contra el código y corregida el 15/10/2026; el detalle completo está en [`historico/ui-v2/design.md`](historico/ui-v2/design.md), que sigue siendo preciso. Resumen:

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
| Dispositivo | Dirección del agente (modo Local) | Campo de texto monoespaciado + botón «Guardar»; valida el formato `host:puerto` |
| Dispositivo | Huella del certificado (modo Local) | Campo de texto monoespaciado; valida que sean 64 caracteres hexadecimales |
| Dispositivo | Identificador (modo iroh) | Campo de texto monoespaciado + botón «Guardar»; valida que sean 64 caracteres hexadecimales |
| Dispositivo | Cerrar sesión | Botón, solo visible con una sesión abierta |
| Dispositivo | Desemparejar | Botón; pide confirmación y borra dirección, huella e identificador iroh además de la sesión |

Controles compartidos: `AppSwitch` (pista 50×30 en área táctil 56×44), `AppSegmented`, `AppStepper` (botones 44×44).

**Conexión con el PC** (`ConnectionFields`, grupo Dispositivo, encima de Cerrar sesión/Desemparejar): selector Local/iroh con `AppSegmented` (no un desplegable nativo, para no introducir un componente que no se usa en ningún otro sitio). En Local, dos campos: la dirección `host:puerto` (por defecto `127.0.0.1:8443`) y la huella del certificado (64 caracteres hexadecimales, que hasta que haya escáner de QR se compara a ojo con la que muestra la TUI); en iroh, un único campo con el identificador del agente, que usa `IrohMetricsRepository` para conectar (ver `doc/iroh/`). Un «Guardar» por modo valida y guarda sus campos a la vez en `SettingsRepository`, junto con el modo activo. Cambiar la dirección, la huella, el identificador o el modo se aplica en caliente: los repositorios de métricas los leen en cada petición, sin reiniciar la app (si el identificador cambia con una conexión iroh abierta, el repositorio la cierra y abre otra).

**Persistencia:** los ajustes se guardan localmente (`shared_preferences`) y se recuperan al reabrir la app. Mientras se cargan, la app muestra una pantalla de carga: `CircularProgressIndicator` (color de acento) y el texto «Sysmote» (`t.muted2`), centrados sobre `t.bg` — sin logo, porque el proyecto no tiene ningún asset de imagen declarado.

## 7 bis. Login (fase 3)

`LoginView` (`features/auth/`), guiada por el estado de `AuthViewModel` (`AuthStage`). Sin sesión se ve la bienvenida (§7 bis.1) y desde ella se abren los formularios y pantallas siguientes:

- **Bienvenida** (§7 bis.1): «Sysmote» y los botones para conectar con el agente, iniciar sesión o registrar la cuenta; también avisa, sin botón de reintentar, de por qué no responde el PC.
- **Registro** (sin cuenta y registro abierto; se abre con «Registrar cuenta»): formulario «Crear la cuenta» con código de registro (sin guiones o con ellos, en mayúsculas o minúsculas), usuario, contraseña y nombre del dispositivo (opcional). Si falta el código, el usuario o la contraseña, avisa de lo que falta. Cada error del contrato tiene su mensaje: código no válido, código caducado («pulsa configuración inicial en la TUI para generar otro») y contraseña débil con sus motivos (mínimo 5 caracteres, un número y una mayúscula). Hasta que haya escáner de QR (fase 8), el código se escribe a mano. Si el agente responde `registro_cerrado` al enviarlo (otro móvil se adelantó), vuelve a la bienvenida con el popup de «ya tiene una cuenta».
- **Login** (con cuenta; se abre con «Iniciar sesión»): formulario con usuario, contraseña (oculta) y el nombre de este dispositivo (opcional: se propone el fabricante y el modelo del móvil, `Móvil Android` si se deja vacío, y solo sirve para el historial de la TUI; sin guardar en Ajustes). Si falta el usuario o la contraseña, avisa de lo que falta en lugar de no hacer nada. Si `sesion_activa` es `true`, un aviso encima del formulario explica que hará falta confirmar en la TUI.
- **Bloqueado** (`429 demasiados_intentos`): aviso con la cuenta atrás en segundos (`espera_s`) devuelta por el agente; el botón «Entrar» se deshabilita hasta que llega a cero.
- **Esperando confirmación** (`202` del login, ya había una sesión activa): mensaje con el dispositivo que la tiene abierta, cuenta atrás de 5 minutos y botón «Cancelar»; sondea `GET /login/solicitud/{id}` cada 2 s hasta que se aprueba, se rechaza o caduca.
- Con sesión, la vista no se muestra: `app.dart` pasa a `ShellView`, y vuelve a la bienvenida si se pierde la sesión.
- **«Conectar con el agente»** (solo sin emparejar): abre en una hoja inferior los mismos campos de dirección, huella e identificador iroh de Ajustes, porque Ajustes queda dentro de la app y sin esta salida no se podría emparejar. Al cerrarla se vuelve a comprobar el agente.

Construida con el mismo sistema visual que el resto de la app (`AppTextField`, con un `obscureText` nuevo para la contraseña; `AppButton`; tokens). El token se guarda con `TokenStorage` (Android Keystore vía `flutter_secure_storage`), se mantiene en memoria para las peticiones y se borra al cerrar sesión, desemparejar o si el agente devuelve `401`, y nunca por un fallo de red. Cerrar sesión y desemparejar también olvidan lo local aunque el PC esté apagado o ya no reconozca el token.

### 7 bis.1 Pantalla de bienvenida (diseño aprobado el 19/11/2026, implementada el 27/11/2026)

Sustituye a la pantalla de «agente inalcanzable» y al botón «Conexión con el PC» de los formularios.

Un solo diseño, con el nombre «Sysmote» centrado arriba (sin logo por ahora) y los botones abajo. Cuáles se ven depende de si la app ya está emparejada:

| Estado | Botones |
|---|---|
| **Sin emparejar** (primer inicio) | «Conectar con el agente», que abre la hoja de conexión (dirección, huella e identificador iroh). Sin mensajes de error al arrancar: el aviso de abajo solo sale tras guardar la hoja de conexión |
| **Emparejada** | «Iniciar sesión» y «Registrar cuenta», siempre los dos |

**Cuándo está emparejada:** la app guarda una marca la primera vez que el agente responde bien. La marca se borra si se cambia la dirección, la huella o el identificador iroh, o al desemparejar. Tras guardar la hoja de conexión, la app comprueba el agente; si responde, marca y muestra los dos botones; si no, sigue en «Conectar con el agente» con el aviso de abajo.

**Qué hace cada botón.** La app consulta antes el estado del agente (`/estado`):

| Estado del agente | «Registrar cuenta» | «Iniciar sesión» |
|---|---|---|
| Con cuenta | Popup: «Este agente ya tiene una cuenta. Inicia sesión.» | Abre el formulario |
| Sin cuenta y registro abierto | Abre el formulario | Popup: «El agente aún no tiene cuenta. Regístrala.» |
| Sin cuenta y registro cerrado | Popup: «El registro está cerrado. Ábrelo desde la TUI del PC.» | El mismo popup |

Si el agente responde `registro_cerrado` al enviar el formulario de registro (otro móvil se adelantó), aparece también el popup de «ya tiene una cuenta».

**Si el PC no responde,** aparece bajo los botones un aviso pequeño en gris, **sin botón de reintentar**, con la causa:

| Causa | Mensaje |
|---|---|
| Sin respuesta a tiempo | «El PC no responde. ¿Está encendido y en la misma red?» |
| No se pudo abrir la conexión | «No se puede llegar al PC. Revisa la dirección.» |
| La huella del certificado no coincide | «La huella no coincide con la de este PC.» |
| Identificador iroh no válido | «El identificador del PC no es válido.» |
| Respuesta inesperada o código HTTP | «El agente respondió algo inesperado.» |

La app vuelve a comprobar el agente al pulsar «Iniciar sesión» o «Registrar cuenta» y cada vez que vuelve a primer plano (solo desde la bienvenida y con la app emparejada). Un token guardado no se borra por un fallo de red.

La comprobación empieza por el token guardado: si el agente lo acepta, la app entra directamente, sin pasar por la bienvenida. Mientras se comprueba, los botones se deshabilitan y en el sitio del aviso aparece un indicador pequeño. Los popups son el diálogo nativo de Android (`AlertDialog`) con el mensaje y el botón «Aceptar».

**Formularios** de login y registro: sin «Conexión con el PC»; tienen un botón «Volver» a la bienvenida, y el gesto atrás del sistema hace lo mismo. Para cambiar de PC se usa Ajustes o desemparejar.

**Sesión caducada:** el token dura 7 días desde el login. Al caducar, el agente devuelve `401 sesion_caducada` (un token desconocido o mal formado sigue dando `no_autenticado`), la app borra el token y muestra la bienvenida con un popup (diálogo nativo con «Aceptar»): «Tu sesión ha caducado. Inicia sesión de nuevo.»

**Sesión no válida:** si el agente responde `401 no_autenticado` a una petición con token (se revocó desde la TUI, se cerró la sesión en el PC o el token ya no vale), la app borra el token y muestra la bienvenida con el popup «Tu sesión ya no es válida. Inicia sesión de nuevo.». Cada popup sale una sola vez, tanto al arrancar con el token guardado como en mitad de la sesión. No sale sin token guardado, con `desemparejado` (que olvida el equipo y vuelve al estado inicial) ni con un login fallido (`credenciales_invalidas` es otro error, y se muestra en el formulario).

## 8. Qué es simulado

| Repositorio | Implementación `Fake...` |
|---|---|
| `MacroRepository` | 4 macros de ejemplo en memoria; `run()` no hace nada |
| `TerminalRepository` | Shell simulado con `help`, `ls`, `pwd`, `whoami`, `uname`, `date`, `echo`, `clear`, historial con ↑/↓ y `Ctrl+C`/`Ctrl+L` |
| `NotesRepository` | 3 notas de ejemplo en memoria |

Todos se registran en `main.dart`; para conectar el agente real basta con escribir la implementación nueva y cambiarla ahí. `FakeMetricsRepository` (CPU/RAM aleatorias, temperatura derivada de la CPU, 3 particiones de ejemplo) ya no está en `lib/`: vive en `test/fakes/` y solo lo usan los tests.

**Repositorios ya no simulados:**
- `AuthRepository`: `HttpAuthRepository` (HTTPS con la huella del certificado fijada: el cliente no trae ninguna CA y solo acepta el certificado cuyo SHA-256 coincide con la huella guardada) e `IrohAuthRepository` (HTTP crudo por el túnel, sin TLS propio, con el identificador iroh como garantía), elegidos por `ConnectionModeAuthRepository` según el modo de Ajustes; Autenticación y Métricas comparten una única conexión iroh. Probados contra un cliente HTTP simulado y una conexión iroh falsa, y por HTTPS contra el agente real de `feature/agent` (registro, login con sesión activa y su aprobación, `401`, desemparejar y bloqueo por intentos); el camino por iroh con el móvil sigue sin probarse. `FakeAuthRepository` queda para los tests.
- `SettingsRepository`: `SharedPreferencesSettingsRepository` (persistencia local con `shared_preferences`), además de `InMemorySettingsRepository` para los tests.
- `MetricsRepository`: `HttpMetricsRepository` (nuevo) pide `GET https://<dirección>/metrics` (ahora con huella fijada y token) al agente real (`feature/agent`, commit `8cf02c2`) y traduce su JSON (`cpu_percent`, `cpu_temp_c`, `ram_used_gb`, `ram_total_gb`, `partitions`) a los modelos de la app. `main.dart` lo envuelve, junto con `IrohMetricsRepository`, en `ConnectionModeMetricsRepository`, que usa uno u otro según el modo de Ajustes. Probado contra un cliente HTTP simulado (`http/testing.dart`) y, ya cerrada la fase 1, por USB con `adb reverse` contra el agente real y con el APK release.

## 9. Pendientes conocidos

Lista completa y actualizada en [`../documentos-generales-del-proyecto/04-plan-de-fases.md`](../documentos-generales-del-proyecto/04-plan-de-fases.md), sección «Pendientes de cada fase» (dentro de «Sueltas y cierres»). El más relevante para esta interfaz:

- Terminal: verificar en el emulador que el teclado en pantalla no pierde pulsaciones durante el retraso de creación de la sesión (intentado el 19/10/2026, sin acceso visual al emulador en esa sesión).
- Conexión por USB con `adb reverse`: sin probar. El 19/11/2026 se probaron en un Xiaomi Redmi 13C (Android 15) el registro, el login y las métricas por red local (HTTPS con la huella fijada) y el login completo por iroh con datos móviles.
