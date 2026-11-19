# Historial de cambios y decisiones

Este documento recoge, por orden cronológico, las cosas que **originalmente eran de una forma y acabaron siendo de otra**: qué se pensó, qué se hizo al final y por qué. Su objetivo es mantener el rastro de esos cambios **fuera** de los documentos 01–07, para que estos describan solo el estado actual del proyecto y no se saturen de «antes decía…».

- **Qué va aquí:** cambios de diseño, de tecnología o de alcance; ideas descartadas y su motivo; decisiones tomadas durante la implementación que se apartan de lo documentado.
- **Qué no va aquí:** el estado actual (eso va en 01–07) ni el registro de decisiones de diseño general (eso es `07-resumen-decisiones-y-contexto.md`).
- **Formato de cada entrada:** fecha, título corto, qué era, qué es ahora, por qué, qué documentos o código afecta y estado (`aplicado`, `pendiente de aplicar` o `pendiente de decidir`).
- **Convención:** las entradas nuevas se añaden al final de su sección. Una entrada no se borra: si algo vuelve a cambiar, se añade otra.

## Índice

*Orden cronológico (no se reordena ni se reescribe). La columna «Área» es solo para localizar un tema rápido.*

| Fecha | Área | Cambio | Estado |
|---|---|---|---|
| 12/10/2026 | Interfaz | Notas: de un campo de texto único a lista con CRUD, con tipo deducido y enlaces pulsables | Aplicado |
| 12/10/2026 | Interfaz | Pantalla «Opciones» renombrada a «Ajustes» | Aplicado |
| 12/10/2026 | Interfaz | Terminal: de widget propio a `xterm.dart` | Aplicado |
| 12/10/2026 | Interfaz | Gráficas: de `fl_chart` a `CustomPainter` | Aplicado |
| 12/10/2026 | Documentación | Documentación de interfaz: `doc/UI` pasa a `doc/ui/ui-v1` y `ui-v2` | Aplicado |
| 12/10/2026 | Interfaz | Temperatura de CPU: color del valor | Aplicado |
| 12/10/2026 | Interfaz | Acciones rápidas: de lista con buscador a cuadrícula con carpetas | Aplicado en la memoria; ajustes de UI pendientes |
| 12/10/2026 | Documentación | Notas: el tipo (texto/enlace) lo deduce el agente | Aplicado en la documentación |
| 12/10/2026 | Documentación | Carpeta del cliente: `app/` pasa a `App-movil/` | Aplicado |
| 12/10/2026 | Documentación | Revisión de coherencia entre documentación e implementación | Aplicado |
| 12/10/2026 | Agente | Herramienta del PC: de CLI con Typer a TUI con botones (Textual) | Aplicado en la documentación |
| 12/10/2026 | Agente | Registro del usuario: de CLI o código de un solo uso a QR en la TUI y cuenta creada en la app | Aplicado en la documentación |
| 12/10/2026 | Agente | Exportación de datos y de estructura de la BD desde la TUI | Aplicado en la documentación |
| 12/10/2026 | Planificación | Replanificación: interfaz primero y beta sin login | Aplicado en la documentación |
| 12/10/2026 | Documentación | Auditoría de la documentación frente a fuentes oficiales | Aplicado |
| 12/10/2026 | Planificación | Cronograma adelantado: la interfaz definitiva ya está hecha | Aplicado en la documentación |
| 14/10/2026 | Agente | Terminal: de PTY ligado a la conexión a sesiones persistentes con tmux | Decidido y documentado; implementación en la fase 4 |
| 15/10/2026 | Interfaz | Inicio: validación de nombre de macro y selector de icono | Aplicado en código |
| 15/10/2026 | Interfaz | Tema oscuro: color de acento aclarado para contraste suficiente | Aplicado en código |
| 15/10/2026 | Interfaz | Terminal: fuente del sistema en vez de Nerd Font; se descarta el parpadeo del cursor | Aplicado en código y documentación |
| 15/10/2026 | Documentación | Documentación de interfaz: `doc/ui/ui-final/DESIGN.md` como referencia única del estado actual | Aplicado |
| 15/10/2026 | Documentación | Tercera auditoría: deduplicación de detalle técnico repetido | Aplicado |
| 15/10/2026 | Agente | TUI del agente: librería confirmada y construcción adelantada a la fase 1 | Aplicado en la documentación |
| 15/10/2026 | Agente | Estructura de la TUI: de botones por fase a cuatro secciones fijas | Aplicado en la documentación |
| 15/10/2026 | Documentación | Nuevo documento: especificación de la TUI en doc/agente/ | Aplicado |
| 19/10/2026 | Interfaz | Inicio: papelera sobre carpeta; Ajustes: persistencia local y fuente de la vista previa | Aplicado |
| 19/10/2026 | Interfaz | Terminal: estado vacío y creación de sesión al primer toque o tecla | Aplicado en código (maqueta sin agente) |
| 19/10/2026 | Interfaz | Métricas: repositorio HTTP real contra el agente; Ajustes: dirección del agente y modo de conexión (local/iroh) | Aplicado en la app; agente y prueba por USB en marcha por separado |
| 19/10/2026 | Interfaz | Terminal: pestañas; Arranque: pantalla de carga con spinner y texto | Aplicado en código |
| 19/10/2026 | Planificación | Fase 1: el objetivo de métricas seguía pidiendo el endpoint completo | Aplicado |
| 19/10/2026 | Interfaz | Interfaz: conexión con el agente, timeout, reintento y dirección en caliente | Aplicado en código |
| 19-20/10/2026 | Interfaz | Interfaz: identificador de Android, nombre visible y enlaces externos | Aplicado en código |
| 20/10/2026 | Interfaz | Interfaz: limpieza — diálogos, toasts y botón flotante unificados | Aplicado en código |
| 19/10/2026 | Agente | Agente: métricas en GB decimales y sin particiones duplicadas | Aplicado en código |
| 19-20/10/2026 | Agente | Agente: comando `companion` instalable y resaltado de sección activa en la TUI | Aplicado en código |
| 19/10/2026 | Agente | Agente: versiones mínimas, `pydantic` y `httpx2` en los tests | Aplicado en código |
| 21/10/2026 | Planificación | Gestión de procesos descartada: la cubre la terminal | Aplicado en la documentación |
| 21/10/2026 | Planificación | Multi-dispositivo: sale de la documentación general y queda solo como idea futura | Aplicado en la documentación |
| 21/10/2026 | Interfaz | Procesos: se recupera como sección propia de la app, con búsqueda y congelar | Aplicado en la documentación |
| 22/10/2026 | Repositorio | Etiquetas de versión permitidas solo para las releases del APK | Aplicado en la documentación |
| 03/11/2026 | Repositorio | El proyecto pasa a llamarse Sysmote (app, agente, comando, paquete y documentación) | Aplicado en la documentación; el código está en las ramas feature |
| 12/11/2026 | Plan | Iroh probado en una red restrictiva real: la duda de la red del centro queda cerrada | Aplicado en la documentación |
| 12/11/2026 | Interfaz | `shared_preferences` 2.5.x no guardaba nada en dispositivo real (`NoSuchMethodError`); fijada una pareja de versiones anterior | Aplicado en código |
| 12/11/2026 | Plan | Fase 2 (iroh) cerrada; el acceso desde Flutter pasa a `iroh_flutter` y se actualizan 01, 02, 04 y 07 | Aplicado en la documentación |
| 13/11/2026 | Interfaz | Métricas avisa de la conexión perdida con datos ya cargados, de la carga y de la ausencia de particiones; los repositorios HTTP e iroh comparten una clase base | Aplicado |
| 14/11/2026 | Plan | La red del centro vuelve a ser una duda abierta: la red restrictiva probada no era la del centro | Aplicado en la documentación |
| 16/11/2026 | Plan | Prueba 5 de la matriz de iroh completada: el identificador sobrevive al reinicio del PC | Aplicado en la documentación |
| 16/11/2026 | Interfaz / Agente | Un solo intento de conexión iroh a la vez (el intento nativo no se cancela) y test de fugas de tareas del túnel | Aplicado en código y en la documentación |
| 16/11/2026 | Interfaz / Agente | Blindaje de iroh: identificador cambiado en caliente y validado, un solo refresco de Métricas, clave secreta con `0600`; el endurecimiento del túnel pasa a la fase 3 | Aplicado en código y en la documentación |
| 18/11/2026 | Agente | Túnel iroh endurecido (límites de conexiones y *streams*, inactividad, excepciones inesperadas) y puerto HTTP interno de referencia | Aplicado en código y en la documentación |
| 18/11/2026 | Agente / Interfaz | Limpieza de la parte de iroh: fuera `iroh_poc.py`, clave secreta con función pública, repositorio de métricas iroh con la conexión compartida y tests de la conexión aparte | Aplicado en código y en la documentación |
| 19/11/2026 | Plan / Agente / Interfaz | Auditorías de simplificación y legibilidad del agente y de la interfaz y revisión de la documentación general frente al código: `07` sobre la creación de la cuenta y el QR, tabla de errores del contrato, README y `CONTRIBUTING.md` | Aplicado en código y en la documentación |
| 19/11/2026 | Agente | `schema.sql` pasa a `agent/sysmote/` y se incluye en el paquete, para que el agente funcione instalado con `pip` o `pipx` | Aplicado en código y en la documentación |
| 19/11/2026 | Agente / Interfaz / Plan | Auditoría complementaria y sus correcciones: login con tiempo igualado y una sola cuenta a nivel de base de datos, `AppTopBar` a `core/`, formato Dart a 100 columnas, comentarios que faltaban, captura de la TUI, y textos de TLS, uvicorn y bloqueo por intentos | Aplicado en código y en la documentación |
| 19/11/2026 | Agente / Plan | El agente se prepara para publicarse en PyPI con el nombre `sysmote`: metadatos del autor, README del paquete y copia de la licencia | Aplicado en código y en la documentación; publicado en PyPI el 19/11/2026 (ver la entrada siguiente) |
| 19/11/2026 | Agente | Versión del esquema de la base de datos y migraciones, para poder actualizar el agente sin romper las bases de los usuarios | Aplicado en código y en la documentación |
| 19/11/2026 | Agente / Plan | Publicación del agente en PyPI con un workflow de GitHub Actions, sin guardar ningún token | Aplicado; `sysmote 0.1.0` publicado |
| 19/11/2026 | Agente | Cambiar la contraseña desde la TUI también levanta el bloqueo por intentos fallidos | Aplicado en código y en la documentación |
| 19/11/2026 | Interfaz | Login: aviso cuando falta un campo y nombre del dispositivo opcional, propuesto a partir del modelo del móvil | Aplicado en código y en la documentación |
| 19/11/2026 | Plan / Documentación | Primera prueba en un móvil físico: red local e iroh; se actualiza lo que decía «sin probar» | Aplicado en la documentación |
| 19/11/2026 | Plan | Fase 3 (seguridad) cerrada; el USB con `adb reverse` pasa a obsoleto como método de prueba | Aplicado en la documentación |
| 19/11/2026 | Plan / Agente / Interfaz | Decisiones abiertas de la auditoría: nombres de documentos en kebab-case, `allowBackup` desactivado, `uv.lock` y formateador de Python | Aplicado |
| 19/11/2026 | Interfaz / Agente | Pantalla de bienvenida en el primer inicio y caducidad de la sesión a los 7 días desde el login, con la tabla `sesion` como historial | Diseño aprobado y documentado; pendiente de implementar |

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
- **Estado:** aplicado. La corrección se hizo en `main` y `feature/agent`; `feature/interfaz` tenía su propia copia de este archivo sin ella, pero ya está fusionada en `main`.

