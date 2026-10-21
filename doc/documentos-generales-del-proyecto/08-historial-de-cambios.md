# Historial de cambios y decisiones

Este documento recoge, por orden cronológico, las cosas que **originalmente eran de una forma y acabaron siendo de otra**: qué se pensó, qué se hizo al final y por qué. Su objetivo es mantener el rastro de esos cambios **fuera** de los documentos 01–07, para que estos describan solo el estado actual del proyecto y no se saturen de «antes decía…».

- **Qué va aquí:** cambios de diseño, de tecnología o de alcance; ideas descartadas y su motivo; decisiones tomadas durante la implementación que se apartan de lo documentado.
- **Qué no va aquí:** el estado actual (eso va en 01–07) ni el registro de decisiones de diseño general (eso es `07-resumen-decisiones-y-contexto.md`).
- **Formato de cada entrada:** fecha, título corto, qué era, qué es ahora, por qué, qué documentos o código afecta y estado (`aplicado`, `pendiente de aplicar` o `pendiente de decidir`).
- **Convención:** las entradas nuevas se añaden al final de su sección. Una entrada no se borra: si algo vuelve a cambiar, se añade otra.

## Índice

| Fecha | Cambio | Estado |
|---|---|---|
| 12/10/2026 | Notas: de un campo de texto único a lista con CRUD, con tipo deducido y enlaces pulsables | Aplicado |
| 12/10/2026 | Pantalla «Opciones» renombrada a «Ajustes» | Aplicado |
| 12/10/2026 | Terminal: de widget propio a `xterm.dart` | Aplicado |
| 12/10/2026 | Gráficas: de `fl_chart` a `CustomPainter` | Aplicado |
| 12/10/2026 | Documentación de interfaz: `doc/UI` pasa a `doc/ui/ui-v1` y `ui-v2` | Aplicado |
| 12/10/2026 | Temperatura de CPU: color del valor | Aplicado |
| 12/10/2026 | Acciones rápidas: de lista con buscador a cuadrícula con carpetas | Aplicado en la memoria; ajustes de UI pendientes |
| 12/10/2026 | Notas: el tipo (texto/enlace) lo deduce el agente | Aplicado en la documentación |
| 12/10/2026 | Carpeta del cliente: `app/` pasa a `App-movil/` | Aplicado |
| 12/10/2026 | Revisión de coherencia entre documentación e implementación | Aplicado |
| 12/10/2026 | Herramienta del PC: de CLI con Typer a TUI con botones (Textual) | Aplicado en la documentación |
| 12/10/2026 | Registro del usuario: de CLI o código de un solo uso a QR en la TUI y cuenta creada en la app | Aplicado en la documentación |
| 12/10/2026 | Exportación de datos y de estructura de la BD desde la TUI | Aplicado en la documentación |
| 12/10/2026 | Replanificación: interfaz primero y beta sin login | Aplicado en la documentación |
| 12/10/2026 | Auditoría de la documentación frente a fuentes oficiales | Aplicado |
| 12/10/2026 | Cronograma adelantado: la interfaz definitiva ya está hecha | Aplicado en la documentación |
| 14/10/2026 | Terminal: de PTY ligado a la conexión a sesiones persistentes con tmux | Decidido y documentado; implementación en la fase 4 |
| 15/10/2026 | Inicio: validación de nombre de macro y selector de icono | Aplicado en código |
| 15/10/2026 | Tema oscuro: color de acento aclarado para contraste suficiente | Aplicado en código |
| 15/10/2026 | Terminal: fuente del sistema en vez de Nerd Font; se descarta el parpadeo del cursor | Aplicado en código y documentación |
| 15/10/2026 | Documentación de interfaz: `doc/ui/ui-final/DESIGN.md` como referencia única del estado actual | Aplicado |
| 15/10/2026 | Tercera auditoría: deduplicación de detalle técnico repetido | Aplicado |
| 15/10/2026 | TUI del agente: librería confirmada y construcción adelantada a la fase 1 | Aplicado en la documentación |
| 15/10/2026 | Estructura de la TUI: de botones por fase a cuatro secciones fijas | Aplicado en la documentación |
| 15/10/2026 | Nuevo documento: especificación de la TUI en doc/agente/ | Aplicado |
| 19/10/2026 | Inicio: papelera sobre carpeta; Ajustes: persistencia local y fuente de la vista previa | Aplicado |
| 19/10/2026 | Terminal: estado vacío y creación de sesión al primer toque o tecla | Aplicado en código (maqueta sin agente) |
| 19/10/2026 | Métricas: repositorio HTTP real contra el agente; Ajustes: dirección del agente y modo de conexión (local/iroh) | Aplicado en la app; agente y prueba por USB en marcha por separado |
| 19/10/2026 | Terminal: pestañas; Arranque: pantalla de carga con spinner y texto | Aplicado en código |
| 19/10/2026 | Fase 1: el objetivo de métricas seguía pidiendo el endpoint completo | Aplicado en main y feature/agent; pendiente en feature/interfaz |
| 19/10/2026 | Interfaz: conexión con el agente, timeout, reintento y dirección en caliente | Aplicado en código |
| 19-20/10/2026 | Interfaz: identificador de Android, nombre visible y enlaces externos | Aplicado en código |
| 20/10/2026 | Interfaz: limpieza — diálogos, toasts y botón flotante unificados | Aplicado en código |
| 19/10/2026 | Agente: métricas en GB decimales y sin particiones duplicadas | Aplicado en código |
| 19-20/10/2026 | Agente: comando `companion` instalable y resaltado de sección activa en la TUI | Aplicado en código |
| 19/10/2026 | Agente: versiones mínimas, `pydantic` y `httpx2` en los tests | Aplicado en código |

---

## Entradas

### 12/10/2026 — Notas: de campo de texto único a lista con CRUD

- **Qué era:** el prototipo v1 (`doc/ui/ui-v1`) tenía un único campo de texto a pantalla completa, compartido con el PC en ambos sentidos, con estado «Sincronizando…».
- **Qué es ahora:** una **lista de notas** con búsqueda, recarga al deslizar, formulario de crear y editar, y borrado con confirmación (`doc/ui/ui-v2/DESIGN.md`).
- **Por qué:** el campo único no cubría el espacio compartido definido en la memoria técnica (notas de texto y enlaces con CRUD, búsqueda y recarga bajo demanda). Además, la entidad `nota` ya existía en la base de datos con tipo, origen y fechas.
- **Cambios derivados durante el diseño de la v2:**
  1. **Tipo sin elegir.** Se propuso un selector «Texto / Enlace» y se descartó: añade pasos al usuario. El tipo se **deduce** del contenido.
  2. **Enlaces en cualquier parte del texto.** Primero solo contaba la nota cuyo contenido completo era una dirección; después se pidió detectarlas también en mitad de un texto (`http://`, `https://` y `www.`).
  3. **Interacción tipo burbuja de mensajería.** Se descartó mostrar una lista de «Enlaces» en el formulario: el `TextField` nativo no permite fragmentos pulsables sin perder el menú de selección de Android. En su lugar, la **tarjeta** es de solo lectura (texto seleccionable con enlaces pulsables) y el **formulario** solo edita. Editar y copiar pasan a iconos en el pie de la tarjeta.
