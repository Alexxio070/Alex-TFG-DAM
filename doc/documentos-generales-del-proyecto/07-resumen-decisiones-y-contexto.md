# Resumen de la conversación de diseño: decisiones y contexto

Este documento complementa a los archivos 01–06 y 08. Aquellos describen **qué** es el proyecto; este recoge **por qué** se ha llegado a cada decisión, qué se descartó y con qué motivo, qué queda pendiente y cómo quiere trabajar el autor. Sirve como contexto para cualquier conversación futura sobre el proyecto.

---

## 1. Quién soy y qué es esto

- Estudiante de **DAM (Desarrollo de Aplicaciones Multiplataforma)**. Este es mi proyecto final.
- **No tengo experiencia en desarrollo Android ni en Flutter.** En clase he visto Kotlin a un nivel muy básico que apenas aporta a este proyecto. Voy a aprender sobre la marcha, así que necesito metas pequeñas y asequibles y explicaciones claras.
- Mi entorno personal es **KDE Plasma** sobre Linux.
- El punto de partida fueron tres documentos generados con otra IA (memoria técnica, justificación del stack y un "system context" en inglés). Los revisamos, tenían incoherencias entre sí y errores técnicos, y se rehicieron por completo en los documentos 01–06.

---

## 2. La idea central (lo más importante)

**Sysmote es una app para administrar mi PC Linux desde el móvil cuando NO estoy delante de él**, desde casa o desde cualquier sitio.

**Criterio de alcance:** si una función solo tiene sentido estando delante o cerca del PC, **queda fuera del TFG**. Este criterio decidió qué se mantenía y qué se descartaba.

**Frase para la defensa:** *KDE Connect es una herramienta para cuando estás cerca del PC; Sysmote es para cuando no lo estás.*

**Requisito de experiencia de usuario:**
- En el móvil, **solo descargar la app**; nada de instalar VPNs ni otras apps.
- En el PC se aceptan dependencias.
- **Nunca configurar el router.**
- Flujo deseado: instalar agente → abrir la TUI y hacer la configuración inicial → instalar app → escanear el QR → crear la cuenta → conectar desde cualquier parte. Hasta la fase 9, las credenciales se crean en la TUI.

**Filosofía de desarrollo:** la primera versión (beta) debe tener **pocas funciones, pero todas funcionando**: una base sólida sobre la que ampliar. Desde el 12/10/2026 la beta es mínima: la interfaz definitiva con *placeholders*, las métricas y la conexión por iroh, sin login.

---

## 3. Registro de decisiones

### 3.1 Tecnología