### 19/10/2026 — Interfaz: conexión con el agente, timeout, reintento y dirección en caliente

- **Qué era:** `HttpMetricsRepository` pedía las métricas al agente sin timeout ni distinguir tipos de error; sin aviso en pantalla si no respondía; el sondeo seguía activo con la pantalla de Métricas en segundo plano o fuera de ella; cambiar la dirección en Ajustes no se aplicaba hasta reabrir la app.
- **Qué es ahora:**
  1. Timeout y errores (sin conexión, tiempo agotado, respuesta inválida) distinguidos con mensajes claros en `HttpMetricsRepository`.
  2. Aviso «No se puede conectar con el agente» con botón «Reintentar» en la pantalla de Métricas.
  3. El sondeo se pausa al salir de la pantalla de Métricas o con la app en segundo plano, y se reanuda al volver.
  4. `HttpMetricsRepository` recibe `() => settings.agentAddress` y lee la dirección del `SettingsViewModel` en cada petición: el cambio de dirección se aplica sin reiniciar la app (sustituye lo descrito en la entrada del 19/10/2026 «Métricas: repositorio HTTP real…», punto 5, ver nota en esa entrada).
- **Por qué:** cerraba los huecos de robustez de la conexión con el agente que quedaron abiertos al introducir `HttpMetricsRepository` el mismo día.
- **Afecta a:** `http_metrics_repository.dart`, `metrics_repository.dart`, `metrics_viewmodel.dart`, `metrics_view.dart`, `main.dart`, `test/http_metrics_repository_test.dart`.
- **Estado:** aplicado en código y verificado por USB con `adb reverse` contra el agente real (fase 1 cerrada, ver `04-plan-de-fases.md`).

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

### 21/10/2026 — Gestión de procesos: descartada, la cubre la terminal

- **Qué era:** el Módulo D de `01` y la fase 6 de `04` preveían una pantalla propia con la lista de procesos (búsqueda, filtro y orden por CPU y memoria) y su finalización en dos pasos (SIGTERM → SIGKILL), limitada a los procesos del propio usuario.
- **Qué es ahora:** no hay función propia. Ver qué procesos consumen más y matarlos se hace desde la terminal integrada (`htop`, `kill`). El Módulo D queda como marcador descartado en `01` para no cambiar la letra de los demás módulos. La fase 6 queda solo con energía, cuya inclusión está pendiente de decidir (`07` §3.8).
- **Por qué:** decisión del autor: lo más cercano a administrar procesos a ese nivel es matarlos a mano o abrir el administrador de procesos desde la terminal, así que una pantalla y unas rutas propias no aportan.
- **Afecta a:** `01` (§1, Módulo D, §3 navegación, §7, §10, §11), `02` (§2.3), `03` (§1, §2, §3), `04` (resumen, fase 6, recortes, demo, cobertura), `07` (§4 y recortes), `doc/agente/ESTRUCTURA.md`, `doc/agente/README.md` y `README.md`.
- **Estado:** aplicado en la documentación.

### 21/10/2026 — Multi-dispositivo: fuera de la documentación general