- **Afecta a:** `ui-v1` §6 (marcado como descartado), `ui-v2` (nuevo), `07` (3.5 y sección 4), `ESTRUCTURA_FLUTTER.md`. Código: `App-movil/lib/features/notes/`.
- **Estado:** aplicado, incluidos los documentos generales (ver la entrada sobre el tipo deducido por el agente).

### 12/10/2026 — «Opciones» pasa a «Ajustes»

- **Qué era:** la pantalla del engranaje del drawer se llamaba «Opciones» en el prototipo y en su especificación.
- **Qué es ahora:** «Ajustes», en el título, el drawer, el texto accesible y los tests.
- **Por qué:** decisión del autor, nombre más habitual en apps Android.
- **Afecta a:** `ui-v1` (aviso y título de §7, el prototipo HTML se deja como histórico), `ui-v2`, `ESTRUCTURA_FLUTTER.md`. Código: `ShellViewModel` (`Section.settings`), `app_drawer.dart`.
- **Estado:** aplicado.

### 12/10/2026 — Terminal: de widget propio a `xterm.dart`

- **Qué era:** en la propuesta inicial de estructura se planteó un widget de terminal propio y sencillo en la fase de interfaz, dejando `xterm.dart` para cuando se conectara el agente.
- **Qué es ahora:** la terminal usa **`xterm.dart` 4.0.0** desde el principio, con el shell simulado detrás de `TerminalRepository`.
- **Por qué:** `xterm.dart` es la elección confirmada en `CLAUDE.md` y en el documento 02; un widget propio no soportaría colores ANSI, programas a pantalla completa ni el redimensionado del PTY, y habría que rehacerlo después.
- **Efectos conocidos:** el cursor **no parpadea** (la v1 lo especificaba parpadeante) y la **Nerd Font** sigue pendiente (se usa JetBrains Mono).
- **Afecta a:** `ESTRUCTURA_FLUTTER.md` (actualizado en la revisión de coherencia), `ui/XTERM_DART.md` (nuevo). Código: `App-movil/lib/features/terminal/`.
- **Estado:** aplicado.

### 12/10/2026 — Gráficas: de `fl_chart` a `CustomPainter`

- **Qué era:** `02-necesidades-tecnologicas.md` y la fase 1 del plan preveían `fl_chart` para las gráficas de CPU y RAM.
- **Qué es ahora:** las gráficas de área se dibujan con un `CustomPainter` propio (sin dependencia).
- **Por qué:** el diseño del prototipo es una gráfica de área sencilla con cuadrícula fija; dibujarla directamente es más corto y exacto que configurar una librería, y evita una dependencia.
- **Afecta a:** `02` (tabla de paquetes) y `04` (fase 1). Código: `App-movil/lib/features/metrics/widgets/area_chart.dart`.
- **Estado:** aplicado en código y en los documentos 02 y 04.

### 12/10/2026 — Documentación de interfaz reorganizada

- **Qué era:** los archivos del prototipo estaban en `doc/UI/` y toda la documentación en `doc/`.
- **Qué es ahora:**
  - `doc/ui/` con `ui-v1/` (prototipo inicial, histórico), `ui-v2/` (especificación definitiva de Notas) y `XTERM_DART.md`;
  - `doc/documentos-generales-del-proyecto/` con los documentos 01–07, este historial y `ESTRUCTURA_FLUTTER.md`.
- **Por qué:** distinguir la implementación antigua (idea descartada para Notas) de la definitiva y separar la documentación de interfaz de la general.
- **Afecta a:** enlaces internos y el apartado «Documentación» de `CLAUDE.md`.
- **Estado:** aplicado.

### 12/10/2026 — Temperatura de CPU: color del valor

- **Qué era:** el prototipo pintaba el valor con `#16181D` fijo, casi ilegible en tema oscuro.
- **Qué es ahora:** usa el color `ink` del tema (legible en claro y oscuro), y rojo `#B42318` con la etiqueta «Alta» si supera el límite.
- **Por qué:** corregir un fallo del prototipo.
- **Estado:** aplicado.

### 12/10/2026 — Acciones rápidas: de lista con buscador a cuadrícula con carpetas

- **Qué era:** la memoria técnica (Módulo E) describía una **lista** de acciones agrupadas por grupo, con buscador, ordenación, formulario de acción y ficha con estadísticas e historial. En el modelo, `grupo` tenía `icono` y `orden`, y `accion_rapida` no tenía ni icono ni orden.
- **Qué es ahora:** una **cuadrícula** de botones con carpetas, reordenado y fusión por arrastre, papelera y creación rápida de acciones. Terminología de la interfaz: *macro* = `accion_rapida`, *carpeta* = `grupo`.
- **Por qué:** diseño validado en el prototipo y en el emulador; más rápido de usar que una lista para pocas acciones, y es la pantalla principal de la app.
- **Decisión tomada (12/10/2026):** adaptar la memoria a la cuadrícula **conservando** la ficha de acción y el historial de ejecuciones como pantalla secundaria. El historial no se retira porque la tabla `ejecucion` alimenta las notificaciones de acciones (Módulo G) y forma parte del esquema evaluado frente a los requisitos de DAM.
- **Cambios aplicados en la documentación:**
  1. **Módulo E (`01`):** descripción de la cuadrícula y de la organización por arrastre; **eliminado** «Búsqueda y ordenación»; reglas nuevas (una carpeta solo contiene acciones, máximo 40 elementos de primer nivel); sección «Creación rápida»; pantallas rehechas (inicio, carpeta, edición de carpeta y creación rápida, ficha secundaria, historial); API sin `q` ni `orden` y con `PUT /orden`.
  2. **Modelo de datos (`01` §6.2 y `03`):** `grupo.icono` → **`grupo.color`**; `accion_rapida` gana **`icono`** y **`orden`**. `orden` comparte secuencia en el primer nivel (carpetas y acciones sin carpeta).
  3. **`03`:** descripción de la cuadrícula y de sus reglas, filas de las tablas, ruta de la API y lista de pantallas.
  4. **`04` fase 7:** objetivos de BD, agente y app ajustados (la cuadrícula ya se diseña en la fase 1 con datos simulados; en la fase 7 se conecta al agente).
- **Cambio de significado:** `grupo.icono` se sustituye (no se mantiene) porque la interfaz no usa icono de carpeta.
- **Huecos que la interfaz actual aún no cubre:**
  - **Papelera sobre una carpeta:** la UI elimina la carpeta **con todo su contenido**, mientras la regla de negocio pide elegir entre «mover a Sin grupo» o «borrar». Hay que añadir esa pregunta en la UI, o cambiar la regla.
  - **Selector de icono:** las acciones nuevas son siempre `bolt`; no existe forma de elegir otro icono.
  - **Acceso a la ficha de acción:** la pulsación larga ya es de arrastre, así que el acceso a la ficha (y al historial) se define en la fase 7.
  - **Valores por defecto de la creación rápida** (directorio, tiempo máximo, notificar al terminar): definirlos al implementar el agente.
- **Estado:** aplicado en la memoria (01, 03 y 04); ajustes de interfaz pendientes (ver arriba).

### 12/10/2026 — Notas: el tipo (texto/enlace) lo deduce el agente

