# Resumen de la conversación de diseño: decisiones y contexto

Este documento complementa a los archivos 01–06, 08 y 09. Aquellos describen **qué** es el proyecto; este recoge **por qué** se ha llegado a cada decisión, qué se descartó y con qué motivo, qué queda pendiente y cómo quiere trabajar el autor. Sirve como contexto para cualquier conversación futura sobre el proyecto.

---

## 1. Quién soy y qué es esto

- Estudiante de **DAM (Desarrollo de Aplicaciones Multiplataforma)**. Este es mi proyecto final.
- **No tengo experiencia en desarrollo Android ni en Flutter.** En clase he visto Kotlin a un nivel muy básico que apenas aporta a este proyecto. Voy a aprender sobre la marcha, así que necesito metas pequeñas y asequibles y explicaciones claras.
- Mi entorno personal es **KDE Plasma** sobre Linux.
- El punto de partida fueron tres documentos generados con otra IA (memoria técnica, justificación del stack y un "system context" en inglés). Tenían incoherencias entre sí y errores técnicos, y se rehicieron por completo en los documentos 01–06.

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

**Filosofía de desarrollo:** la primera versión (beta) debe tener **pocas funciones, pero todas funcionando**: una base sólida sobre la que ampliar. La beta es mínima: la interfaz definitiva con *placeholders*, las métricas y la conexión por iroh, sin login.

---

## 3. Registro de decisiones

### 3.1 Tecnología

| Decisión | Elegido | Motivo | Descartado |
|---|---|---|---|
| Framework móvil | **Flutter** (aceptado por el tutor el 26/09/2026) | Se valora usar tecnología no vista en clase; xterm.dart resuelve la terminal (la pieza más difícil); *hot reload* ayuda a aprender | Kotlin + Compose: más fácil para iroh (binding oficial), pero sin emulador de terminal equivalente |
| Agente PC | Python 3.11 + FastAPI | Mejores librerías de sistema; asíncrono | Go, Rust (curva), Flask (síncrono) |
| Acceso remoto | **iroh**, túnel local (patrón dumbpipe), en la fase 2 (adelantado el 02/10/2026 por ser la parte más crítica) | Cero configuración para el usuario, sin servidores propios, y si falla se cae automáticamente a "solo LAN" | Tailscale (app VPN en el móvil), relé propio (cifrado propio y servidor que pagar), Cloudflare Tunnel. WebRTC con STUN/TURN **queda como respaldo** solo si iroh da problemas reales (27/09/2026) |
| Puente Flutter ↔ iroh | Plugin **`iroh_flutter`** (pub.dev) llamado desde Dart, sin puente en Kotlin | La app tiene un `IrohMetricsRepository` con la misma interfaz que el repositorio HTTP; `ConnectionModeMetricsRepository` elige uno u otro según Ajustes, así que ViewModels y vistas no cambian | Platform channel con módulo Kotlin: el binding publicado no incluye Android y habría que compilarlo igualmente |
| Red restrictiva real | Probado en una red restrictiva real, que no era la del centro: iroh conecta y funciona (confirmado por el autor, 12/11/2026) | Confirma que iroh funciona por el relé en una red restrictiva. La red del centro sigue sin probarse (§3.8) | — |
| Tokens | Opacos, con hash en SQLite | Revocables al instante (botón «Cerrar todas las sesiones») | JWT (no revocables; innecesarios con un solo dispositivo) |
| BD | SQLite con `sqlite3` + patrón repositorio + `schema.sql` | Sencillo, sin servidor, cumple la normativa. El tutor confirmó que SQLite local es válido (28/09/2026) | SQLAlchemy (excesivo), MySQL, Firebase |
| Instalación del agente | **pipx** | Usa el Python de la distro; evita atar el agente a la glibc con la que se compila, aunque iroh exige glibc ≥ 2.28 | PyInstaller (atado a la glibc de compilación), pip directo (bloqueado en distros modernas), Flatpak (su aislamiento impide PTY y D-Bus) |
| Servicio | systemd de usuario con `default.target` + linger opcional | Al quitar lo gráfico, no hace falta la sesión gráfica | `graphical-session.target` |
| Herramienta del PC | **TUI con botones (Textual)** al escribir `sysmote`; **Typer** solo para `sysmote serve` y `sysmote notify`; QR con `qrcode` (ver §3.7) | Botones en lugar de comandos que recordar; Textual es la opción mejor soportada para botones y formularios | Solo CLI con Typer, curses y urwid (bajo nivel), prompt_toolkit (pensado para REPL), py_cui (abandonado) |
| Arquitectura app | MVVM con provider + repositorios simulados | Capas claras (requisito); permite trabajar sin el agente | BLoC (demasiado para quien empieza) |

### 3.2 Seguridad
- **Registro por QR (12/10/2026), en la fase 9:** la TUI muestra un QR con un código de registro de un solo uso; la app lo escanea y crea la cuenta. Hasta entonces el usuario se crea desde la TUI. Detalle en `01-memoria-tecnica.md` §5.1.
- **TLS autofirmado con certificate pinning.** La huella llega en el QR (hasta la fase 9, se compara a ojo con la que muestra la TUI).
- **2FA descartado** porque choca con la configuración mínima. Se compensa con contraseña robusta, límite de intentos y revocación.
- **Un solo dispositivo.**
- **El agente nunca usa root ni sudo.** Para operaciones de root, la app avisa de que hay que usar la terminal.