- **Qué era:** `01` §5.1 hablaba de emparejar "otro móvil" y `03` de varios móviles con un mismo PC; `07` fijaba un solo dispositivo y remitía a `06` como idea futura.
- **Qué es ahora:** un PC se empareja con un único móvil. El multi-dispositivo solo consta en `06`, marcado como muy a futuro y pendiente de investigar.
- **Por qué:** exigiría rediseñar varias piezas y no está claro cómo se comportarían la terminal (sesiones y ventanas en el PC) y las notas (ediciones simultáneas) con varios móviles a la vez.
- **Afecta a:** `01` (§5.1), `03` (§2), `06` y `07` (§3.2).
- **Estado:** aplicado en la documentación.

### 21/10/2026 — Procesos: se recupera como sección propia de la app

- **Qué era:** el mismo día se había descartado la gestión de procesos por considerar que la terminal ya la cubría (entrada «Gestión de procesos: descartada»).
- **Qué es ahora:** una sección nueva del menú lateral, «Procesos», con la lista de todos los procesos del PC y su consumo, búsqueda por nombre o PID, y las acciones de finalizar y congelar (con opción de reanudar), ambas con confirmación. La lista va ordenada por nombre, con barra de búsqueda por nombre o PID, y se actualiza cada segundo como Métricas. En el menú lateral va entre Métricas y Terminal. La fase 6 pasa a ser procesos más energía (esta última sigue pendiente de decidir).
- **Por qué:** idea nueva del autor; existen herramientas como `htop` y `psutil` que la hacen viable sin gran esfuerzo.
- **Afecta a:** `01` (resumen, Módulo D, navegación, casos de uso, comparativa), `03` (§1 y §2), `04` (resumen y fase 6) y `07` (§3.8 y §4).
- **Estado:** aplicado en la documentación.

### 22/10/2026 — Etiquetas de versión: solo para las releases del APK

- **Qué era:** `CLAUDE.md` y `README.md` decían «sin `develop` ni etiquetas por versión», mientras `04` publicaba el APK como release `v0.1-beta` y nombraba la fase 4 «v0.2».
- **Qué es ahora:** no hay `develop`; las etiquetas de versión (`v0.1-beta`, `v0.2`…) se usan solo para publicar el APK en las releases de GitHub.
- **Por qué:** una release de GitHub necesita una etiqueta; así se elimina la contradicción sin cambiar el plan.
- **Afecta a:** `CLAUDE.md` y `README.md`.
- **Estado:** aplicado en la documentación.

### 03/11/2026 — El proyecto pasa a llamarse Sysmote

- **Qué era:** el proyecto se llamaba «Linux System Companion»; el comando y el paquete del agente, `companion`; el paquete Dart, `tfg` (clase `TfgApp`); el id de Android, `io.github.alexxio070.companion`.
- **Qué es ahora:** el nombre visible es «Sysmote». En minúsculas, `sysmote` es el comando de la TUI, el paquete Python (`agent/sysmote/`), el paquete Dart y el id de Android (`io.github.alexxio070.sysmote`). Las rutas del PC documentadas pasan a `~/.config/sysmote`, `~/.local/share/sysmote/sysmote.db`, `sysmote.service`, etc. La clase de la TUI es `SysmoteApp`, igual que la de la app. El banner de la TUI dibuja «SYSMOTE».
- **Por qué:** decisión del autor.
- **Afecta a:** `agent/`, `App-movil/`, `README.md`, `CLAUDE.md`, `01`–`07`, `09`, `doc/agente/` y `doc/ui/`. Las entradas anteriores de este historial conservan el nombre antiguo, porque describen lo que se hizo en su fecha. El repositorio de GitHub conserva de momento su nombre (`Alex-TFG-DAM`).
- **Estado:** aplicado en la documentación y en `feature/agent` y `feature/interfaz`; con el id de Android nuevo, el móvil trata la app como una distinta a la instalada antes.

### 12/11/2026 — `shared_preferences` no guardaba nada en un dispositivo real

- **Qué era:** `shared_preferences: ^2.5.6` resolvía `shared_preferences_android` en su versión 2.5.0 (y, tras un intento de actualizarlo a mano, 2.5.5). En el emulador y en los tests (que usan `SharedPreferences.setMockInitialValues`) todo funcionaba; en un móvil real **ningún ajuste se guardaba** tras cerrar la app del todo y reabrirla — ni el identificador de iroh, ni la dirección del agente, ni el tema oscuro, ni nada.
- **Causa encontrada:** con `adb logcat`, cada llamada a `shared_preferences` (leer y guardar) lanzaba `PlatformException` → `java.lang.NoSuchMethodError: no non-static method ...SharedPreferencesApiRegistrar.getAll(...)` (y, tras subir la versión de `shared_preferences_android` a 2.5.5, el mismo error pero con `getInstance`). Es un desajuste real entre el código Dart generado por `shared_preferences` 2.5.6 y la clase Kotlin de `shared_preferences_android` en esas versiones — no se ha confirmado si es un fallo conocido y reportado en el repositorio oficial, solo que es reproducible de forma determinista en este proyecto. No tiene relación con MIUI ni con iroh, aunque se descubrió probando el identificador de iroh.
- **Qué es ahora:** se fija con `dependency_overrides` en `App-movil/pubspec.yaml` una pareja de versiones anterior y estable: `shared_preferences: 2.3.3` y `shared_preferences_android: 2.3.4`. Probado en un móvil real (Xiaomi/MIUI): el ajuste sobrevive a cerrar la app del todo y reabrirla.
- **Pendiente:** confirmar si hay una versión más reciente que corrija el fallo (para poder quitar el *override*) y, si no, considerar abrir un issue en el repositorio de `shared_preferences`.
- **Afecta a:** `App-movil/pubspec.yaml`. También de paso: `SettingsViewModel._update()` ahora espera (`await`) a que `save()` termine antes de dar el cambio por guardado, y `ConnectionFields` muestra un «Guardado» al terminar — refuerzos añadidos durante esta misma depuración, independientes del fallo de versión.
- **Estado:** aplicado.

### 12/11/2026 — Iroh probado en una red restrictiva real

- **Qué era:** quedaba pendiente repetir la conexión desde una red restrictiva real y averiguar si la red del centro deja salir el tráfico hacia los relés de iroh (decisión abierta en `07` §3.8).
- **Qué es ahora:** el autor confirma que la prueba se hizo y funciona. La decisión sale de §3.8 y se anota en §3.1.
- **Por qué:** la prueba se completó.
- **Afecta a:** `04` (fase 2), `07` (§3.1 y §3.8) y `doc/iroh/04-pruebas.md`. No se han anotado la red usada ni el detalle del resultado.
- **Estado:** aplicado en la documentación.

### 12/11/2026 — Fase 2 cerrada y puente Flutter ↔ iroh actualizado

- **Qué era:** `01` §4.1 y §4.4, `02` §4.2 y `07` §3.1 describían un componente nativo en Kotlin (*platform channel*, `openTunnel`/`closeTunnel`) con un puerto local, y la decisión sobre cómo usar iroh desde Flutter figuraba como pendiente (`07` §3.8, `04`). `04` no marcaba la fase 2 como cerrada y decía que de la beta «solo queda pendiente la conexión por iroh».
- **Qué es ahora:** la app usa el plugin `iroh_flutter` directamente desde Dart (`IrohMetricsRepository`), sin puente en Kotlin y sin puerto local; `ConnectionModeMetricsRepository` elige entre el repositorio HTTP y el de iroh según Ajustes. La decisión sale de `07` §3.8 y se anota en §3.1. La fase 2 queda cerrada en `04`: a la beta le falta publicar la release `v0.1-beta`.
- **Por qué:** el autor da la fase por cerrada y la implementación ya existe en el código (`App-movil/pubspec.yaml`, `doc/iroh/02-implementacion.md`).
- **Afecta a:** `01` (§4.1 y §4.4), `02` (§4.2), `04` (fase 2 y beta), `07` (§3.1 y §3.8) y `doc/iroh/README.md`. De la prueba 5 solo se reinició el proceso del agente, no el PC entero; consta en `04` y en `doc/iroh/`.
- **Estado:** aplicado en la documentación.

