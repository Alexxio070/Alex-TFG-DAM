# Resumen de la conversación de diseño: decisiones y contexto

Este documento complementa a los archivos 01–06. Aquellos describen **qué** es el proyecto; este recoge **por qué** se ha llegado a cada decisión, qué se descartó y con qué motivo, qué queda pendiente y cómo quiere trabajar el autor. Sirve como contexto para cualquier conversación futura sobre el proyecto.

---

## 1. Quién soy y qué es esto

- Estudiante de **DAM (Desarrollo de Aplicaciones Multiplataforma)**. Este es mi proyecto final.
- **No tengo experiencia en desarrollo Android ni en Flutter.** En clase he visto Kotlin a un nivel muy básico que apenas aporta a este proyecto. Voy a aprender sobre la marcha, así que necesito metas pequeñas y asequibles y explicaciones claras.
- Mi entorno personal es **KDE Plasma** sobre Linux.
- El punto de partida fueron tres documentos generados con otra IA (memoria técnica, justificación del stack y un "system context" en inglés). Los revisamos, tenían incoherencias entre sí y errores técnicos, y se rehicieron por completo en los documentos 01–06.

---

## 2. La idea central (lo más importante)

**Linux System Companion es una app para administrar mi PC Linux desde el móvil cuando NO estoy delante de él**, desde casa o desde cualquier sitio.

**Criterio de alcance:** si una función solo tiene sentido estando delante o cerca del PC, **queda fuera del TFG**. Este criterio decidió qué se mantenía y qué se descartaba.

**Frase para la defensa:** *KDE Connect es una herramienta para cuando estás cerca del PC; Linux System Companion es para cuando no lo estás.*

**Requisito de experiencia de usuario:**
- En el móvil, **solo descargar la app**; nada de instalar VPNs ni otras apps.
- En el PC se aceptan dependencias.
- **Nunca configurar el router.**
- Flujo deseado: instalar agente → configurar credenciales → instalar app → iniciar sesión → conectar desde cualquier parte.

**Filosofía de desarrollo:** la primera versión (beta) debe tener **pocas funciones, pero todas funcionando**: una base sólida sobre la que ampliar. Desde el 12/10/2026 la beta es mínima: la interfaz definitiva con *placeholders*, las métricas y la conexión por iroh, sin login.

---

## 3. Registro de decisiones

### 3.1 Tecnología

| Decisión | Elegido | Motivo | Descartado |
|---|---|---|---|
| Framework móvil | **Flutter** (aceptado por el tutor el 26/09/2026) | Se valora usar tecnología no vista en clase; xterm.dart resuelve la terminal (la pieza más difícil); *hot reload* ayuda a aprender | Kotlin + Compose: más fácil para iroh (binding oficial), pero sin emulador de terminal equivalente. Era el plan B; ya no es necesario |
| Agente PC | Python 3.11 + FastAPI | Mejores librerías de sistema; asíncrono | Go, Rust (curva), Flask (síncrono) |
| Acceso remoto | **iroh**, túnel local (patrón dumbpipe), **fase 2 (mediados de noviembre – Navidad)**, adelantado el 02/10/2026 por ser la parte más crítica | Cero configuración para el usuario, sin servidores propios, y si falla se cae automáticamente a "solo LAN" | Tailscale (obliga a app VPN en el móvil), relé propio (el peor: cifrado propio y servidor que pagar), Cloudflare Tunnel. WebRTC con STUN/TURN (servidores propios) **queda como respaldo** solo si iroh da problemas reales (27/09/2026) |
| Puente Flutter ↔ iroh | Platform channel mínimo en Kotlin: `openTunnel` / `closeTunnel` (*pendiente de revisión*) | Flutter no sabe que iroh existe; usa el mismo código que en LAN | El binding de Kotlin publicado no incluye Android y hay que compilarlo con Rust y el NDK igualmente, así que el plugin `iroh_flutter` (pub.dev) vuelve a ser candidato. Se decide al empezar la fase 2 |
| Tokens | Opacos, con hash en SQLite | Revocables al instante (botón «Cerrar todas las sesiones») | JWT (no revocables; innecesarios con un solo dispositivo) |
| BD | SQLite con `sqlite3` + patrón repositorio + `schema.sql` | Sencillo, sin servidor, cumple la normativa. El tutor confirmó que SQLite local es válido (28/09/2026) | SQLAlchemy (excesivo), MySQL, Firebase |
| Instalación del agente | **pipx** | Usa el Python de la distro; evita problemas de glibc (me recomendaron alejarme de glibc) | PyInstaller (atado a la glibc de compilación), pip directo (bloqueado en distros modernas), Flatpak (su aislamiento impide PTY y D-Bus) |
| Servicio | systemd de usuario con `default.target` + linger opcional | Al quitar lo gráfico, no hace falta la sesión gráfica | `graphical-session.target` (propuesta inicial, se cambió) |
| Herramienta del PC | **TUI con botones (Textual)** al escribir `companion` (12/10/2026); **Typer** solo para `companion serve` y `companion notify`; QR con `qrcode` | Botones en lugar de comandos que recordar; `serve` y `notify` los lanzan systemd y los scripts | Solo CLI con Typer (diseño anterior), curses (bajo nivel), urwid |
| Arquitectura app | MVVM con provider + repositorios simulados | Capas claras (requisito); permite trabajar sin el agente | BLoC (demasiado para quien empieza) |