| Decisión | Elegido | Motivo | Descartado |
|---|---|---|---|
| Framework móvil | **Flutter** (aceptado por el tutor el 26/09/2026) | Se valora usar tecnología no vista en clase; xterm.dart resuelve la terminal (la pieza más difícil); *hot reload* ayuda a aprender | Kotlin + Compose: más fácil para iroh (binding oficial), pero sin emulador de terminal equivalente. Era el plan B; ya no es necesario |
| Agente PC | Python 3.11 + FastAPI | Mejores librerías de sistema; asíncrono | Go, Rust (curva), Flask (síncrono) |
| Acceso remoto | **iroh**, túnel local (patrón dumbpipe), **fase 2 (principios de noviembre – mediados de diciembre)**, adelantado el 02/10/2026 por ser la parte más crítica | Cero configuración para el usuario, sin servidores propios, y si falla se cae automáticamente a "solo LAN" | Tailscale (obliga a app VPN en el móvil), relé propio (el peor: cifrado propio y servidor que pagar), Cloudflare Tunnel. WebRTC con STUN/TURN (servidores propios) **queda como respaldo** solo si iroh da problemas reales (27/09/2026) |
| Puente Flutter ↔ iroh | Platform channel mínimo en Kotlin: `openTunnel` / `closeTunnel` (*pendiente de revisión*) | Flutter no sabe que iroh existe; usa el mismo código que en LAN | El binding de Kotlin publicado no incluye Android y hay que compilarlo con Rust y el NDK igualmente, así que el plugin `iroh_flutter` (pub.dev) vuelve a ser candidato. Se decide al empezar la fase 2 |
| Tokens | Opacos, con hash en SQLite | Revocables al instante (botón «Cerrar todas las sesiones») | JWT (no revocables; innecesarios con un solo dispositivo) |
| BD | SQLite con `sqlite3` + patrón repositorio + `schema.sql` | Sencillo, sin servidor, cumple la normativa. El tutor confirmó que SQLite local es válido (28/09/2026) | SQLAlchemy (excesivo), MySQL, Firebase |
| Instalación del agente | **pipx** | Usa el Python de la distro; evita atar el agente a la glibc con la que se compila, aunque iroh exige glibc ≥ 2.28 | PyInstaller (atado a la glibc de compilación), pip directo (bloqueado en distros modernas), Flatpak (su aislamiento impide PTY y D-Bus) |
| Servicio | systemd de usuario con `default.target` + linger opcional | Al quitar lo gráfico, no hace falta la sesión gráfica | `graphical-session.target` |
| Herramienta del PC | **TUI con botones (Textual)** al escribir `sysmote` (12/10/2026, librería confirmada el 15/10/2026); **Typer** solo para `sysmote serve` y `sysmote notify`; QR con `qrcode` | Botones en lugar de comandos que recordar; `serve` y `notify` los lanzan systemd y los scripts; Textual es la opción mejor soportada para botones/formularios frente a las alternativas | Solo CLI con Typer (diseño anterior), curses (bajo nivel), urwid (más bajo nivel que Textual), prompt_toolkit (pensado para línea de comandos/REPL, no pantallas con varios controles), py_cui (sin publicaciones desde 2022, abandonado) |
| Arquitectura app | MVVM con provider + repositorios simulados | Capas claras (requisito); permite trabajar sin el agente | BLoC (demasiado para quien empieza) |

### 3.2 Seguridad
- **TUI en lugar de CLI (12/10/2026):** al escribir `sysmote` se abre una TUI con botones para todo (configuración inicial y QR de registro, QR de emparejamiento, servicio, estado, contraseña, cerrar sesiones, notas y exportaciones).
- **Construcción de la TUI adelantada a la fase 1 (15/10/2026, estructura revisada el 15/10/2026):** igual que la interfaz de la app, la TUI se construye entera y de una vez. Estructura fija: banner, área de datos vacía por defecto y cuatro botones — **Emparejamiento** (con tres subpestañas: Dispositivo —QR y datos del dispositivo—, Seguridad —fase 3: configuración inicial, contraseña, cerrar sesiones— y Servicio —fase 5: instalar, quitar, estado—), **Historial** (acciones rápidas de la fase 7 y comandos de terminal desde un archivo de log aparte), **Base de datos** (navegador en vivo de las tablas + exportaciones de la fase 7) y **Notas** (CRUD de notas de la fase 9). Las fases posteriores no añaden botones a la barra: activan contenido dentro de estas cuatro secciones.
- **Historial de comandos de terminal (15/10/2026):** archivo de log en una carpeta dentro de `~/.cache` (`ISO-8601<TAB>comando`), sin límite de tamaño por ahora; no se duplica en SQLite. Solo registra lo que la app envía por el WebSocket de la terminal al pulsar Enter — el agente no ve lo escrito directamente en la ventana del PC (eso exigiría integración de shell con OSC 133, descartada del TFG, ver `06-ideas-de-futuro.md` §5). La pantalla Historial combina este log con la tabla `ejecucion` solo al mostrarlos.
- **Registro por QR (12/10/2026):** la TUI muestra un QR con la dirección, la huella, el identificador iroh y un código de registro de un solo uso con caducidad corta. La app lo escanea, muestra "Emparejado, se necesita crear autenticación" y abre un diálogo de usuario y contraseña. El modo registro se cierra tras la primera cuenta. **Va en la fase 9 (12/10/2026);** hasta entonces el usuario se crea desde la TUI.
- **TLS autofirmado con certificate pinning.** La huella llega en el QR (hasta la fase 9, se compara a ojo con la que muestra la TUI).
- **2FA descartado** porque choca con la configuración mínima. Se compensa con contraseña robusta, límite de intentos y revocación.
- **Un solo dispositivo.**
- **El agente nunca usa root ni sudo.** Para operaciones de root, la app avisa de que hay que usar la terminal.

