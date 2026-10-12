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

---

## Entradas

### 12/10/2026 — Notas: de campo de texto único a lista con CRUD

- **Qué era:** el prototipo v1 (`doc/ui/ui-v1`) tenía un único campo de texto a pantalla completa, compartido con el PC en ambos sentidos, con estado «Sincronizando…».
- **Qué es ahora:** una **lista de notas** con búsqueda, recarga al deslizar, formulario de crear y editar, y borrado con confirmación (`doc/ui/ui-v2/ESPECIFICACION_NOTAS.md`).
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
- **Afecta a:** `ESTRUCTURA_FLUTTER.md` (decisión obsoleta, ver «Pendiente de aplicar»), `ui/XTERM_DART.md` (nuevo). Código: `App-movil/lib/features/terminal/`.
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

---

## Pendiente

Cosas abiertas tras la revisión del 12/10/2026. Ya no hay incoherencias de redacción conocidas entre la documentación y la implementación; lo que queda son huecos de la interfaz o decisiones de plan:

| Área | Qué falta |
|---|---|
| Inicio (UI) | Papelera sobre carpeta: preguntar «mover a Sin grupo» o «borrar» (hoy borra todo el contenido) |
| Inicio (UI) | Validar nombre de macro (1–50 caracteres) y nombres únicos dentro de la carpeta |
| Inicio (UI) | Selector de icono para las macros (hoy siempre `bolt`) |
| Fase 7 | Definir el acceso a la ficha de acción y a su historial, y los valores por defecto de la creación rápida |
| Terminal | Nerd Font (fase 4) y parpadeo del cursor si se quiere (limitación de `xterm.dart` 4.0.0) |
| Tema oscuro | El acento por defecto tiene poco contraste sobre fondo oscuro; valorar un tono más claro en oscuro |
| Metodología | Mantener este historial al día: anotar aquí cada cambio de diseño que se aparte de lo documentado |