### 3.2 Seguridad
- **TUI en lugar de CLI (12/10/2026):** al escribir `companion` se abre una TUI con botones para todo (configuración inicial y QR de registro, QR de emparejamiento, servicio, estado, contraseña, cerrar sesiones, notas y exportaciones). Antes prefería CLI; cambié de opinión.
- **Registro por QR (12/10/2026):** la TUI muestra un QR con la dirección, la huella, el identificador iroh y un código de registro de un solo uso con caducidad corta. La app lo escanea, muestra "Emparejado, se necesita crear autenticación" y abre un diálogo de usuario y contraseña. El modo registro se cierra tras la primera cuenta. **Va en la fase 9 (12/10/2026);** hasta entonces el usuario se crea desde la TUI.
- **TLS autofirmado con certificate pinning.** La huella llega en el QR (hasta la fase 9, se compara a ojo con la que muestra la TUI).
- **2FA descartado** porque choca con la configuración mínima. Se compensa con contraseña robusta, límite de intentos y revocación.
- **Un solo dispositivo.** Multi-dispositivo como idea futura.
- **El agente nunca usa root ni sudo.** Para operaciones de root, la app avisa de que hay que usar la terminal.

### 3.3 Terminal
- Se lanza `$SHELL -l` de forma genérica. **No hay que programar soporte por shell**: el PTY funciona igual con Bash, Zsh y Fish. **Shell probada oficialmente: Zsh.**
- La paleta y la fuente las pone el móvil, no la shell. Hay que incluir una Nerd Font.
- Temas de terminal: "si da tiempo".

### 3.4 Notificaciones (dentro del TFG)
- Quiero recibir en el móvil avisos del PC, por ejemplo cuando **Claude Code termine de trabajar**, cuando un proceso de terminal termine o arranque bien, o si hay **CPU o RAM elevadas**.
- Diseño:
  - `companion notify "mensaje"` por socket Unix (sirve para scripts y *hooks* de Claude Code);
  - reglas de alerta por umbral;
  - servicio en primer plano en Android que reutiliza el del túnel iroh.
- **Sin Firebase.** Funciona también en LAN, sin iroh.