### 3.3 Terminal
- Se lanza `$SHELL -l` de forma genérica. **No hay que programar soporte por shell**: el PTY funciona igual con Bash, Zsh y Fish. **Shell probada oficialmente: Zsh.**
- La paleta y la fuente las pone el móvil, no la shell. **Decisión del 15/10/2026:** se descarta la Nerd Font; la app usa la fuente monoespaciada del sistema Android.
- Temas de terminal: "si da tiempo".
- **Sesiones persistentes con tmux (14/10/2026):** la sesión de terminal es del agente y no de la conexión. La app solo pide «abre una terminal y ejecuta esto» y se engancha para ver la salida; si cierra la app, la limpia de recientes o pierde la red, el comando sigue en el PC y se recupera la salida al volver. El agente abre además una ventana de la terminal gráfica del usuario conectada a la misma sesión. La sesión termina con `exit`, al cerrar su ventana en la app o al cerrar su ventana en el PC; sin caducidad por inactividad. Empieza con una sola sesión. Sin sesiones activas, la app muestra una terminal vacía con un aviso de que tocar o escribir abre una ventana en el PC; la sesión se crea al primer toque o tecla (shell real desde el principio) y se sustituye el aviso por el prompt. Al reabrir la app, solo se restauran sus propias pestañas. Detalle en `../agente/terminal-sesiones-tmux.md`.
- **tmux como dependencia del PC (14/10/2026):** se acepta (en el PC se aceptan dependencias). Sin tmux, la terminal queda ligada a la conexión, con aviso.

### 3.4 Notificaciones (dentro del TFG)
- Quiero recibir en el móvil avisos del PC, por ejemplo cuando **Claude Code termine de trabajar**, cuando un proceso de terminal termine o arranque bien, o si hay **CPU o RAM elevadas**.
- Diseño:
  - `sysmote notify "mensaje"` por socket Unix (sirve para scripts y *hooks* de Claude Code);
  - reglas de alerta por umbral;
  - servicio en primer plano en Android que reutiliza el del túnel iroh.
- **Sin Firebase.** Funciona también en LAN, sin iroh.

### 3.5 Espacio compartido (dentro del TFG, decidido el 12/10/2026)
- **Sustituye al explorador y la transferencia de archivos**, que pasan a ideas de futuro (06).
- Un espacio común entre el móvil y el PC donde dejar **notas de texto y enlaces** para pasar información de un lado a otro. CRUD desde la app y botones de la TUI en el PC; la app pide las notas al abrir la pantalla y al recargar (sin actualización al momento: es una app para usar lejos del PC). Si los dos lados editan la misma nota, gana el último cambio.
- **Imágenes: aún pensándolo.** Fuera del alcance confirmado hasta que se decida.
- Va en la fase 9, después del CRUD (fase 7), cuyo patrón reutiliza.
- **Pantalla de Notas definitiva (12/10/2026):** lista de notas con tarjetas, búsqueda, formulario de crear/editar y borrado, tal como describe el Módulo F. Sustituye al campo de texto único del prototipo v1, que queda descartado. Detalle en `../ui/historico/ui-v2/DESIGN.md`; el prototipo inicial se conserva como histórico en `../ui/historico/ui-v1/`.