- **Qué era:** la tabla `nota` tenía `tipo (texto / enlace)` sin decir quién lo calcula; la v2 de la especificación hablaba de «deducirlo al guardar» sin indicar dónde, y el plan de la fase 9 pedía «URL válida» en el formulario.
- **Qué es ahora:** el **agente** deduce el tipo al guardar (`enlace` si el contenido incluye una dirección `http://`, `https://` o `www.` en cualquier parte; `texto` si no). La app solo envía el contenido (`NotesRepository.create(content)`) y usa la misma regla únicamente para pintar los enlaces como pulsables. El formulario no valida URL.
- **Por qué:** una sola fuente de la regla, y cubre también las notas creadas desde la TUI del PC.
- **Afecta a:** `01` (Módulo F), `03` (tabla `nota`), `04` (fase 9), `ui-v2` (§2, §3 y §6).
- **Estado:** aplicado en la documentación.

### 12/10/2026 — Carpeta del cliente: `app/` pasa a `App-movil/`

- **Qué era:** la documentación y `CLAUDE.md` hablaban de un monorepo con `app/` (Flutter) y `agent/` (Python).
- **Qué es ahora:** el cliente vive en `App-movil/`. `agent/` aún no existe: se crea con el agente.
- **Afecta a:** `CLAUDE.md`, `01`, `02`, `03` y `04`.
- **Estado:** aplicado.

### 12/10/2026 — Revisión de coherencia entre documentación e implementación

Correcciones aplicadas tras revisar todos los documentos frente al código:

| Documento | Corrección |
|---|---|
| `01` Módulo B | La pantalla de métricas muestra CPU, temperatura, RAM y disco; el resto de datos del agente queda para ampliar |
| `01` Módulo F, `03`, `04` fase 9 | Tipo de nota deducido por el agente; sin validación de URL en el formulario; descripción de la pantalla |
| `02` §1.3 y `04` fase 1 | Gráficas con `CustomPainter`; añadidos `xterm`, `flutter_svg` y `url_launcher` a la tabla de paquetes |
| `03` §5c | Pantalla de ajustes con su contenido real; «logout» y «datos del servidor» quedan para cuando exista el login |
| `06` | «Copiar al portapapeles de un toque» ya forma parte del TFG |
| `ui-v1` | Nueva sección 10 con las diferencias de la implementación (cursor sin parpadeo, vibración, tamaños, aviso sin `$`, ondas, etc.) |
| `ui-v2` | Tipo deducido por el agente; fecha «ahora» para menos de un minuto |
| `ESTRUCTURA_FLUTTER.md` | Reescrito: árbol real, `xterm.dart` en lugar de widget propio, repositorios y ejemplo al día |
| `CLAUDE.md`, `01`–`04` | `app/` → `App-movil/` |

**Sin cambios, por no ser incoherencia sino plan:** la Nerd Font sigue siendo un objetivo de la fase 4 (hoy se usa JetBrains Mono); `agent/` se crea con el agente.

### 12/10/2026 — Herramienta del PC: de CLI a TUI

- **Qué era:** una CLI con Typer y un comando por tarea (`companion setup`, `show-pairing`, `install-service`, `uninstall-service`, `status`, `passwd`, `logout-all`, `note add`, `note list`, `notify`). El autor prefería CLI antes que TUI.
- **Qué es ahora:** al escribir `companion` se abre una **TUI con Textual** con botones para todo (configuración inicial, QR, servicio, estado, contraseña, cerrar sesiones, notas y exportaciones). Solo `companion serve` (lo arranca systemd) y `companion notify "mensaje"` (scripts y *hooks*) siguen siendo comandos de terminal con Typer. El QR se dibuja con `qrcode`.
- **Por qué:** botones en lugar de comandos que recordar.
- **Afecta a:** `01` (5.1, 8.1, 8.2), `02` (2.6), `03` (sección 7), `04` (fases 3, 5, 7 y 9), `07` (3.1 y 3.2), plan de estudios.
- **Estado:** aplicado en la documentación.

### 12/10/2026 — Registro del usuario por QR

- **Qué era:** `companion setup` creaba el usuario desde la CLI; como alternativa pendiente de revisión, un código de un solo uso y un formulario de registro en la app.
- **Qué es ahora:** la TUI muestra un QR con la dirección, la huella del certificado, el identificador iroh y un código de registro de un solo uso con caducidad corta. La app lo escanea, muestra «Emparejado, se necesita crear autenticación» y abre un diálogo de usuario y contraseña. El modo registro se cierra con la primera cuenta. Se implementa en la **fase 9**; hasta entonces el botón de configuración inicial de la TUI crea el usuario directamente.
- **Por qué:** decisión del autor; además la huella llega en el QR y no hay que compararla a ojo.
- **Afecta a:** `01` (0, 5.1, 5.4, 7), `03`, `04` (fases 3 y 9), `07` (3.2 y 9).
- **Estado:** aplicado en la documentación.

### 12/10/2026 — Exportación de la base de datos desde la TUI

- **Qué era:** no existía.
- **Qué es ahora:** dos botones en la TUI (fase 7) que guardan en el escritorio del usuario (`XDG_DESKTOP_DIR`, o la carpeta personal) un JSON con los datos (sin `sesion`, `intento_login` ni el hash de la contraseña) y una carpeta con `tablas.sql`, `indices.sql`, `vistas.sql` y `triggers.sql` leídos de `sqlite_schema`.
- **Por qué:** petición del autor. Se descartaron CSV (un archivo por tabla, pierde tipos) y SQL con `INSERT` (mezcla datos y estructura) para los datos.
- **Afecta a:** `01` (6.3), `03`, `04` (fase 7), `07` (3.7), plan de estudios (Unidad 9).
- **Estado:** aplicado en la documentación.

### 12/10/2026 — Replanificación: interfaz primero y beta sin login

- **Qué era:** fase 1 métricas, fase 2 iroh (noviembre), fase 3 seguridad y fase 4 instalación antes de Navidad; terminal en la fase 5. La beta incluía login e instalación.
- **Qué es ahora:** fase 1 interfaz definitiva con *placeholders* y métricas (mediados de octubre – mediados de noviembre); fase 2 iroh (hasta Navidad); **beta sin login** (solo métricas de solo lectura, agente arrancado a mano); fase 3 seguridad con una TUI mínima (enero); fase 4 terminal (hasta finales de febrero); fase 5 instalación; fases 6–10 en el mismo orden, ajustadas para terminar a finales de mayo. En el plan de estudios se intercambian las Unidades 6 (ahora terminal) y 7 (ahora empaquetado).
- **Por qué:** el autor quiere empezar por la interfaz y una beta mínima. La seguridad va antes de la terminal porque esta da acceso a la shell.
- **Efectos conocidos:** calendario apretado; si el hito de febrero es a principios de mes, la terminal no llegaría.
- **Afecta a:** `01`, `03`, `04`, `05`, `07`, plan de estudios.
- **Estado:** aplicado en la documentación.

### 12/10/2026 — Auditoría de la documentación frente a fuentes oficiales