### 13/11/2026 — Métricas avisa de la conexión perdida; repositorios de métricas con base común

- **Qué era:** si el agente dejaba de responder con la pantalla de Métricas ya cargada, las gráficas se quedaban congeladas con los últimos valores y sin ningún aviso (el error solo se mostraba si todavía no había datos). Mientras cargaba, la pantalla se quedaba en blanco, y si el agente no devolvía ninguna partición desaparecían también CPU, temperatura y RAM. Además, `HttpMetricsRepository` e `IrohMetricsRepository` duplicaban unas 40 líneas, existía una pantalla aislada de prueba de iroh (`lib/debug/`) y el agente medía la CPU con un bloqueo de 100 ms en cada petición.
- **Qué es ahora:** Métricas muestra «Conectando con el agente…» mientras carga; «Conexión perdida. Reintentando…» encima de los últimos datos, que desaparece sola cuando vuelve a llegar una muestra; y «El agente no ha encontrado ninguna partición» en lugar de la tarjeta de disco, sin ocultar el resto. Los dos repositorios heredan de `AgentMetricsRepository` y solo implementan cómo traer el JSON; la pantalla aislada se ha borrado (Ajustes → iroh hace lo mismo); `cpu_percent` se mide sin intervalo bloqueante, sobre el tiempo transcurrido desde la llamada anterior.
- **Por qué:** auditoría del código del 13/11/2026. Los fallos se encontraron leyendo el código; el aviso de conexión perdida se comprobó después en un móvil real parando el agente.
- **Afecta a:** `doc/ui/interfaz-app.md` (§4), `doc/ui/estructura-app.md`, `doc/ui/tests.md`, `doc/agente/tests.md`, `doc/agente/ESTRUCTURA.md` y `doc/iroh/`. Código: `App-movil/lib/features/metrics/`, `App-movil/lib/data/` y `agent/sysmote/`.
- **Estado:** aplicado en código y en la documentación.

### 14/11/2026 — La red del centro vuelve a ser una duda abierta

- **Qué era:** la entrada del 12/11/2026 («Iroh probado en una red restrictiva real») daba por cerrada la duda de si la red del centro deja salir el tráfico hacia los relés de iroh, y la sacaba de `07` §3.8.
- **Qué es ahora:** la red restrictiva probada no era la del centro, así que esa duda vuelve a `07` §3.8. Forma prevista de probarlo, si el centro lo permite: el agente en marcha en el PC de casa, vigilado desde el centro con una sesión de AnyDesk, y el móvil conectado por iroh desde la Wi-Fi del centro.
- **Por qué:** el autor aún no sabe en qué condiciones le dejarán hacer la prueba en el centro.
- **Afecta a:** `04` (fase 2 y «Entorno de pruebas»), `07` (§3.1 y §3.8) y `doc/iroh/04-pruebas.md`.
- **Estado:** aplicado en la documentación.

### 16/11/2026 — Blindaje de iroh tras una revisión del código

- **Qué era:** cambiar el identificador iroh en Ajustes no surtía efecto mientras la conexión abierta siguiera viva; un identificador mal pegado solo daba el aviso genérico «No se pudo conectar»; salir y volver rápido a Métricas, o «Reintentar» con una carga en curso, podía dejar dos suscripciones a `watch()`; y la clave secreta del agente se escribía con los permisos por defecto antes del `chmod 0600`. `doc/ui/interfaz-app.md` decía que el identificador se aplicaba «en caliente», lo que no era cierto con una conexión abierta.
- **Qué es ahora:** el repositorio cierra la conexión y abre otra si cambia el identificador; Ajustes rechaza un identificador que no sean 64 caracteres hexadecimales y el repositorio avisa con un mensaje propio; `MetricsViewModel` descarta los refrescos anteriores con un contador de generación; la clave secreta se crea ya con `0600` y un archivo corrupto da un error claro. Para probarlo, la conexión iroh va tras una interfaz mínima (`IrohLink`) que los tests sustituyen por una falsa: la reconexión y los dos *timeouts* pasan a tener test automático. El límite de conexiones y de *streams* del túnel, el *timeout* de inactividad y la captura de cualquier excepción del bucle de `run()` se aplazan a la fase 3, cuando exista el login.
- **Por qué:** pregunta del autor sobre si la fase 2 estaba «blindada»; la respuesta honesta era que solo lo estaba frente a los fallos ya vistos, y se revisó el código contra esa lista.
- **Afecta a:** `04` (fase 3), `doc/iroh/` (§2 de `04-pruebas.md`, `03-problemas-y-soluciones.md` §8–11, `02-implementacion.md`), `doc/ui/interfaz-app.md` §7, `doc/ui/tests.md` y `doc/agente/tests.md`. Código: `App-movil/lib/data/iroh/`, `App-movil/lib/data/models/settings.dart`, `App-movil/lib/features/metrics/` y `agent/sysmote/iroh_tunnel.py`.
- **Estado:** aplicado en código y en la documentación. La prueba 5 de la matriz sigue parcial.

### 16/11/2026 — Un solo intento de conexión iroh a la vez

- **Qué era:** el límite de 5 s al conectar solo dejaba de esperar; el intento nativo no se cancela (`Endpoint.connect` de `iroh_flutter` no lo permite) y seguía vivo. La siguiente petición lanzaba otro intento, y si el viejo conectaba tarde, esa conexión quedaba sin cerrar. Consecuencias deducidas, no vistas en el móvil.
- **Qué es ahora:** `IrohMetricsRepository` mantiene un solo intento nativo a la vez. Las peticiones que llegan mientras sigue en marcha lo esperan, cada una con su límite de 5 s; si conecta tarde se aprovecha, y si el identificador cambió se cierra al llegar. Un test del agente comprueba con iroh real que las tareas de reenvío del túnel no se acumulan. IPv6 y el relé caído quedan como limitaciones conocidas que el autor no puede reproducir, y la medición de fugas nativas en el móvil, como procedimiento manual pendiente.
- **Por qué:** duda abierta tras el blindaje de la entrada anterior: no se podía afirmar que no quedaran conexiones sin cerrar.
- **Afecta a:** `doc/iroh/` (`02-implementacion.md`, `03-problemas-y-soluciones.md` §12, `04-pruebas.md`, `README.md`), `doc/ui/tests.md` y `doc/agente/tests.md`. Código: `App-movil/lib/data/iroh/iroh_metrics_repository.dart` y los tests.
- **Estado:** aplicado en código y en la documentación.

### 16/11/2026 — Prueba 5 de la matriz de iroh completada

- **Qué era:** la prueba 5 (reiniciar el agente y el PC: el identificador iroh debe ser el mismo) constaba como parcial, porque el 12/11/2026 solo se había reiniciado el proceso del agente, no el PC entero.
- **Qué es ahora:** el autor confirma que la prueba funciona: el identificador iroh es el mismo tras reiniciar el PC. Se quitan de `doc/iroh/` y de `04` las menciones a que estaba parcial o pendiente. Las entradas anteriores de este historial conservan lo que era cierto en su fecha.
- **Por qué:** la prueba se completó.
- **Afecta a:** `04` (estado de la fase 2), `doc/iroh/04-pruebas.md` y `doc/iroh/README.md`. No se han anotado la fecha ni los detalles del reinicio, solo la confirmación del autor. Queda como está la repetición de esta prueba en la fase 5, con el servicio instalado.
- **Estado:** aplicado en la documentación.