### 3.6 Requisitos mínimos de DAM
Se evaluó el proyecto contra la normativa del centro. Huecos detectados y cómo se resolvieron:
- **CRUD de 2 entidades relacionadas:** no existía. Se añadieron las **acciones rápidas**: `grupo` 1:N `accion_rapida` 1:N `ejecucion`, con CRUD completo de grupos y acciones. Refuerzo con `regla_alerta` 1:N `notificacion` y con `nota` (espacio compartido).
- **BD de 3–4 tablas:** ahora son 9 tablas, con `schema.sql` y repositorios.
- **Diseño de BD, casos de uso, pruebas y capturas en la memoria:** añadidos a la documentación y al plan.
- **Elemento diferenciador:** cubierto de sobra (cámara/QR, servicio en segundo plano con notificaciones, P2P, PTY).
- **Flutter:** la normativa cita "Android Studio, Kotlin, Java" y Flutter no aparece, pero **el tutor lo aceptó (26/09/2026)**. Riesgo cerrado.
- **Agente en Python:** es parte fundamental del proyecto; sin él la app no funciona (02/10/2026).

### 3.7 Exportar la base de datos (12/10/2026)
- Dos botones en la TUI (fase 7), con los archivos en el escritorio (`XDG_DESKTOP_DIR`, normalmente `~/Escritorio`; si no existe, la carpeta personal) y la fecha y la hora en el nombre.
- **Datos:** un JSON `sysmote-datos-AAAAMMDD-HHMM.json` con una sección por tabla, sin `sesion`, `intento_login` ni el hash de la contraseña. Descartados CSV (un archivo por tabla, pierde tipos) y SQL con `INSERT` (mezcla datos y estructura).
- **Estructura:** carpeta `sysmote-estructura-AAAAMMDD-HHMM/` con `tablas.sql`, `indices.sql`, `vistas.sql` y `triggers.sql`, leídos de `sqlite_schema`. Los *joins* no se guardan en la BD: las relaciones son las claves foráneas de `tablas.sql`. El diseño no tiene vistas ni triggers, así que esos archivos llevan un comentario que lo explica.

### 3.8 Decisiones abiertas

Con su fecha límite para resolverlas. Cuando una se cierre, se pasa a la sección que le corresponda de §3 y se quita de aquí.

| Decisión | Estado | Cuándo resolverla |
|---|---|---|
| Cómo usar iroh desde Flutter: binding de Kotlin compilado desde el código fuente + *platform channel*, o el plugin `iroh_flutter` de pub.dev | **Pendiente de revisión:** el binding de Kotlin publicado no incluye Android; las dos opciones necesitan Rust y el NDK | Al empezar la fase 2, con la prueba de concepto |
| Imágenes en el espacio compartido | **Aún pensándolo** (fuera del alcance confirmado) | Antes de la fase 9 |
| Tipo del servicio en primer plano de Android | **Pendiente de revisión:** no `dataSync`; candidato `connectedDevice` | En la fase 8 |
| ¿La red del centro deja salir HTTPS con WebSocket hacia los relés de iroh? | **Pendiente de revisión:** preguntar en el centro cómo está montada la red | Antes de la prueba en red restrictiva (fase 2) |
| Fecha exacta del hito de febrero y fecha oficial de entrega de la memoria | **Pendiente de revisión** | Cuando se conozcan |
| ¿Entra el control de energía (apagar, reiniciar, suspender, hibernar, bloquear) en el proyecto? **Por qué está:** encaja con el criterio de alcance (tiene sentido sin estar delante del PC), forma parte del valor diferencial (`01` §2) y cuenta como elemento diferenciador de integración con el sistema (D-Bus / systemd-logind, `01` §12), aunque quedan otros (cámara/QR, servicio en segundo plano, P2P con iroh). **Por qué se duda:** sin sesión activa polkit puede denegarla y la solución exige una regla manual con sudo (fila siguiente); apagado el PC no se puede volver a encender desde el móvil (Wake-on-LAN descartado); hibernar suele no estar configurado y es el primer recorte; su pantalla no tiene sitio decidido en la app. *Otros motivos del autor: pendientes de anotar.* | **Pendiente de decidir** | Antes de la fase 6 |
| Energía sin sesión activa: apagar/reiniciar/suspender/hibernar vía logind puede necesitar una regla de polkit (instalación manual con sudo, el agente no puede escribirla) para funcionar sin una sesión gráfica activa | **Pendiente de investigar:** confirmar si falla de verdad en KDE Plasma 6 y valorar los riesgos de seguridad de esa regla antes de decidir si se añade | Antes de la fase 6 |