- **Qué se hizo:** revisión de los 13 documentos (01–08, `ESTRUCTURA_FLUTTER.md`, `ui/` y el plan de estudios) contra documentación oficial y registros de paquetes. Sin datos inventados; correcciones aplicadas.
- **Correcciones principales:**
  - el límite de glibc ≥ 2.28 lo impone solo el binding de Python de iroh (cryptography y argon2 tienen paquetes para musl);
  - el emulador x86_64 no está soportado oficialmente por iroh, pero no está demostrado que no funcione;
  - copiar y pegar en `xterm.dart` hay que programarlo en el móvil; `url_launcher` necesita el modo de aplicación externa; `SelectableText` no recorta con «…»; el menú de selección lo dibuja Flutter;
  - el plan de estudios enseña `CustomPainter` en lugar de `fl_chart`;
  - el modelo de amenazas recoge la beta sin login y los permisos de archivos del agente;
  - la memoria técnica (01) gana un apartado «Navegación y pantallas de la app»; energía, procesos, reglas, notificaciones, login, conexión y escaneo del QR quedan con ubicación pendiente de revisión;
  - requisitos completos de `connectedDevice`, `dataSync` solo con targetSdk ≥ 35, `PRAGMA foreign_keys` en cada conexión, requisitos de red de iroh (`dns.iroh.link`, DNS);
  - verificación de desarrolladores de Android (2027) en las ideas de futuro;
  - fechas de las fases 8–10 ajustadas para terminar a finales de mayo; referencias rotas y contradicciones entre documentos.
- **Afecta a:** todos los documentos citados.
- **Estado:** aplicado.

### 12/10/2026 — Cronograma adelantado: la interfaz ya está hecha

- **Qué era:** la fase 1 incluía hacer la interfaz definitiva y las métricas (~5 semanas, hasta mediados de noviembre); iroh hasta Navidad; seguridad en enero; terminal hasta finales de febrero; fases 8–10 apretadas en mayo.
- **Qué es ahora:** la interfaz definitiva, con *placeholders* y datos simulados, ya está terminada. La fase 1 solo crea el agente y conecta las métricas reales (hasta principios de noviembre). Todo se adelanta unas 3 semanas: iroh hasta mediados de diciembre, beta entre mediados de diciembre y Navidad, seguridad de mediados de diciembre a principios de enero, terminal hasta mediados de febrero; las fases 9 y 10 recuperan 3 y 2 semanas. La Unidad 3 del plan de estudios deja la parte de interfaz y se centra en el agente de métricas.
- **Por qué:** el autor terminó la interfaz antes de lo previsto.
- **Afecta a:** `03` (sección 11), `04`, `07` (sección 5), plan de estudios (Unidades 2 y 3).
- **Estado:** aplicado en la documentación.

### 14/10/2026 — Terminal: de PTY ligado a la conexión a sesiones persistentes con tmux

- **Qué era:** el agente abría un PTY al conectarse el móvil y lo cerraba al desconectar («cierre limpio al desconectar», fase 4). Cerrar la app, limpiarla de recientes o perder la cobertura cortaba el comando en marcha.
- **Qué es ahora:** la sesión es del agente. La app solo pide «abre una terminal y ejecuta esto» y se engancha para ver la salida; la sesión es una sesión de **tmux**, también visible en una ventana de la terminal gráfica del PC. El comando sigue aunque la app se cierre, y al volver se recupera la salida.
- **Por qué:** una terminal que se corta al cerrar la app es peligrosa para tareas largas (por ejemplo, actualizar el sistema), y el criterio del proyecto es usarla **sin estar delante del PC**. Además, ver en el PC lo ocurrido al volver.
- **Decisiones tomadas:**
  1. **tmux** como mecanismo (menos código: aporta buffer y reenganche) frente a un cliente propio.
  2. **Cerrar la ventana en el PC termina la sesión**; cerrar la ventana en la app también (la cierra en el PC). `exit` basta; no hay comando `close`.
  3. **Sin caducidad por inactividad:** la sesión vive hasta que se cierre.
  4. **Una sola sesión al principio;** después, **varias pestañas** en la app, como las de un navegador (cada una, una terminal independiente con su sesión de tmux y su ventana en el PC).
  5. **Cliente propio sin tmux:** posibilidad a **muy largo plazo** para eliminar la dependencia.
  6. **Sin sesiones activas, terminal vacía con aviso:** la sesión no se crea al abrir la pantalla sino al primer toque o tecla, con un mensaje genérico que avisa de que eso abre una ventana en el PC; no hay pestaña principal y se pueden cerrar todas. *(Se pensó primero crearla con la primera orden y se cambió a la primera tecla el mismo día, para tener la shell real, Tab e historial desde el principio, a costa de abrir una ventana en el PC con la primera letra; el aviso y que el toque también dispare la creación se añadieron después.)*
  7. **`GET /terminales` solo devuelve las pestañas propias** que la app tenía abiertas al cerrarse, no cualquier sesión de tmux del PC.
- **Consecuencias:** `tmux` pasa a ser una dependencia del sistema en el PC, que `pipx` no instala (comprobación en la TUI, fase 5); sin tmux, la terminal queda ligada a la conexión con aviso. La API pasa de `/ws/terminal` a `/terminales` y `/ws/terminal/{id}`.
- **Nuevo documento:** `doc/agente/terminal-sesiones-tmux.md` (con la carpeta `doc/agente/`, para la documentación específica del agente).
- **Afecta a:** `01` (Módulo A y §8.1), `02` (nuevo 2.2.1 y §7.2), `03` (§A y API), `04` (fases 4 y 5), `06`, `07`, `ESTRUCTURA_FLUTTER.md`, `ui/XTERM_DART.md` y `CLAUDE.md`.
- **No verificado:** todo lo relativo a tmux (comandos, ganchos de cierre, versión mínima, licencia) y a cómo cada emulador ejecuta un comando.
- **Estado:** decidido y documentado; sin código. La app no cambia hasta que exista el agente.

### 15/10/2026 — Tercera auditoría: deduplicación de detalle técnico repetido

- **Qué se hizo:** nueva auditoría de solo lectura de los 8 documentos generales, `doc/agente/` y `doc/ui/` buscando contenido duplicado, contradicciones, cosas fuera de alcance no reflejadas en `06` y contenido desactualizado. Sin datos inventados; sin hallazgos de alcance ni de contenido desactualizado.
- **Duplicación eliminada:** el detalle técnico de iroh (versiones, glibc, arquitecturas soportadas), del `foregroundServiceType` de Android (`connectedDevice`/`dataSync`, permisos del manifiesto) y de `ACCESS_LOCAL_NETWORK` estaba explicado por extenso en varios documentos a la vez. Ahora cada uno tiene una única fuente y el resto remite a ella con una frase corta:
  - iroh → `02-necesidades-tecnologicas.md` §3.3 (antes repetido también en `01`, `03`, `04` y `05`);
  - `foregroundServiceType` → `02-necesidades-tecnologicas.md` §4.1 (antes repetido también en `01`, `03` y `04`);
  - `ACCESS_LOCAL_NETWORK` → `01-memoria-tecnica.md` §10 (antes repetido también en `02` y `03`).