### 17/11/2026 — Sin TLS propio dentro del túnel iroh

- **Qué era:** la memoria decía que el mismo TLS autofirmado con certificate pinning se mantendría dentro del túnel iroh, para que la seguridad no dependiera del modo de conexión.
- **Qué es ahora:** HTTPS con huella fijada en la conexión por red local (USB o LAN). Por iroh no hay TLS propio: el cifrado y la autenticación del agente los pone iroh (QUIC con TLS 1.3 y clave pública), con el login obligatorio en los dos casos. El túnel reenvía a un puerto HTTP interno que solo escucha en `127.0.0.1`.
- **Por qué:** `SecureSocket` de Dart está pensado para sockets y no para un *stream* arbitrario como el de iroh (no se ha comprobado con una prueba), y repetir el cifrado complicaba la app sin aportar protección extra. La documentación oficial de iroh (FAQ, consultada el 17/11/2026) confirma el cifrado y la autenticación por clave pública; indica además que prevé cambiar al tipo de certificado de clave pública en bruto, un detalle del mecanismo.
- **Afecta a:** `01` (§4.4, §5.1, §5.3), `02` §5.1, `07`, `doc/iroh/01-que-es-y-como-funciona.md` y el contrato de la fase 3 (`doc/agente/contrato-api-fase3.md`).
- **Estado:** aplicado en la documentación; sin implementar.

### 17/11/2026 — Una sesión activa solo se sobrescribe con confirmación en la TUI

- **Qué era:** el contrato de la fase 3 proponía que un login nuevo sustituyera la sesión anterior sin más.
- **Qué es ahora:** con una sesión activa, un login correcto crea una solicitud pendiente y no abre sesión hasta que el usuario lo confirma en la TUI del PC («Hay una sesión activa en {dispositivo}, ¿quieres cerrarla e iniciar una nueva?», con «Sí, sobrescribir la sesión» y «No, mantener la sesión anterior»). La app avisa antes del login con el campo `sesion_activa` de `GET /estado` y espera la decisión con `GET /login/solicitud/{id}`. La solicitud caduca a los 5 minutos.
- **Por qué:** decisión del autor: quien conozca la contraseña pero no esté delante del PC no debe poder echar al dispositivo conectado.
- **Afecta a:** `01` §5.2, `doc/agente/tui.md` (subpestaña Seguridad) y `doc/agente/contrato-api-fase3.md`.
- **Estado:** aplicado en la documentación; sin implementar.

### 17/11/2026 — Desemparejamiento: TUI, app y limitación al desinstalar

- **Qué era:** «Desemparejar» en la TUI no tenía efecto definido en la app, y no se había decidido qué pasa si se desinstala la app o el agente.
- **Qué es ahora:** al desemparejar en la TUI, la app recibe `401 desemparejado` y olvida el equipo. La app tiene además su propio botón «Desemparejar» (`POST /desemparejar`). La sesión caduca a los 30 días sin uso, la TUI muestra la última conexión y «Quitar servicio» avisa a la app si está conectada. **Desinstalar la app o el agente no desempareja automáticamente**: Android no avisa a una app cuando se desinstala y la app no puede distinguir un agente desinstalado de un PC apagado. La limitación queda documentada en `01` §10 y en el README.
- **Por qué:** petición del autor de un desemparejamiento automático también al desinstalar; no es viable, así que se adoptaron las alternativas fiables.
- **Afecta a:** `01` §10, `04` (fases 3 y 5), `doc/agente/tui.md` y `doc/agente/contrato-api-fase3.md`; nota en `README.md` y `README.en.md`.
- **Estado:** aplicado en la documentación; sin implementar.

### 18/11/2026 — Fase 3 implementada en el agente: registro con código y QR en la TUI

- **Qué era:** el plan decía que en la fase 3 la TUI crearía el usuario y que el QR de emparejamiento y registro llegaría en la fase 9.
- **Qué es ahora:** la TUI no crea la cuenta. Abre el modo registro y muestra el QR (con la dirección, la huella y el identificador iroh, que va siempre) y un código de registro de un solo uso (16 caracteres en base32, 10 minutos). La cuenta la crea la app con `POST /registro`. La contraseña exige como mínimo 5 caracteres, un número y una mayúscula. `POST /registro` distingue tres errores `403`: `registro_cerrado`, `codigo_caducado` y `codigo_invalido`. La TUI y el agente se comunican solo por SQLite: la tabla efímera `solicitud_login` lleva las solicitudes de login pendientes y `codigo_registro` los códigos. Con la fase 3 se añaden también el HTTPS autofirmado con huella, Argon2, los tokens opacos con caducidad de 30 días sin uso y el límite de intentos (5 permitidos; el 6.º ya recibe `429`). El comando `sysmote` abre la TUI y arranca el agente (HTTPS en 8443, HTTP interno en `127.0.0.1:8444` y túnel iroh). El QR pasa de la fase 9 a la 3; el escáner en la app sigue en la fase 9.
- **Por qué:** decisión del autor: el QR de la TUI se adelanta de la fase 9 a la 3. El resto son los detalles que se cerraron al implementar el contrato.
- **Afecta a:** `01` (§5.1, §6.2), `02` (§5.1, §5.2: `cryptography` 50.0 y `argon2-cffi` 25.1, comprobadas en PyPI el 18/11/2026), `04` (fases 3 y 9, recortes y cobertura) y `doc/agente/contrato-api-fase3.md`.
- **Estado:** implementado y probado en el agente. La parte de la app está en la entrada siguiente.

### 18/11/2026 — App: login, registro y token de sesión (fase 3)

- **Qué era:** la app no pedía login: iba directa a la pantalla principal. El estado de «emparejado» lo simulaba un `PairingRepository` con datos de ejemplo.
- **Qué es ahora:** sin sesión, la app solo muestra el login, guiado por `GET /estado` (agente inalcanzable, sin cuenta, registro, login, bloqueo con cuenta atrás, espera de confirmación en la TUI). Tiene registro con código, token en el Keystore, «Cerrar sesión» y «Desemparejar» en Ajustes, y un campo de huella del certificado. En modo Local usa HTTPS con un cliente sin ninguna CA pública que solo acepta el certificado cuyo SHA-256 coincide con la huella guardada; por iroh, HTTP por el túnel con `Bearer`. Métricas también va con `Bearer`. Se retira `PairingRepository`, y el doble de pruebas de autenticación vive solo en `test/`.
- **Por qué:** consecuencias de implementar el contrato. Dos decisiones de diseño nuevas: el login ofrece «Conexión con el PC» porque la dirección y la huella se configuran en Ajustes, dentro de la app, y sin esa salida el usuario quedaría atrapado; y si el agente no responde, un token guardado no se borra, porque puede ser solo un fallo de red.
- **Afecta a:** `App-movil/lib/data`, `features/auth`, `features/settings`, `doc/ui/` y `doc/agente/contrato-api-fase3.md` (su estado).
- **Estado:** implementado. 223 tests y análisis limpio; probado contra el agente real por HTTPS. Sin probar en un móvil físico ni por iroh.

### 18/11/2026 — Túnel iroh endurecido y puerto HTTP interno de referencia