---

## 4. Lo descartado y por qué

**Descartado por no tener sentido estando lejos del PC** (va a *06-ideas-de-futuro.md* como posible "modo cercanía"):
- control multimedia (MPRIS);
- mezclador de volumen por aplicación y cambio de salida de audio. Mi motivo: "¿para qué querría modificar el volumen de una app si no estoy delante del PC?";
- batería de periféricos;
- abrir URLs en el PC;
- notificaciones del móvil al escritorio;
- ricing de KDE y personalización en general;
- portapapeles compartido. Se reconvirtió en **espacio compartido** de notas de texto y enlaces, que el 12/10/2026 pasó a formar parte del TFG (ver 3.5).
- explorador y transferencia de archivos (12/10/2026): sustituido por el espacio compartido; queda como idea de futuro.
- **Campo de texto único compartido para Notas (12/10/2026):** era la pantalla del prototipo v1. Se descartó porque no cubría notas de texto y enlaces con CRUD y búsqueda. Lo sustituye la lista de notas de `../ui/historico/ui-v2/`.

**Descartado por complejidad o por chocar con otros requisitos:**
- Terminal ligada a la conexión del móvil como comportamiento por defecto (14/10/2026): el comando se cortaba al cerrar o limpiar la app. Sustituida por sesiones persistentes con tmux; queda solo como alternativa si falta tmux.
- Cliente de sesiones propio en lugar de tmux (14/10/2026): **aplazado a muy largo plazo** para eliminar la dependencia; por plazo no entra en el TFG (ver 06).
- Wake-on-LAN;
- 2FA;
- alertas con Firebase;
- soporte para otros escritorios o gestores de ventanas (solo KDE; expandir en el futuro);
- iOS (muy a futuro, fuera del alcance).

---

## 5. Planificación (resumen; detalle en 04)

**Calendario (02/10/2026, revisado el 12/10/2026):**
- **Interfaz ya hecha (12/10/2026):** la interfaz definitiva de la app está terminada, con *placeholders* y datos simulados.
- **Beta v0.1 (mediados de diciembre – Navidad):** mínima: interfaz definitiva, métricas y conexión por iroh, sin login.
- La seguridad y la instalación van detrás de la beta. La terminal termina a mediados de febrero (si el hito es antes, hay que ajustar) y las fases 9–10 coinciden con la redacción de la memoria en mayo. Si hay retraso, se aplica el orden de recortes.
- **Hito de febrero:** versión funcional con la app conectándose al PC a través de iroh, la terminal y las gráficas de rendimiento. *Fecha exacta pendiente de revisión.*
- **Defensa:** primera semana de junio de 2027. *Fecha oficial de entrega de la memoria pendiente de revisión.*

**Criterios:**
- lo más arriesgado primero: iroh justo después de las métricas, para descubrir pronto si da problemas;
- después, lo obligatorio y lo de más impacto en la nota;
- fases difíciles intercaladas con fáciles para no dejar lo importante al final;
- lo de menor impacto, al final como "si da tiempo".

**Calendario completo, fase a fase:** `04-plan-de-fases.md`.

- **Sin login en la beta:** el agente solo expone métricas de solo lectura y se arranca a mano.
- **La beta NO necesita cumplir los mínimos de DAM.**

**Orden de recorte si voy con retraso:** reglas de alerta → mDNS → hibernar → registro por QR. Si iroh no funciona, se aplica el plan B en la fase 2 (solo LAN). **Nunca se recortan:** iroh (o su plan B documentado), terminal, CRUD de acciones rápidas, login y TLS, y pulido mínimo de errores.