### 3.5 Espacio compartido (dentro del TFG, decidido el 12/10/2026)
- **Sustituye al explorador y la transferencia de archivos**, que pasan a ideas de futuro (06).
- Un espacio común entre el móvil y el PC donde dejar **notas de texto y enlaces** para pasar información de un lado a otro. CRUD desde la app y botones de la TUI en el PC; la app pide las notas al abrir la pantalla y al recargar (sin actualización al momento: es una app para usar lejos del PC). Si los dos lados editan la misma nota, gana el último cambio.
- **Imágenes: aún pensándolo.** Fuera del alcance confirmado hasta que se decida.
- Va en la fase 9, después del CRUD (fase 7), cuyo patrón reutiliza.
- **Pantalla de Notas definitiva (12/10/2026):** lista de notas con tarjetas, búsqueda, formulario de crear/editar y borrado, tal como describe el Módulo F. Sustituye al campo de texto único del prototipo v1, que queda descartado. Detalle en `../ui/ui-v2/ESPECIFICACION_NOTAS.md`; el prototipo inicial se conserva como histórico en `../ui/ui-v1/`.

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
- **Datos:** un JSON `companion-datos-AAAAMMDD-HHMM.json` con una sección por tabla, sin `sesion`, `intento_login` ni el hash de la contraseña. Descartados CSV (un archivo por tabla, pierde tipos) y SQL con `INSERT` (mezcla datos y estructura).
- **Estructura:** carpeta `companion-estructura-AAAAMMDD-HHMM/` con `tablas.sql`, `indices.sql`, `vistas.sql` y `triggers.sql`, leídos de `sqlite_schema`. Los *joins* no se guardan en la BD: las relaciones son las claves foráneas de `tablas.sql`. El diseño no tiene vistas ni triggers, así que esos archivos llevan un comentario que lo explica.

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
- **Campo de texto único compartido para Notas (12/10/2026):** era la pantalla del prototipo v1. Se descartó porque no cubría notas de texto y enlaces con CRUD y búsqueda. Lo sustituye la lista de notas de `../ui/ui-v2/`.

**Descartado por complejidad o por chocar con otros requisitos:**
- Wake-on-LAN;
- 2FA;
- alertas con Firebase;
- soporte para otros escritorios o gestores de ventanas (solo KDE; expandir en el futuro);
- iOS (muy a futuro, fuera del alcance).

---

## 5. Planificación (resumen; detalle en 04)

**Calendario (02/10/2026, revisado el 12/10/2026):**
- **Beta v0.1 en Navidad:** mínima: interfaz definitiva con *placeholders*, métricas y conexión por iroh, sin login.
- **Calendario apretado:** la seguridad y la instalación pasan detrás de la beta, así que la terminal termina a finales de febrero y las fases 8–10 coinciden con la redacción de la memoria en mayo.
- **Hito de febrero:** versión funcional con la app conectándose al PC a través de iroh, la terminal y las gráficas de rendimiento. *Fecha exacta pendiente de revisión.*
- **Defensa:** primera semana de junio de 2027. *Fecha oficial de entrega de la memoria pendiente de revisión.*

**Criterios:**
- lo más arriesgado primero: iroh justo después de las métricas, para descubrir pronto si da problemas;
- después, lo obligatorio y lo de más impacto en la nota;
- fases difíciles intercaladas con fáciles para no dejar lo importante al final;
- lo de menor impacto, al final como "si da tiempo".

**Beta v0.1 (Navidad):**
- Fase 0: preparación y aprender Flutter.
- Fase 1: interfaz definitiva con *placeholders* y métricas (mediados de octubre – mediados de noviembre).
- Fase 2: conexión remota con iroh (mediados de noviembre – Navidad): prueba de concepto, integración sin servicio en primer plano y pruebas primero en casa (misma Wi-Fi, datos móviles, UDP bloqueado, cambio de red y reinicio) y después en una red restrictiva. Hasta la fase 3 el agente solo expone métricas.
- **Sin login en la beta:** el agente solo expone métricas de solo lectura y se arranca a mano.
- **La beta NO necesita cumplir los mínimos de DAM.**

**Después de la beta:**
- Fase 3: seguridad (enero): TUI mínima que crea el usuario y login. Va antes de la terminal porque esta da acceso a la shell.
- Fase 4: terminal (mediados de enero – finales de febrero), para el hito de febrero.
- Fase 5: instalación con pipx y servicio (instalado desde la TUI).
- Fase 6: energía y procesos.
- Fase 7: CRUD de acciones rápidas (requisito obligatorio) y botones de exportación de la TUI.
- Fase 8: notificaciones, reglas y servicio en primer plano.
- Fase 9: mDNS, QR de emparejamiento, registro por QR y espacio compartido (notas de texto y enlaces; imágenes aún pensándolo).
- Fase 10: pulido.