- **Contradicción corregida:** el intervalo de *polling* de métricas en la beta decía "cada 1 s" en `01`/`04` pero "every 1–2 s" en `03`; se deja en "1 s" en los tres.
- **Nota añadida:** `03-system-context.md` §5c listaba las pantallas de energía, procesos, reglas de alerta, notificaciones, login y conexión dentro de un flujo de navegación fijo, sin indicar que su ubicación está pendiente de revisión (lo que sí decía `01-memoria-tecnica.md` §3). Se añadió la misma advertencia en `03`.
- **No se tocó `03-system-context.md` como resumen condensado para asistentes de IA:** se mantiene así porque el propio documento se declara una copia condensada intencional, con `01`/`02`/`04` como fuente de verdad si hay conflicto.
- **No se movió nada a `06-ideas-de-futuro.md`:** todo lo descartado del alcance ya estaba correctamente recogido allí (pestañas de terminal, temas de terminal, imágenes en el espacio compartido); no se encontraron ideas futuras sin reflejar.
- **Afecta a:** `01`, `02`, `03`, `04`, `05`.
- **Estado:** aplicado.

### 15/10/2026 — TUI del agente: librería confirmada y construcción adelantada a la fase 1

- **Qué era:** la fase 3 creaba una "TUI mínima con Textual" junto con la seguridad; la librería (Textual) era una elección tentativa sin comparar alternativas.
- **Qué es ahora:** se compararon Textual, urwid, prompt_toolkit y py_cui para una interfaz con botones y formularios; Textual es la mejor soportada (framework de widgets, MIT, mantenimiento activo en 2026) y se confirma. Además, la TUI se construye entera en la **fase 1** (interfaz definitiva), igual que se hizo con la interfaz de la app en la fase 0; las fases 3, 5, 7 y 9 pasan a **activar** contenido dentro de ella en vez de crear la TUI o parte de ella. (La estructura concreta de esa interfaz definitiva se revisó el mismo día; ver la entrada siguiente.)
- **Por qué:** mismo criterio que con la app — tener antes la interfaz completa (aunque inerte) ayuda a ver el conjunto y evita rehacer la TUI pieza a pieza en cada fase.
- **Afecta a:** `04-plan-de-fases.md` (tabla de decisiones, fases 1 y 3), `07-resumen-decisiones-y-contexto.md` (§3.1, §3.2, cronograma).
- **Estado:** aplicado en la documentación; sin código todavía.

### 15/10/2026 — Estructura de la TUI: de botones por fase a cuatro secciones fijas

- **Qué era:** la entrada anterior describía la TUI como "todos los botones de todas las fases, deshabilitados hasta implementarse", sin una estructura visual concreta.
- **Qué es ahora:** alex aportó `DESIGN.md` y una implementación de referencia (`main.py`) con una estructura concreta: banner ASCII a ancho completo, área de datos (vacía por defecto, con marco redondeado) y una barra de botones fijos abajo. Se adopta esa estructura y ese comportamiento (incluidos los colores ANSI de la terminal, `ansi_color=True`, en vez de la paleta fija de Textual), pero **no** las tablas de ejemplo de `main.py` (`dispositivos`, `macros`, `historial`, `ajustes`): esas eran solo ilustrativas. Los datos reales son los del esquema ya documentado (`usuario`, `sesion`, `grupo`, `accion_rapida`, `ejecucion`...). Resultado, cuatro botones:
  - **Emparejamiento:** QR y dispositivo (desde `sesion`); también la seguridad de la fase 3 (configuración inicial, contraseña, cerrar sesiones) y el servicio de la fase 5 (instalar, quitar, estado);
  - **Historial:** acciones rápidas (`ejecucion`, fase 7) y comandos de terminal;
  - **Base de datos:** navegador en vivo de las tablas de `schema.sql`, con las exportaciones de la fase 7;
  - **Notas:** CRUD de notas de la fase 9.
- **Decisión nueva — historial de comandos de terminal:** el agente no puede ver lo que se escribe directamente en la ventana del PC (solo lo que la app manda por el WebSocket de la terminal), así que una captura completa necesitaría integración de shell (OSC 133), ya descartada del TFG (`06-ideas-de-futuro.md` §5). Se opta por registrar solo lo que llega desde la app, en un archivo de log aparte (`~/.cache/.../ISO-8601<TAB>comando`, sin tabla en SQLite para no duplicar, sin límite de tamaño por ahora); la pantalla Historial combina ese archivo con `ejecucion` solo al mostrarlos.
- **Por qué:** tener una referencia visual y de comportamiento concreta (en vez de solo una lista de botones) evita ambigüedad al construir la TUI; el esquema de datos se mantiene porque ya está documentado, verificado y es el que usan el resto de fases.
- **Afecta a:** `04-plan-de-fases.md` (decisiones, fase 1, fase 3, fase 5, fase 9), `07-resumen-decisiones-y-contexto.md` (§3.1, §3.2, cronograma), `01-memoria-tecnica.md` (§6, §8.1).
- **Estado:** aplicado en la documentación; sin código todavía.

### 15/10/2026 — Nuevo documento: especificación de la TUI en doc/agente/

- **Qué se hizo:** se copió el `DESIGN.md` aportado por alex a `doc/agente/DESIGN.md` y se amplió con lo que el boceto original no cubría: las subpestañas de Emparejamiento (Dispositivo, Seguridad, Servicio), la sección Notas, el esquema de datos real (en vez de las tablas de ejemplo del boceto) y el diseño del historial de comandos de terminal (archivo de log en `~/.cache`, sin tabla SQLite).
- **Por qué:** mantener un único documento de referencia para la TUI, ya en el repo, en vez de dejarlo repartido entre una subida temporal y los documentos generales.
- **Afecta a:** `doc/agente/DESIGN.md` (nuevo), `doc/agente/README.md` (índice).
- **Estado:** aplicado.

### 15/10/2026 — Inicio, tema y terminal: cinco pendientes resueltos; `ui-final/DESIGN.md` como referencia única

- **Qué se hizo:**
  1. **Validar nombre de macro:** obligatorio, máximo 50 caracteres, sin repetirse (sin distinguir mayúsculas) con otra macro o carpeta del nivel superior de la cuadrícula. Mensaje de error bajo el campo del diálogo «Nueva macro».
  2. **Selector de icono de macro:** fila de 4 opciones (volumen, candado, luna, rayo) en el mismo diálogo; por defecto, rayo.
  3. **Contraste del acento en tema oscuro:** se calculó el contraste real (fórmula WCAG) de los 6 colores contra el fondo oscuro `#111316`; todos estaban entre 1,96 y 3,59. Se aclaró la luminosidad de cada uno (mismo tono y saturación) hasta un contraste de ~4,5:1; nueva tabla `kAccentColorsDark` en `app_tokens.dart`, aplicada solo en tema oscuro.
  4. **Terminal, fuente del sistema:** se quita `fontFamily: 'JetBrainsMono'` de `TerminalStyle`; sin ese parámetro, `xterm.dart` usa su valor por defecto, `'monospace'`, que en Android resuelve a la fuente del dispositivo (verificado en el código fuente del paquete). Se descarta también la Nerd Font. **Conflicto documentado:** la ventana del PC y la app mostrarán la misma sesión, pero no el mismo aspecto, ya que cada lado usa su propia fuente.
  5. **Parpadeo del cursor:** se descarta implementarlo; no compensa el esfuerzo de montarlo por fuera de `xterm.dart`.
  6. **`doc/ui/ui-final/DESIGN.md`** (nuevo): referencia única y actualizada de las 6 pantallas, escrita leyendo el código real, no copiando `ui-v1`/`ui-v2`. Esos dos documentos pasan a histórico, con un aviso al principio que remite a `ui-final`.