- **Qué era:** el túnel no limitaba conexiones ni *streams*, no cortaba un *stream* inactivo y cualquier excepción que no fuera de iroh en su bucle lo tumbaba. Estaba aplazado a la fase 3 (`doc/iroh/04-pruebas.md`, puntos 10 y 11). El túnel reenviaba al puerto que le pasaba quien lo arrancaba (8443 en `iroh_poc.py`).
- **Qué es ahora:** `Limits` fija 4 conexiones simultáneas (al llegar al límite se cierra la más antigua, no la nueva), 8 *streams* por conexión (los sobrantes se rechazan) y 60 s de inactividad por *stream* (contando las dos direcciones juntas). Cualquier excepción del bucle se registra y el túnel sigue. `INTERNAL_HTTP_PORT = 8444` documenta el puerto HTTP interno propuesto para el destino, según la decisión del 17/11/2026 (sin TLS propio por iroh), que no fija el número; el túnel solo reenvía a `127.0.0.1`.
- **Por qué:** con el login de la fase 3, el túnel pasa a exponer algo más que métricas. El límite de *streams* se cuenta en el túnel porque el de iroh no se aplica tras aceptar la conexión (comprobado con una prueba).
- **Afecta a:** `doc/iroh/` (`02-implementacion.md` §2, `03-problemas-y-soluciones.md` §13, `04-pruebas.md`, `README.md`) y `04` (se quita el punto de la fase 3). Código: `agent/sysmote/iroh_tunnel.py` y `agent/tests/test_iroh_tunnel.py`. Pendiente de revisar en la fase 4: 60 s cortarían una terminal inactiva.
- **Estado:** aplicado en código y en la documentación.

### 18/11/2026 — Limpieza de la parte de iroh

- **Qué era:** `agent/scripts/iroh_poc.py` arrancaba a mano el agente y el túnel con su propia clave (`iroh_secret_key_poc.bin`), aunque desde la fase 3 los arranca `sysmote.server.Servidores` con la clave real: daba otro identificador y su puerto chocaba con el de la TUI. `iroh_tunnel.py` tenía una constante `INTERNAL_HTTP_PORT` que no usaba nadie, y `pairing_service.py` importaba la función privada `_load_or_create_secret_key`. `IrohMetricsRepository` recibía un identificador que ignoraba, y sus tests probaban sobre todo la lógica de `IrohConnection`.
- **Qué es ahora:** se borran el script y la constante; la función pasa a ser pública (`load_or_create_secret_key`); `IrohMetricsRepository` recibe la conexión compartida y el token, igual que `IrohAuthRepository`. Los tests de la conexión pasan a `iroh_connection_test.dart`, y se quitan o fusionan los redundantes después de comprobar, rompiendo el código a propósito, que otro test cubría lo mismo: tests de iroh del agente de 13 a 12 y de la app de 15 a 14 (9 de la conexión y 5 del repositorio, uno de ellos nuevo). Comentarios y docstrings en el túnel y en el repositorio.
- **Por qué:** auditoría de simplificación y legibilidad pedida por el autor.
- **Afecta a:** `agent/sysmote/iroh_tunnel.py`, `agent/sysmote/services/pairing_service.py`, `App-movil/lib/data/iroh/iroh_metrics_repository.dart`, `App-movil/lib/main.dart`, los tests de iroh, `doc/iroh/`, `doc/agente/ESTRUCTURA.md`, `doc/agente/tests.md` y `doc/ui/tests.md`.
- **Estado:** aplicado en código y en la documentación.

### 19/11/2026 — Revisión de la documentación frente al código

- **Qué era:** tras las auditorías, `07` seguía diciendo que hasta la fase 9 la cuenta se crea en la TUI y que el QR llega en la fase 9; la tabla de errores del contrato no recogía los `404` ni el `405`; `huella_distinta` figuraba como un error del agente; los README omitían la consulta de solicitud de login entre las rutas que responden sin sesión; y `CONTRIBUTING.md` describía una rama `feature/<nombre>` por tarea.
- **Qué es ahora:** `07` dice que la cuenta la crea la app con el código de registro (la TUI no la crea) y que la TUI muestra el QR desde la fase 3, con el escáner de la app en la fase 9; el contrato añade `404 solicitud_desconocida`, `404 no_encontrado` y `405 metodo_no_permitido`, y aclara que `huella_distinta` es un error de la app y no del agente; los README recogen la consulta de solicitud; `CONTRIBUTING.md` explica que los cambios llegan por pull request desde una rama cortada de `main`.
- **Por qué:** revisión pedida por el autor antes del PR de las auditorías, cruzando la documentación con el código, el contrato y la ejecución de la guía de instalación.
- **Afecta a:** `07`, `doc/agente/contrato-api-fase3.md`, `doc/agente/tests.md`, `README.md`, `README.en.md` y `CONTRIBUTING.md`.
- **Estado:** aplicado en la documentación.

### 19/11/2026 — `schema.sql` dentro del paquete del agente

- **Qué era:** `schema.sql` estaba en `agent/`, fuera del paquete `sysmote`. Con una instalación editable (`pip install -e`) funcionaba, pero al instalar el agente de forma normal (`pip` o `pipx install ./agent`) el archivo no se incluía y `sysmote` terminaba con un `FileNotFoundError` al abrir la base de datos. La guía de instalación ofrecía `pipx` como alternativa válida.
- **Qué es ahora:** `schema.sql` está en `agent/sysmote/` y `pyproject.toml` lo declara como dato del paquete; `database.py` lo busca junto a sí mismo. Verificado construyendo el paquete, instalándolo sin modo editable en un entorno limpio y arrancando `sysmote`; también con `pipx install ./agent`.
- **Por qué:** el agente se distribuye como paquete de Python (`pip`, `pipx install sysmote`), y eso exige que todo lo que necesita viaje dentro del paquete.
- **Afecta a:** `agent/sysmote/database.py`, `agent/pyproject.toml`, `agent/sysmote/schema.sql` y las rutas citadas en `doc/agente/` (`ESTRUCTURA.md`, `README.md`, `tui.md`), `01`, `02` y `04`.
- **Estado:** aplicado en código y en la documentación.

### 19/11/2026 — Auditoría complementaria y correcciones

- **Qué era:** quedaban por auditar la organización de carpetas y archivos, la legibilidad, la completitud de los comentarios, la seguridad del login, las dependencias y la configuración de Android. De ello salió que el login con un usuario inexistente respondía más rápido que con una contraseña incorrecta (delataba si el usuario existe); que dos registros simultáneos con un código válido podían crear dos cuentas; que `AppTopBar` vivía dentro de `shell/` aunque la usaban otras secciones; que había dos docstrings y trece `///` por escribir; que no había formateador en Dart; y varios desajustes de documentación (captura de la TUI anterior al QR, URL de uvicorn, «TLS 1.3», el bloqueo por intentos sin documentar como limitación).
- **Qué es ahora:** el login ejecuta Argon2 también con un usuario inexistente; el esquema lleva un índice único que limita la base de datos a una cuenta, y `registrar` convierte el rechazo en `registro_cerrado`; `AppTopBar` está en `core/widgets/`; los docstrings y los `///` están completos (96 de 96 en el agente y 176 de 176 en la app); `dart format` con ancho de 100 columnas fijado en `analysis_options.yaml`; la captura de la TUI está regenerada; `02` dice que el servidor acepta TLS 1.2 y 1.3; `05` cita `uvicorn.dev`; los README recogen el bloqueo por intentos como limitación conocida; y `doc/agente/ESTRUCTURA.md` y `doc/ui/estructura-app.md` escriben la convención de nombres y las piezas transversales. Se quita `test_sesion_repository.py`, porque su escenario (dos cuentas) ya no puede darse.
- **Por qué:** revisión pedida por el autor antes del PR de las auditorías. Los informes de las auditorías no se publican: se guardan solo en local.
- **Afecta a:** `agent/sysmote/services/auth_service.py`, `password_service.py`, `schema.sql`, `iroh_tunnel.py`, sus tests y `doc/agente/tests.md` (155 tests); `App-movil/` (formato, `AppTopBar` y comentarios); `02`, `05`, los dos README, `doc/img/tui-emparejamiento.png`, `doc/agente/ESTRUCTURA.md` y `doc/ui/estructura-app.md`.
- **Estado:** aplicado en código y en la documentación. Quedan como decisión del autor la convención de nombres de los documentos, el identificador de la aplicación de Android, los emojis de `04` a `06`, la copia de seguridad de Android, un archivo de restricciones para Python y el formateador de Python.