**Orden de recorte si voy con retraso:** reglas de alerta → mDNS → hibernar y ordenación de procesos → registro por QR. Si iroh no funciona, se aplica el plan B en la fase 2 (solo LAN). **Nunca se recortan:** iroh (o su plan B documentado), terminal, CRUD, login y TLS.

---

## 6. Entorno de pruebas

La red del centro está muy blindada y probablemente el móvil no pueda llegar al PC por ella. Solución sin depender de ninguna red:
- **USB + `adb reverse tcp:8443 tcp:8443`** como método principal (la app se conecta a `127.0.0.1:8443`, la misma dirección que usará el túnel de iroh);
- emulador de Android Studio (`10.0.2.2` = anfitrión);
- punto de acceso del móvil para probar como LAN real;
- repositorios simulados en la app.

Fuera de casa, iroh no necesita abrir puertos de entrada: basta con que salga HTTPS (TCP 443 con WebSocket) hacia los relés, y si el UDP está bloqueado todo va por el relé. *Pendiente de revisión:* confirmar con el centro que deja salir ese tráfico.

Para la defensa: USB o punto de acceso, más un vídeo de respaldo.

---

## 7. Forma de trabajar con Claude

- **Proyecto de Claude (organización actual):**
  - los documentos 01–07 están en la carpeta "Documentacion TFG" del proyecto y son el contexto base de todos los hilos;
  - el repositorio de GitHub (Alexxio070/Alex-TFG-DAM) está conectado y tiene una copia de estos documentos en `docs/`;
  - el trabajo se organiza en hilos con prefijo **PROYECTO:** (desarrollo del TFG), **APRENDIZAJE:** (unidades de estudio) y **PREGUNTAS:** (dudas sueltas);
  - el hilo "Proyecto: Trabajo del repositorio" es el único que hace commits y PRs en el repo.
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

## 9. Pendientes inmediatos

1. ~~Preguntar al tutor por escrito~~ **Resuelto:** Flutter aceptado (26/09/2026), el agente en Python es parte fundamental del proyecto (02/10/2026) y la política de IA está aclarada (28/09/2026, ver sección 8).
2. Averiguar la **fecha oficial de entrega de la memoria** y la fecha exacta del hito de febrero, y ajustar el plan. *Pendiente de revisión.*
3. ~~Decidir cómo se crea el usuario~~ **Resuelto (12/10/2026):** registro por QR desde la TUI y la app, en la fase 9.
4. ~~Revisar las licencias marcadas como "verificar" en el documento 05~~ **Resuelto (02/10/2026):** licencias comprobadas; iroh-ssh-android es GPL-3.0 e iroh-android-native no declara licencia, así que de ninguno de los dos se puede copiar código.
5. Preguntar en el centro cómo está montada la red: si deja salir HTTPS con WebSocket hacia los relés de iroh o si hay un proxy que inspeccione el tráfico. *Pendiente de revisión* (antes de la prueba en red restrictiva de la fase 2).
6. Confirmar el tipo del servicio en primer plano (`connectedDevice` como candidato). *Pendiente de revisión* (fase 8).
7. Elegir cómo usar iroh desde Flutter: binding de Kotlin compilado desde el código fuente + *platform channel*, o el plugin `iroh_flutter`. *Pendiente de revisión* (al empezar la fase 2).
8. Decidir si las **imágenes** entran en el espacio compartido. *Aún pensándolo* (antes de la fase 9).

---

## 10. Qué NO está en estos documentos

- **La normativa oficial de requisitos mínimos del proyecto de DAM.** Aquí solo está resumida (03, sección 2) y cruzada con el plan (04, tabla final). **Súbela también al proyecto** tal cual la da el centro.
- **Los tres documentos originales generados con otra IA.** Están obsoletos y sustituidos por los 01–06; no hace falta conservarlos.
- **Explicaciones didácticas** que se dieron en la conversación (qué es un platform channel, cómo funciona un PTY, etc.). Son conocimiento general que se puede volver a preguntar.