---

## 6. Entorno de pruebas

Métodos y alternativas descartadas: `02-necesidades-tecnologicas.md` §8.4. Tabla operativa completa, con la matriz de pruebas de iroh: `04-plan-de-fases.md`, «Entorno de pruebas».

---

## 7. Forma de trabajar con Claude

- **Proyecto de Claude (organización actual):**
  - la fuente de los documentos 01–08 es `doc/` en el repositorio de GitHub (Alexxio070/Alex-TFG-DAM); la carpeta "Documentacion TFG" del proyecto de Claude es un espejo que se actualiza desde el repo;
  - el trabajo se organiza en hilos con prefijo **PROYECTO:** (desarrollo del TFG), **APRENDIZAJE:** (unidades de estudio) y **PREGUNTAS:** (dudas sueltas);
  - alex abre una sesión de Claude Code por rama `feature/*` o por tarea de documentación; cada sesión propone sus commits antes de hacerlos.
- **Regla de confirmación previa (01/10/2026):** antes de generar o crear nada, Claude explica cómo ha entendido la petición y su plan (qué, cómo y por qué), y espera mi confirmación explícita. Nunca toca el repositorio salvo que yo lo pida.
- **No usar el conocimiento del proyecto como repositorio manual** del código: se queda desactualizado. El repositorio real es Git/GitHub.
- **Reparto de herramientas:**
  - chat o proyecto para planificar, entender conceptos y redactar la memoria;
  - Claude Code para escribir y depurar código.
- **Aprendizaje:** usar Claude como profesor y revisor más que como autor. Tengo que entender y poder defender todo el código.
- **Preferencia de trabajo:** antes de generar documentos, quiero que se me diga **cuántos y qué contendrá cada uno**, y que las propuestas vengan **numeradas** para que yo decida qué se añade y qué no.

---

## 8. Open source y uso de IA

- Cuando termine el TFG, **la app se publicará como open source**.
- Preocupación: a mucha gente le echan para atrás las apps "vibecodeadas".
- **Commits:** en Claude Code, desactivar la firma con `"attribution": false` en `settings.json` (o, por partes, `"attribution": {"commit": "", "pr": "", "sessionUrl": false}`; `sessionUrl` quita el enlace a la sesión que se añade en las sesiones en la nube), o hacer yo los commits. Los commits antiguos con firma se pueden limpiar con `git filter-repo` **después de la evaluación**.
- **Lo que genera confianza de verdad:**
  - commits pequeños y concretos;
  - tests y CI;
  - un README honesto escrito por mí;
  - código coherente que sé mantener;
  - responder a issues con criterio.
- Postura recomendada: declarar el uso de IA de forma breve ("asistido por IA, revisado y mantenido por el autor") en vez de ocultarlo.
- **Para el TFG (aclarado con el tutor, 28/09/2026):** usar librerías como infraestructura está permitido (por ejemplo, `xterm.dart`), incluso para la funcionalidad estrella. Lo que hay que evitar es copiar fragmentos concretos de código de internet sin entenderlos ni integrarlos. El proyecto puede estar asistido por IA siempre que yo entienda lo que hace y pueda defenderlo ante el tribunal (explicar cualquier parte o hacer un cambio en directo). Declararlo en la memoria.

---

## 9. Qué NO está en estos documentos

- **La normativa oficial de requisitos mínimos del proyecto de DAM.** Aquí solo está resumida (03, sección 2) y cruzada con el plan (04, tabla final). **Súbela también al proyecto** tal cual la da el centro.
- **Los tres documentos originales generados con otra IA.** Están obsoletos y sustituidos por los 01–06; no hace falta conservarlos.
- **Explicaciones didácticas** que se dieron en la conversación (qué es un platform channel, cómo funciona un PTY, etc.). Son conocimiento general que se puede volver a preguntar.