### 19/11/2026 — Paquete del agente preparado para PyPI

- **Qué era:** el agente solo se podía instalar desde el código fuente. `pyproject.toml` no tenía autor, descripción larga, enlaces ni clasificadores, `agent/README.md` solo remitía al README raíz y la licencia no viajaba dentro del paquete.
- **Qué es ahora:** `pyproject.toml` declara el autor (Alexxio), las palabras clave, nueve clasificadores comprobados contra la lista oficial de PyPI, los enlaces del proyecto y `license-files`; `agent/README.md` es la página del paquete, con instalación por `pipx` y por `pip` en un entorno virtual; y `agent/LICENSE` es una copia de la licencia. Verificado construyendo el sdist y la rueda, mirando su contenido (incluyen `schema.sql`, la licencia y el README) e instalando la rueda en un entorno limpio, donde `sysmote` arranca.
- **Por qué:** decisión del autor de distribuir el agente como paquete de Python en PyPI. La instalación recomendada sigue siendo `pipx`, con `pip` dentro de un entorno virtual como alternativa.
- **Afecta a:** `agent/pyproject.toml`, `agent/README.md`, `agent/LICENSE`, `02` §7.2, `07` §3.1 y `04` (fase 5).
- **Estado:** aplicado. Se publicó en PyPI el 19/11/2026 con el flujo descrito en la entrada siguiente. Una versión subida a PyPI no se puede volver a subir con el mismo número.

### 19/11/2026 — Versión del esquema y migraciones de la base de datos

- **Qué era:** el agente aplicaba `schema.sql` en cada conexión con `CREATE TABLE IF NOT EXISTS`, que no modifica las tablas que ya existen. No había versión de esquema ni migraciones: cuando una fase posterior añadiera una columna a una tabla, la base de datos de un usuario que ya tuviera esa tabla no la tendría y el agente fallaría.
- **Qué es ahora:** la versión del esquema se guarda en la propia base (`PRAGMA user_version`; la 1 es el esquema con el que se publica el agente). `agent/sysmote/migraciones.py` guarda los cambios pendientes, cada uno como una tupla de sentencias SQL que se ejecuta en su propia transacción, y `database.connect()` los aplica al abrir una base que ya existía. Una base nueva se crea directamente con `schema.sql` y salta las migraciones, y una base de una versión más nueva que el agente da un error claro. Cada cambio de esquema futuro se escribe a la vez en `schema.sql` y en `migraciones.py`.
- **Por qué:** hacía falta antes de que haya usuarios con datos y de publicar el agente en PyPI, porque `pipx upgrade` actualiza el código pero no toca la base de datos del usuario. Sin esto, un cambio de tablas en una fase futura habría roto las instalaciones existentes.
- **Afecta a:** `agent/sysmote/database.py`, `agent/sysmote/migraciones.py`, `agent/tests/test_migraciones.py`, `01` §6, `doc/agente/ESTRUCTURA.md` y `doc/agente/tests.md` (161 tests).
- **Estado:** aplicado en código y en la documentación. De momento no hay migraciones: el esquema actual es la versión 1.

### 19/11/2026 — Publicación del agente en PyPI con GitHub Actions

- **Qué era:** el paquete estaba preparado pero no publicado, y publicarlo habría exigido subirlo a mano con un token personal.
- **Qué es ahora:** el workflow `.github/workflows/publicar-agente.yml` se dispara al subir una etiqueta `agent-v*` (publica en PyPI) o a mano (publica en TestPyPI). Pasa los tests del agente, comprueba que la etiqueta coincide con la versión de `agent/pyproject.toml`, construye con `uv build` y publica con Trusted Publishing: PyPI acepta la identidad temporal de GitHub, así que no hay ningún token guardado. El entorno `pypi` exige la aprobación del autor antes de cada publicación.
- **Por qué:** publicar sin guardar secretos y con un paso humano de aprobación; el prefijo `agent-v` evita que las etiquetas de la APK disparen la publicación.
- **Afecta a:** `.github/workflows/publicar-agente.yml`, `04` (fase 5) y esta entrada.
- **Estado:** `sysmote 0.1.0` publicado en PyPI el 19/11/2026 tras un ensayo en TestPyPI. Las versiones siguientes se publican subiendo `version` en `agent/pyproject.toml` y la etiqueta `agent-vX.Y.Z`.

### 19/11/2026 — Cambiar la contraseña levanta el bloqueo por intentos

- **Qué era:** tras cinco intentos fallidos la cuenta se bloquea 10 minutos. Quien olvidaba la contraseña y la cambiaba desde la TUI seguía bloqueado, y la contraseña nueva no entraba hasta pulsar también «Reiniciar intentos». Se detectó en la primera prueba con un móvil físico.
- **Qué es ahora:** `auth_service.cambiar_contrasena` borra además los intentos de la cuenta, de modo que la contraseña nueva entra al momento. «Reiniciar intentos» sigue existiendo por separado.
- **Por qué:** quien cambia la contraseña desde la TUI es el dueño del PC; mantener el bloqueo no protege nada y despista.
- **Afecta a:** `agent/sysmote/services/auth_service.py`, `agent/tests/test_auth_service.py` (un test nuevo, 162 en total), `doc/agente/tui.md` y `doc/agente/tests.md`.
- **Estado:** aplicado y probado.

### 19/11/2026 — Login: aviso por campos vacíos y nombre del dispositivo opcional

- **Qué era:** en el login y en el registro, el botón no hacía nada y no avisaba si faltaba algún campo, y el nombre del dispositivo era obligatorio. En la primera prueba con un móvil físico, escribir mal la contraseña sin rellenar ese nombre no daba ningún mensaje.
- **Qué es ahora:** si falta el usuario, la contraseña (o el código, en el registro) aparece un aviso que lo dice. El nombre del dispositivo es opcional: la app propone el fabricante y el modelo del móvil (leídos con `device_info_plus`) y, si se deja vacío, usa «Móvil Android». Solo sirve para el historial y para el aviso de sesión activa de la TUI.
- **Por qué:** el nombre es informativo, no una credencial, y un formulario que no responde parece roto.
- **Afecta a:** `App-movil/lib/features/auth/` (`login_view.dart`, `login_form.dart`, `registration_form.dart`), `App-movil/lib/data/device_name.dart` (nuevo), `pubspec.yaml` (dependencia nueva `device_info_plus` 13.3.0), `test/login_widget_test.dart` (3 tests nuevos, 223 en total), `doc/ui/interfaz-app.md`, `doc/ui/tests.md` y `02` (tabla de dependencias).
- **Estado:** aplicado y probado (`flutter analyze` sin avisos, 223 tests). Falta probarlo en el móvil físico.