- **Por qué:** los puntos 1–5 cerraban huecos ya anotados en «Pendiente» (más abajo); el 6 evita que la documentación de interfaz quede repartida entre tres versiones sin un único sitio fiable.
- **Afecta a:** `new_macro_dialog.dart`, `home_viewmodel.dart`, `app_tokens.dart`, `app_theme.dart`, `terminal_view.dart`; `doc/ui/XTERM_DART.md`, `doc/ui/ui-v1/DESIGN.md`, `doc/ui/ui-v2/DESIGN.md`, `doc/ui/ui-final/DESIGN.md` (nuevo), `01-memoria-tecnica.md`.
- **Estado:** aplicado.

### 19/10/2026 — Inicio: papelera sobre carpeta; Ajustes: persistencia local y fuente de la vista previa

- **Qué era:**
  1. Arrastrar una carpeta a la papelera la borraba siempre con todo su contenido, sin preguntar (hueco anotado el 12/10/2026 y en «Pendiente»).
  2. La vista previa de la terminal en Ajustes seguía en JetBrains Mono, distinta de la fuente real de la terminal (del sistema, decisión del 15/10/2026).
  3. Los ajustes vivían solo en memoria (`SettingsViewModel`): se perdían al cerrar la app, uno de los tres fallos señalados por el autor tras probar el APK (los otros dos, gesto del drawer y FAB tapado por la barra del sistema, ya se habían corregido antes).
- **Qué es ahora:**
  1. Si la carpeta soltada en la papelera tiene macros, se muestra un diálogo «¿Qué hacer con «nombre»?» con tres opciones: mover los macros a Sin grupo, cancelar o borrar carpeta y contenido. Una carpeta vacía se sigue borrando directamente.
  2. Se quita `fontFamily: 'JetBrainsMono'` de la vista previa; usa la misma fuente por defecto que la terminal real.
  3. Se añade `shared_preferences` y una `SettingsRepository` (interfaz) con dos implementaciones: `SharedPreferencesSettingsRepository` (real, registrada en `main.dart`) e `InMemorySettingsRepository` (para tests). `SettingsViewModel` carga de forma asíncrona al construirse y guarda tras cada cambio. Mientras carga, la app muestra una pantalla en blanco (placeholder temporal, sin diseñar todavía).
- **Por qué:** cerraba tres huecos ya documentados como pendientes.
- **Afecta a:** código: `home_viewmodel.dart`, `home_view.dart`, `folder_trash_dialog.dart` (nuevo), `terminal_preview.dart`, `settings_repository.dart` (nuevo), `data/fake/in_memory_settings_repository.dart` (nuevo), `data/local/shared_preferences_settings_repository.dart` (nuevo), `settings_viewmodel.dart`, `main.dart`, `app.dart`. Documentación: `ui-final/DESIGN.md` (§2, §3, §7, §8, §9), este historial.
- **Estado:** aplicado en código; pantalla de carga aún placeholder (blanco liso, sin diseño final).

### 19/10/2026 — Terminal: estado vacío y creación de sesión al primer toque o tecla

- **Qué era:** la pantalla mostraba el banner y el prompt de `FakeTerminalRepository` desde que se abría, sin terminal vacía ni disparador; no había forma de volver a ese estado.
- **Qué es ahora:** aplicado el diseño de `doc/agente/terminal-sesiones-tmux.md` §4, usando el texto y el criterio de disparador que ya constaban allí como decisión (no una incógnita abierta):
  1. Sin sesión, la pantalla muestra el aviso **«Toca para abrir una terminal en tu PC»**.
  2. Dispara la creación el primer toque sobre esa zona, o la primera tecla que no sea un modificador solo (CTRL, ALT, SHIFT, META); el botón de ocultar teclado no cuenta por no estar disponible en este estado.
  3. Mientras se crea la sesión (en la maqueta, un retraso simulado de 600 ms, ya que no hay agente que medir), se superpone un indicador con el texto **«Abriendo terminal…»**; la terminal real ya está montada y enfocada por debajo, así que lo que se teclee con un teclado físico se guarda y se envía en orden al quedar lista.
  4. Al quedar lista, aparece el prompt real (shell simulado, con historial y Tab).
  5. Escribir `exit` o Ctrl+D con la línea vacía cierra la sesión y vuelve al aviso inicial, con una `Terminal` nueva (según el ciclo de vida de `terminal-sesiones-tmux.md` §4).
- **Simplificaciones de esta maqueta, sin agente real:**
  - El disparador por tecla física solo abre la sesión; no se reconstruye qué carácter era (un `KeyEvent` crudo no equivale de forma fiable a texto de IME). En un móvil sin teclado físico, el toque es el disparador real.
  - Durante la creación, el teclado físico sí queda en cola; el teclado en pantalla depende de que el sistema conecte el campo de texto en ese intervalo exacto, sin verificar en el emulador.
- **Por qué:** cerraba el pendiente de UI de la terminal anotado en «Pendiente» (más abajo) y en `ui-final/DESIGN.md` §9, con los valores que ya estaban documentados.
- **Afecta a:** `terminal_repository.dart`, `fake_terminal_repository.dart`, `terminal_viewmodel.dart`, `terminal_view.dart`, `test/widget_test.dart`. Documentación: `ui-final/DESIGN.md` (§5, §9), este historial.
- **Estado:** aplicado en código, sin verificación visual en emulador.

### 19/10/2026 — Métricas: repositorio HTTP real; Ajustes: dirección del agente y modo de conexión

- **Qué era:** la pantalla de Métricas solo leía `FakeMetricsRepository` (datos inventados); no existía ningún sitio en la app para indicar cómo llegar al agente.
- **Qué es ahora:**
  1. **`HttpMetricsRepository`** (nuevo, `data/http/`): pide `GET http://<dirección>/metrics` al agente real (ver `feature/agent`, commit `8cf02c2`) y traduce su JSON (`cpu_percent`, `cpu_temp_c`, `ram_used_gb`, `ram_total_gb`, `partitions`) a los modelos `MetricSample`/`MachineInfo`/`Partition` que ya usaba la app. Registrado en `main.dart` en vez de `FakeMetricsRepository` (que se queda solo para los tests, mismo patrón que el resto de repositorios).
  2. **Particiones:** se leen de nuevo en cada apertura de la app (`loadInfo()`, una vez al arrancar), no en cada segundo junto con las gráficas — decisión tomada porque nadie va a llenar varios GB de disco en los segundos que dura una sesión de la app.
  3. **Temperatura sin sensor:** `MetricSample.tempC` pasa a ser anulable; si el agente devuelve `cpu_temp_c: null` (sin sensor `k10temp`/`coretemp`/`cpu_thermal`/`zenpower` reconocido), la tarjeta de temperatura se sustituye por un aviso: **"No se ha podido mostrar la temperatura"**.
  4. **Ajustes → Dispositivo**, encima del botón Emparejar/Desemparejar: selector **Local / iroh** (`AppSegmented`, no un desplegable nativo — la app no usa ninguno en ningún otro sitio) y un campo de texto con botón «Guardar»: en modo Local, la dirección `host:puerto` (por defecto `127.0.0.1:8443`, validada con una expresión regular simple); en modo iroh, el identificador a mano (sin conexión real todavía, solo se guarda para cuando exista el túnel de la fase 2). Ambos valores persisten a la vez en `SettingsRepository`, junto con el modo activo, para no perder el otro al cambiar de uno a otro.
  5. **`main.dart`** pasa a ser `async`: antes de `runApp`, carga los ajustes guardados para tener ya la dirección real al construir `HttpMetricsRepository`. Cambiar la dirección se aplica la próxima vez que se abre la app, no en caliente (misma simplificación que las particiones).