### 3.3 Terminal
- Se lanza `$SHELL -l` de forma genérica. **No hay que programar soporte por shell**: el PTY funciona igual con Bash, Zsh y Fish. **Shell probada oficialmente: Zsh.**
- La paleta y la fuente las pone el móvil, no la shell. **Decisión del 15/10/2026:** se descarta la Nerd Font; la app usa la fuente monoespaciada del sistema Android.
- Temas de terminal: "si da tiempo".
- **Sesiones persistentes con tmux (14/10/2026):** la sesión es del agente y no de la conexión, así que un comando sigue en el PC aunque se cierre la app o se pierda la red, y el agente abre además una ventana en la terminal gráfica del PC. Detalle en `01` §3 (Módulo A) y `../agente/terminal-sesiones-tmux.md`.
- **tmux como dependencia del PC (14/10/2026):** se acepta (en el PC se aceptan dependencias). Sin tmux, la terminal queda ligada a la conexión, con aviso.

### 3.4 Notificaciones (dentro del TFG)
- Quiero recibir en el móvil avisos del PC, por ejemplo cuando **Claude Code termine de trabajar**, cuando un proceso de terminal termine o arranque bien, o si hay **CPU o RAM elevadas**.
- Diseño:
  - `sysmote notify "mensaje"` por socket Unix (sirve para scripts y *hooks* de Claude Code);
  - reglas de alerta por umbral;
  - servicio en primer plano en Android que reutiliza el del túnel iroh.
- **Sin Firebase.** Funciona también en LAN, sin iroh.

### 3.5 Espacio compartido (dentro del TFG, decidido el 12/10/2026)
- **Sustituye al explorador y la transferencia de archivos**, que pasan a `06-ideas-de-futuro.md`.
- Notas de texto y enlaces entre el móvil y el PC, en la fase 9, reutilizando el patrón del CRUD de la fase 7. Sin actualización al momento (es una app para usar lejos del PC); si los dos lados editan la misma nota, gana el último cambio. Detalle en `01` §3 (Módulo F).
- **Imágenes: aún pensándolo** (§3.8).
- **Pantalla de Notas:** lista de tarjetas con búsqueda y formulario aparte, en lugar del campo de texto único del prototipo v1. Detalle en `../ui/historico/ui-v2/DESIGN.md`.

### 3.6 Requisitos mínimos de DAM
Se evaluó el proyecto contra la normativa del centro. Huecos detectados y cómo se resolvieron:
- **CRUD de 2 entidades relacionadas:** se añadieron las **acciones rápidas**: `grupo` 1:N `accion_rapida` 1:N `ejecucion`, con CRUD completo de grupos y acciones. Refuerzo con `regla_alerta` 1:N `notificacion` y con `nota` (espacio compartido).
- **BD de 3–4 tablas:** el diseño tiene 9 tablas, con `schema.sql` y repositorios.
- **Diseño de BD, casos de uso, pruebas y capturas en la memoria:** incluidos en la documentación y en el plan.
- **Elemento diferenciador:** cubierto de sobra (cámara/QR, servicio en segundo plano con notificaciones, P2P, PTY).
- **Flutter:** la normativa cita "Android Studio, Kotlin, Java" y Flutter no aparece, pero **el tutor lo aceptó (26/09/2026)**. Riesgo cerrado.
- **Agente en Python:** es parte fundamental del proyecto; sin él la app no funciona (02/10/2026).

### 3.7 TUI del agente y exportaciones
- **TUI en lugar de CLI (12/10/2026; Textual confirmado el 15/10/2026):** al escribir `sysmote` se abre una TUI con botones para todo, en vez de comandos que recordar.
- **Construida entera en la fase 1 (15/10/2026):** igual que la interfaz de la app, con cuatro secciones fijas (Emparejamiento, Historial, Base de datos y Notas). Las fases posteriores activan contenido dentro de ellas, no añaden botones. Especificación en `../agente/tui.md`.
- **Historial de comandos de terminal (15/10/2026):** archivo de log aparte en `~/.cache`, no en SQLite. Solo registra lo que la app envía por la terminal; lo escrito directamente en la ventana del PC exigiría integración de shell (OSC 133), descartada del TFG (`06` §5).
- **Exportar la base de datos (12/10/2026), en la fase 7:** dos botones de la TUI que dejan los archivos en el escritorio. Los datos van en un JSON (descartados CSV, que pierde los tipos, y SQL con `INSERT`, que mezcla datos y estructura); la estructura, en archivos `.sql` leídos de `sqlite_schema`. Detalle en `01` §6.3.

### 3.8 Decisiones abiertas

Con su fecha límite para resolverlas. Cuando una se cierre, se pasa a la sección que le corresponda de §3 y se quita de aquí.