### 19/11/2026 — Primera prueba en un móvil físico

- **Qué era:** el README, el README del paquete, `04` y `interfaz-app.md` decían que la app no se había probado en un móvil físico ni el login por iroh.
- **Qué se probó:** en un Xiaomi Redmi 13C con Android 15, con el agente instalado desde PyPI (`pipx`): registro con código de un solo uso, login y métricas reales por red local (HTTPS con la huella fijada), ajustes persistentes, bloqueo por intentos fallidos, cierre de sesión y login completo por iroh con datos móviles. La TUI funcionó bien.
- **Qué falló o faltaba:** el puerto 8443 estaba bloqueado por el cortafuegos del PC (`ufw`) hasta abrirlo para la red local; el login no avisaba si faltaba un campo y exigía el nombre del dispositivo; y tras cambiar la contraseña desde la TUI seguía el bloqueo por intentos. Los dos últimos se corrigen en las dos entradas anteriores.
- **Qué sigue sin probarse:** la conexión por USB con `adb reverse`, y las partes simuladas de la app (macros, terminal y notas).
- **Afecta a:** `README.md`, `README.en.md`, `agent/README.md`, `doc/ui/interfaz-app.md`, `04` y esta entrada.
- **Estado:** documentación actualizada con lo que se comprobó, sin afirmar más.

### 19/11/2026 — Fase 3 cerrada y USB obsoleto como método de prueba

- **Qué era:** la fase 3 figuraba como implementada, con la prueba en un móvil físico y por USB pendientes, y el plan seguía nombrando el USB con `adb reverse` como una de las comprobaciones de la fase.
- **Qué es ahora:** la fase 3 está cerrada. El autor comprobó en un Xiaomi Redmi 13C (Android 15), por red local y por iroh, los tres criterios de «Terminada cuando»: sin login no se puede hacer nada, una huella distinta es rechazada y «Cerrar todas las sesiones» expulsa al móvil. El USB con `adb reverse` deja de usarse como método de prueba; la comprobación «por USB y por iroh» de la fase 3 pasa a ser «por red local y por iroh».
- **Por qué:** con la conexión por red local y por iroh funcionando en un móvil real, el USB no aporta nada que no cubran; solo seguía útil para instalar la app, y eso se hace con `adb install`, que no necesita `adb reverse`.
- **Limitaciones del túnel iroh:** IPv6, relé caído, fugas de memoria y la falta de un test automático de la conexión real se dan por cerradas sin probarlas: el autor no tiene forma de reproducirlas. Quedan como limitaciones conocidas, no como comprobadas.
- **Afecta a:** `04-plan-de-fases.md` (fase 3), `doc/iroh/04-pruebas.md` y esta entrada.
- **Estado:** aplicado en la fase 3. Quedan menciones del USB en otras partes del plan y de los README (entorno de pruebas, respaldo de la defensa, fase 4, guía de instalación); se revisan aparte.

### 19/11/2026 — Decisiones abiertas de la auditoría

- **Qué era:** la auditoría dejó seis decisiones del autor sin resolver: nombres de los documentos, `applicationId` de Android, emojis de `04` a `06`, `allowBackup`, versiones fijas de Python y formateador de Python. Las cuatro capturas de la app seguían con la fecha del 16/11.
- **Qué se decidió y qué se hizo:**
  - **Nombres de documentos:** todo en kebab-case. Se renombran `doc/agente/ESTRUCTURA.md` a `estructura.md`, `doc/ui/XTERM_DART.md` a `xterm-dart.md` y los dos `DESIGN.md` de `doc/ui/historico/` a `design.md`, con sus enlaces. Las entradas antiguas de este historial conservan los nombres que tenían entonces.
  - **`applicationId`:** se deja `io.github.alexxio070.sysmote`, la convención habitual de proyectos sin dominio propio. Hay que mantenerlo desde la primera APK publicada, porque cambiarlo después rompe las actualizaciones.
  - **Emojis de `04` a `06`:** se dejan. La norma de «sin emojis» se refiere al código.
  - **`allowBackup`:** `android:allowBackup="false"` en el manifiesto. El token ya está en el almacenamiento seguro; el coste es que una reinstalación pierde la dirección y la huella guardadas. No se comprobó que la copia de seguridad fuera explotable.
  - **Versiones fijas de Python:** se sube `agent/uv.lock` (solo para desarrollo y CI; quien instala desde PyPI sigue usando las cotas mínimas del `pyproject.toml`).
  - **Formateador de Python:** `ruff format` con 100 columnas, como en Dart, declarado en `pyproject.toml` y en las dependencias de desarrollo. El reformateo de 24 archivos va en un commit aparte y no cambia el comportamiento (162 tests). Quedan unas 34 líneas de más de 100 columnas, casi todas docstrings y textos, que el formateador no parte.
  - **Capturas de la app:** se dejan como están; el autor comprobó que no cambió nada visible.
- **Afecta a:** `doc/agente/estructura.md`, `doc/ui/xterm-dart.md`, `doc/ui/historico/`, `AndroidManifest.xml`, `agent/pyproject.toml`, `agent/uv.lock`, el código Python del agente, ambos README y esta entrada.
- **Estado:** aplicado y probado (162 tests del agente).

### 19/11/2026 — Pantalla de bienvenida y caducidad de la sesión a 7 días

- **Qué era:** en el primer inicio la app mostraba la pantalla de «agente inalcanzable», con el error repetido y los botones «Reintentar» y «Conexión con el PC»; el token de sesión caducaba a los 30 días sin usarse.
- **Qué se decidió:**
  - **Bienvenida:** «Sysmote» arriba y, abajo, «Conectar con el agente» si no hay emparejamiento, o «Iniciar sesión» y «Registrar cuenta» si ya lo hay. Cuenta ya creada o registro cerrado: popup. PC sin respuesta: aviso pequeño con la causa, sin botón de reintentar. Los formularios pierden «Conexión con el PC».
  - **Emparejada:** una marca guardada tras el primer contacto con el agente, que se borra al cambiar la dirección, la huella o el identificador iroh. No se deduce de los ajustes porque la dirección nunca está vacía (trae `127.0.0.1:8443` por defecto), ni de preguntar al agente porque un PC apagado se confundiría con una app sin configurar.
  - **Caducidad:** 7 días desde el inicio de sesión, sin renovarse con el uso, en lugar de 30 días sin uso. La regla de inactividad desaparece del desemparejamiento.
  - **Historial:** la tabla `sesion` ya conserva todas las sesiones; se le añade `caduca_en`. Se guarda el hash del token, no el token en claro, para que quien lea la base de datos no pueda iniciar sesión. Las sesiones existentes reciben `creado_en + 7 días` al migrar.
- **Por qué:** el primer inicio no es un error y no debe parecerlo; y la caducidad absoluta acota lo que dura un token robado.
- **Afecta a:** `doc/ui/interfaz-app.md` (§7 bis.1), `doc/agente/contrato-api-fase3.md`, `01-memoria-tecnica.md` (tabla `sesion` y desemparejamiento), `07-resumen-decisiones-y-contexto.md` (§3.2) y esta entrada. Quedan por actualizar al implementarlo: `doc/ui/estructura-app.md`, `doc/ui/tests.md`, `doc/agente/tests.md` y `doc/agente/estructura.md`.
- **Estado:** diseño aprobado y documentado el 19/11/2026; sin implementar. La pantalla y la caducidad van en ramas y PR separados.