- **Por qué:** es el trabajo de app de la fase 1 (`04-plan-de-fases.md`): repositorio real de métricas, pantalla de dirección del agente y selector local/iroh adelantado para no rehacer esa pantalla en la fase 2.
- **Nota (19/10/2026):** el punto 5 quedó desfasado el mismo día: ver la entrada «19/10/2026 — Interfaz: conexión con el agente, timeout, reintento y dirección en caliente», que sustituye ese comportamiento por la dirección en caliente.
- **Sin verificar en esta sesión:** la prueba completa por USB con `adb reverse` (necesita el agente real arrancado y un móvil o emulador conectado) y la TUI del agente (trabajo en curso en `feature/agent`, otra rama).
- **Afecta a:** `metrics.dart` (modelo), `metrics_view.dart`, `settings_repository.dart`, `settings_viewmodel.dart`, `shared_preferences_settings_repository.dart`, `connection_fields.dart` (nuevo), `http_metrics_repository.dart` (nuevo), `main.dart`, `pubspec.yaml` (dependencia `http`). Documentación: `ui-final/DESIGN.md` (§4, §7, §8, §9), este historial.
- **Estado:** aplicado en código, verificado con `flutter analyze`/`flutter test` y un test de `HttpMetricsRepository` contra un cliente HTTP simulado (`http/testing.dart`); sin verificación en dispositivo real ni contra el agente en marcha.

### 19/10/2026 — Terminal: pestañas; Arranque: pantalla de carga con spinner y texto

- **Qué era:** la pantalla de Terminal solo admitía una sesión; cerrar la app a segundo plano y el arranque mostraban una pantalla en blanco liso (placeholder temporal).
- **Qué es ahora:**
  1. **Pestañas de Terminal**, aplicando `terminal-sesiones-tmux.md` §10 con las preguntas abiertas del documento resueltas así: título «Terminal N» sin renombrar, sin confirmación al tocar «+» (es una acción explícita), **confirmación obligatoria al cerrar una pestaña con «×»** (decisión de alex, igual se sepa o no si hay algo en marcha, porque la maqueta no puede saberlo), límite de 6 con el mismo aviso de "no caben más" que usa Inicio, sin indicador de actividad ni recordar la pestaña activa (quedan fuera de esta versión), sin restaurar pestañas al reabrir la app (ninguna sesión sobrevive a cerrarla en la maqueta).
  2. `TerminalTabsViewModel` (nuevo) gestiona la lista de pestañas, cada una un `TerminalViewModel` con su propio `Terminal` y su propio `TerminalRepository` (ahora se inyecta una fábrica, `TerminalRepository Function()`, en vez de una instancia compartida). Escribir `exit`/Ctrl+D en una pestaña la cierra sola, sin el diálogo de confirmación (acción ya explícita).
  3. Pantalla de carga del arranque: `CircularProgressIndicator` (color de acento) + «Linux System Companion», sobre el fondo del tema, en vez del blanco liso. Sin logo: el proyecto no tiene ningún asset de imagen declarado.
- **Por qué:** cerraba los dos últimos pendientes de interfaz del plan original (pestañas de Terminal y diseño del placeholder de arranque); las respuestas a las preguntas abiertas de pestañas las dio alex directamente.
- **Sin verificar en esta sesión:** no se pudo probar visualmente en el emulador (acceso denegado al pedir el permiso de pantalla).
- **Afecta a:** `terminal_repository.dart`, `fake_terminal_repository.dart` (sin cambios de contrato, solo de quién la instancia), `terminal_tabs_viewmodel.dart` (nuevo), `terminal_viewmodel.dart`, `terminal_view.dart`, `terminal_tabs_bar.dart` (nuevo), `close_tab_dialog.dart` (nuevo), `main.dart`, `app.dart`, `test/widget_test.dart`. Documentación: `ui-final/DESIGN.md` (§5, §7, §9), este historial.
- **Estado:** aplicado en código, verificado con `flutter analyze`/`flutter test`; sin verificación visual.
- **Nota (20/10/2026):** `close_tab_dialog.dart` se sustituyó por el diálogo único `confirm_card.dart`; ver la entrada «20/10/2026 — Interfaz: limpieza — diálogos, toasts y botón flotante unificados».

### 19/10/2026 — Fase 1: el objetivo de métricas seguía pidiendo el endpoint completo

- **Qué era:** `04-plan-de-fases.md` (fase 1, objetivo del agente) pedía un endpoint con CPU por núcleo, swap, carga y tiempo encendido — la lista completa de psutil. El "Terminada cuando" de la fase decía "tres secciones" de la TUI.
- **Qué es ahora:** el endpoint real que se construyó solo expone lo que la app consume hoy (CPU total, RAM, discos, temperatura); núcleos/swap/carga/uptime quedan como ampliación opcional, no requisito. "Terminada cuando" pasa a "cuatro secciones" (se había añadido Notas y no se actualizó esa frase).
- **Por qué:** esta reducción de alcance ya se había decidido y aplicado al propio endpoint; solo faltaba corregir el documento, que se quedó con la redacción antigua.
- **Afecta a:** `04-plan-de-fases.md` (fase 1).
- **Estado:** aplicado en `main` y `feature/agent`. **Pendiente en `feature/interfaz`:** tiene su propia copia de este archivo, sin esta corrección (no se tocó para no interferir con esa sesión).

### 19/10/2026 — Interfaz: conexión con el agente, timeout, reintento y dirección en caliente

- **Qué era:** `HttpMetricsRepository` pedía las métricas al agente sin timeout ni distinguir tipos de error; sin aviso en pantalla si no respondía; el sondeo seguía activo con la pantalla de Métricas en segundo plano o fuera de ella; cambiar la dirección en Ajustes no se aplicaba hasta reabrir la app.
- **Qué es ahora:**
  1. Timeout y errores (sin conexión, tiempo agotado, respuesta inválida) distinguidos con mensajes claros en `HttpMetricsRepository`.
  2. Aviso «No se puede conectar con el agente» con botón «Reintentar» en la pantalla de Métricas.
  3. El sondeo se pausa al salir de la pantalla de Métricas o con la app en segundo plano, y se reanuda al volver.
  4. `HttpMetricsRepository` recibe `() => settings.agentAddress` y lee la dirección del `SettingsViewModel` en cada petición: el cambio de dirección se aplica sin reiniciar la app (sustituye lo descrito en la entrada del 19/10/2026 «Métricas: repositorio HTTP real…», punto 5, ver nota en esa entrada).