| Decisión | Estado | Cuándo resolverla |
|---|---|---|
| Imágenes en el espacio compartido | **Aún pensándolo** (fuera del alcance confirmado) | Antes de la fase 9 |
| Tipo del servicio en primer plano de Android | **Pendiente de revisión:** no `dataSync`; candidato `connectedDevice` | En la fase 8 |
| Fecha exacta del hito de febrero y fecha oficial de entrega de la memoria | **Pendiente de revisión** | Cuando se conozcan |
| ¿La red del centro deja salir el tráfico de iroh hacia los relés? (forma prevista de probarlo: abajo) | **Pendiente de revisión** (14/11/2026) | Antes de la defensa |
| ¿Entra el control de energía (apagar, reiniciar, suspender, hibernar, bloquear) en el proyecto? (motivos: abajo) | **Pendiente de decidir** | Antes de la fase 6 |
| Energía sin sesión activa: logind puede necesitar una regla de polkit, instalada a mano con sudo, para funcionar sin sesión gráfica | **Pendiente de investigar:** confirmar si falla de verdad en KDE Plasma 6 y valorar los riesgos de esa regla | Antes de la fase 6 |

**Red del centro.** Aún no se sabe en qué condiciones se podrá probar en el centro. Forma prevista, si el centro la permite: dejar el agente en marcha en el PC de casa, vigilarlo desde el centro con una sesión de AnyDesk y conectar el móvil por iroh desde la Wi-Fi del centro. AnyDesk también sale por la red del centro, así que, aunque funcione, no garantiza que funcione iroh: lo que cuenta es la conexión del móvil.

**Control de energía.**
- *Por qué está:* encaja con el criterio de alcance (tiene sentido sin estar delante del PC), forma parte del valor diferencial (`01` §2) y cuenta como elemento diferenciador de integración con el sistema (D-Bus / systemd-logind, `01` §12), aunque quedan otros (cámara/QR, servicio en segundo plano, P2P con iroh).
- *Por qué se duda:*
  - sin sesión activa polkit puede denegarla y la solución exige una regla manual con sudo (última fila de la tabla);
  - apagado el PC no se puede volver a encender desde el móvil (Wake-on-LAN descartado);
  - hibernar suele no estar configurado y es el primer recorte;
  - su pantalla no tiene sitio decidido en la app.
- *Otros motivos del autor:* pendientes de anotar.

---

## 4. Lo descartado y por qué

**Descartado por no tener sentido estando lejos del PC** (va a `06` como posible "modo cercanía"):
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

## 5. Planificación

Calendario, criterios, orden de recortes y lo que nunca se recorta: `04-plan-de-fases.md`. Lo esencial:
- **Beta v0.1 (mediados de diciembre – Navidad):** interfaz definitiva, métricas y conexión por iroh, sin login. No necesita cumplir los mínimos de DAM.
- **Hito de febrero:** la app se conecta al PC por iroh y ofrece la terminal y las gráficas.
- **Defensa:** primera semana de junio de 2027. Fechas pendientes: §3.8.

---

## 6. Entorno de pruebas

Métodos y alternativas descartadas: `02-necesidades-tecnologicas.md` §8.4. Tabla operativa completa, con la matriz de pruebas de iroh: `04`, «Entorno de pruebas».

---

## 7. Forma de trabajar con Claude

- **Proyecto de Claude (organización actual):**
  - la fuente de los documentos 01–09 es `doc/` en el repositorio de GitHub (Alexxio070/Alex-TFG-DAM); la carpeta "Documentacion TFG" del proyecto de Claude es un espejo que se actualiza desde el repo;
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

- Cuando termine el TFG, **la app se publicará como open source**. Preocupación: a mucha gente le echan para atrás las apps "vibecodeadas".
- **Commits sin firma de IA:** desactivar la atribución en Claude Code (`"attribution"` en `settings.json`) o hacer yo los commits; los antiguos con firma se pueden limpiar con `git filter-repo` **después de la evaluación**.
- **Lo que genera confianza de verdad:** commits pequeños y concretos, tests y CI, un README honesto escrito por mí, código coherente que sé mantener y responder a issues con criterio. Declarar el uso de IA de forma breve ("asistido por IA, revisado y mantenido por el autor") en vez de ocultarlo.
- **Para el TFG (aclarado con el tutor, 28/09/2026):** usar librerías como infraestructura está permitido (por ejemplo, `xterm.dart`), incluso para la funcionalidad estrella. Lo que hay que evitar es copiar fragmentos concretos de código de internet sin entenderlos ni integrarlos. El proyecto puede estar asistido por IA siempre que yo entienda lo que hace y pueda defenderlo ante el tribunal (explicar cualquier parte o hacer un cambio en directo). Declararlo en la memoria.

---

## 9. Qué NO está en estos documentos

- **La normativa oficial de requisitos mínimos de DAM:** aquí solo está resumida (`03` §3) y cruzada con el plan (`04`, «Cobertura de los requisitos mínimos»); el original es el del centro.
- **Los tres documentos originales generados con otra IA:** obsoletos, sustituidos por los 01–06.
- **Explicaciones didácticas** (qué es un platform channel, cómo funciona un PTY…): conocimiento general que se puede volver a preguntar.