- **Por qué:** cerraba los huecos de robustez de la conexión con el agente que quedaron abiertos al introducir `HttpMetricsRepository` el mismo día.
- **Afecta a:** `http_metrics_repository.dart`, `metrics_repository.dart`, `metrics_viewmodel.dart`, `metrics_view.dart`, `main.dart`, `test/http_metrics_repository_test.dart`.
- **Estado:** aplicado en código; sin verificación contra el agente real (prueba por USB con `adb reverse` pendiente, ver «Pendiente»).

### 19-20/10/2026 — Interfaz: identificador de Android, nombre visible y enlaces externos

- **Qué era:** la app seguía con el `applicationId`/`namespace` de la plantilla (`com.example.tfg`), sin nombre visible propio, sin declarar `<queries>` para abrir enlaces externos y sin el permiso `INTERNET` en el manifest de release.
- **Qué es ahora:**
  1. `applicationId` y `namespace` pasan a `io.github.alexxio070.companion`.
  2. Nombre visible: «Linux System Companion».
  3. Se declara `<queries>` (intent VIEW + esquema `https`) para que `url_launcher` pueda abrir enlaces en Android 11 y posteriores.
  4. Se añade el permiso `INTERNET` al manifest de release (ya estaba en el de debug).
- **Por qué:** identidad propia de la app, necesaria antes de publicar el APK, y requisito de Android 11+ para que los enlaces de Notas se abran desde la release.
- **Afecta a:** `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml`.
- **Estado:** aplicado en código.

### 20/10/2026 — Interfaz: limpieza — diálogos, toasts y botón flotante unificados

- **Qué era:** cada pantalla tenía su propio diálogo de confirmación (incluido `close_tab_dialog.dart` de la entrada del 19/10/2026 «Terminal: pestañas…», ver nota en esa entrada), su propio *toast* y su propio botón flotante, con pequeñas diferencias de estilo entre ellos.
- **Qué es ahora:**
  1. **`confirm_card.dart`** (nuevo): único diálogo de confirmación, sustituye a `confirm_dialog.dart` y a `close_tab_dialog.dart`.
  2. **`app_toast.dart`** (nuevo): único *toast*, sustituye a `run_toast.dart` y usos sueltos.
  3. **`app_fab.dart`** (nuevo): único botón flotante.
  4. Tokens de color compartidos movidos a `app_tokens.dart`; constantes con nombre para valores que estaban repetidos como literales.
  5. Archivos largos divididos (`macro_grid.dart`, `disk_card.dart`).
- **Por qué:** quitar duplicación de widgets casi iguales entre pantallas y dejar un único sitio para cambiar el estilo de confirmaciones, avisos y acción flotante.
- **Afecta a:** `app_tokens.dart`, `confirm_card.dart` (nuevo), `app_toast.dart` (nuevo), `app_fab.dart` (nuevo), y las pantallas que los usan (Inicio, Métricas, Notas, Ajustes, Terminal, `shell_view.dart`/`app_drawer.dart`).
- **Estado:** aplicado en código.

### 19/10/2026 — Agente: métricas en GB decimales y sin particiones duplicadas

- **Qué era:** el agente enviaba los tamaños en GiB (potencias de 1024), mientras la app esperaba GB decimales (potencias de 1000), lo que producía una discrepancia entre los valores mostrados; además, la lista de particiones incluía snaps, montajes *loop* y el mismo dispositivo físico repetido por cada punto de montaje.
- **Qué es ahora:** los tamaños se calculan con `1000**3`; se descartan snaps, montajes *loop* y particiones duplicadas por dispositivo, quedándose con una por disco físico.
- **Por qué:** corregir la discrepancia GB/GiB con la app y evitar una lista de particiones con ruido que no aporta al usuario.
- **Afecta a:** `metrics_repository.py`, `metrics_service.py`.
- **Estado:** aplicado en código. Commits: `8b639a5`, `1f55ab0`, `41a9a6a`, `a086eb6`.

### 19-20/10/2026 — Agente: comando `companion` instalable y resaltado de sección activa en la TUI

- **Qué era:** la TUI no se podía abrir como comando instalado por `pipx`; los botones de sección y las subpestañas de Emparejamiento no indicaban cuál estaba activa.
- **Qué es ahora:**
  1. Comando `companion` instalable que abre la TUI.
  2. Resaltado de la sección y de la subpestaña activas: primero con una clase CSS que un temporizador de la propia Textual borraba sola; luego con `reverse` y la paleta propia de Textual en vez de `ansi_color` (que no se podía combinar de forma fiable con `reverse`); bordes consistentes en los botones y pie de página transparente.
  3. Se quita el identificador `#home` (sin uso).
- **Por qué:** tener un comando real en vez de ejecutar el módulo a mano, y que la TUI indique en qué sección y subpestaña está el usuario.
- **Afecta a:** `tui/app.py`, `tui/screens/main_screen.py`, `tui/widgets/pairing_section.py`, `pyproject.toml`, `tests/test_tui.py`, `doc/agente/DESIGN.md`.
- **Estado:** aplicado en código. Commits: `13d721f`, `360daf6`, `fc086b0`, `3a17b11`, `fd291ab`, `ecffaa5`, `381dfa9`.

### 19/10/2026 — Agente: versiones mínimas, `pydantic` y `httpx2` en los tests

- **Qué era:** `pyproject.toml` no fijaba versiones mínimas de las dependencias, no declaraba `pydantic` como dependencia directa (llegaba de forma transitiva) y los tests usaban `httpx`, que Starlette 1.9 empezó a marcar como obsoleto.
- **Qué es ahora:** versiones mínimas fijadas, `pydantic` declarado como dependencia directa, `httpx2` en lugar de `httpx` para los tests.
- **Por qué:** evitar romper por una versión mínima no probada, declarar explícitamente una dependencia ya en uso, y quitar el aviso de obsolescencia de Starlette.
- **Afecta a:** `pyproject.toml`.
- **Estado:** aplicado en código. Commits: `e0de0f2`, `7d518ea`.

---

## Pendiente

Cosas abiertas tras la revisión del 12/10/2026. Ya no hay incoherencias de redacción conocidas entre la documentación y la implementación; lo que queda son huecos de la interfaz o decisiones de plan:

| Área | Qué falta |
|---|---|
| Fase 7 | Definir el acceso a la ficha de acción y a su historial, y los valores por defecto de la creación rápida |
| Terminal (fase 4) | Prototipos: cierre al cerrar la ventana del PC, historial sin duplicados, ventana en kitty y Konsole, versión mínima de tmux y supervivencia al reinicio del agente |
| Terminal (fase 4) | Decidir límite de sesiones, tamaño del historial y *keepalive*; completar la tabla «emulador → cómo lanzarlo» |
| Agente | Documentar la API, el esquema, la seguridad y la instalación en `doc/agente/` |
| Terminal (agente) | Medir la latencia real de crear sesión + ventana del PC + enganche (estimada en 200 ms–1 s LAN, sin verificar); hoy la maqueta simula 600 ms fijos |
| Fase 1 | Probar `HttpMetricsRepository` por USB con `adb reverse` contra el agente real (hoy solo probado con un cliente HTTP simulado) |
| Terminal (UI) | Verificar en el emulador que el teclado en pantalla no pierde pulsaciones durante el retraso de creación de la sesión |
| Metodología | Mantener este historial al día: anotar aquí cada cambio de diseño que se aparte de lo documentado |
