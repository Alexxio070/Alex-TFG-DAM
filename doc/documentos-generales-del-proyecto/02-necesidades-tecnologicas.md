# Necesidades Tecnológicas: Linux System Companion

Este documento parte de **lo que el proyecto necesita** y, para cada necesidad, explica qué tipo de tecnología la cubre, cuál se ha elegido y qué alternativas se descartaron y por qué.

Cada bloque sigue el mismo esquema:

- **Necesidad:** qué problema hay que resolver.
- **Tipo de tecnología:** qué categoría de herramienta lo resuelve.
- **Elección:** la opción concreta.
- **Alternativas descartadas:** qué más se consideró y por qué no.

> **Resuelto (26/09/2026):** la normativa del proyecto cita "Android Studio, Kotlin, Java" para apps Android, pero el tutor ha aceptado Flutter. El plan B (Kotlin + Jetpack Compose, ver 1.1) ya no es necesario.

---

## 1. Aplicación móvil

### 1.1 Desarrollar la app Android
- **Necesidad:** una app con interfaz gráfica, gráficas en vivo, formularios de login y una terminal.
- **Tipo de tecnología:** framework de desarrollo móvil.
- **Elección:** **Flutter (lenguaje Dart).**
  - Interfaz declarativa por componentes (*widgets*) y recarga en caliente (*hot reload*): los cambios se ven al instante, lo que acelera mucho el aprendizaje.
  - Dispone de un emulador de terminal maduro (xterm.dart, ver 1.2), que es la pieza más difícil de la app.
  - Tecnología no vista en el grado, lo que aporta valor académico.
  - Permite escribir código nativo Kotlin donde haga falta mediante *platform channels* (ver 4.2).
- **Alternativas descartadas:**
  - *Kotlin + Jetpack Compose (nativo Android) — era el plan B si el centro no aceptaba Flutter:* ventajas reales (binding oficial de iroh, aunque para Android hay que compilarlo igualmente; acceso directo a Android, documentación oficial de Google), pero no tiene un emulador de terminal equivalente a xterm.dart. Las librerías de Termux funcionan, pero usan el sistema de vistas antiguo y están pensadas para terminales locales, lo que exigiría adaptarlas. Además, se ve parcialmente en el grado.
  - *React Native:* ecosistema de terminal menos maduro y un lenguaje más (JavaScript/TypeScript) sin ventaja clara para este proyecto. *(Desde la versión 0.76 la nueva arquitectura basada en JSI es la predeterminada, y desde la 0.82 es la única; sustituye al antiguo "puente" JavaScript.)*

### 1.2 Mostrar una terminal en el móvil
- **Necesidad:** interpretar el flujo de bytes de una shell remota (colores, cursor, secuencias de control) y dibujarlo en pantalla.
- **Tipo de tecnología:** librería de emulación de terminal (VT100/xterm).
- **Elección:** **xterm.dart** (licencia MIT). Soporta True Color, caracteres anchos y emojis, temas en tiempo de ejecución y teclados de móvil. Incluye ejemplos de terminal y de cliente SSH en unas 100 líneas.
  - **Estado del paquete:** estable, pero sin versiones nuevas desde la 4.0.0 (febrero de 2024). Se fija esa versión y se comprueba que funciona con la versión de Flutter usada en el proyecto.
- **Alternativas descartadas:**
  - *WebView con xterm.js:* funciona, pero mezcla una web dentro de la app y complica la integración con el teclado.
  - *Librerías de Termux en Kotlin:* ver 1.1.

### 1.3 Paquetes de apoyo en Flutter

| Necesidad | Paquete previsto | Motivo |
|---|---|---|
| Peticiones HTTP | `http` | Llamadas REST al agente |
| WebSocket | `web_socket_channel` | Terminal, métricas y eventos |
| Persistencia local de ajustes | `shared_preferences` | Guardar la dirección del agente, el modo de conexión y el resto de ajustes en el móvil |
| Gráficas | `CustomPainter` (del propio Flutter) | Gráficas de área de CPU, temperatura y RAM en vivo; sin dependencia extra |
| Terminal | `xterm` | Emulador de terminal (ver 1.2) |
| Iconos | `flutter_svg` | Iconos del diseño como SVG, con el color del tema |
| Abrir enlaces | `url_launcher` | Abrir en el navegador los enlaces de las notas |
| Guardar token y huella de forma segura | `flutter_secure_storage` | Usa el Keystore de Android |
| Descubrir el PC en la red local | `bonsoir` | Cliente mDNS/DNS-SD |
| Escanear QR | `mobile_scanner` | Registro y emparejamiento con el QR de la TUI |
| Notificaciones locales | `flutter_local_notifications` | Mostrar avisos del PC |
| Gestión de estado (ViewModels del patrón MVVM) | `provider` | Sencillo para empezar; Riverpod como alternativa si crece |

*Versiones y compatibilidad a verificar al empezar cada fase.*

---

## 2. Agente en el PC

### 2.1 Lenguaje y servidor
- **Necesidad:** un programa que se ejecute en segundo plano, acceda al sistema (procesos, PTY, D-Bus) y atienda peticiones del móvil de forma concurrente.
- **Tipo de tecnología:** lenguaje con buen acceso al sistema + framework web asíncrono.
- **Elección:** **Python 3.11+ con FastAPI y Uvicorn.**
  - Python tiene las librerías de sistema más maduras para este caso (psutil, dbus-fast, zeroconf, bindings de iroh) y permite desarrollar rápido.
  - FastAPI es asíncrono (*asyncio*): una misma instancia puede atender REST y varios WebSocket (terminal, métricas, eventos) a la vez sin bloquearse. Valida los datos automáticamente (con **Pydantic**, declarado como dependencia directa) y genera documentación de la API, útil para probar sin la app.
- **Alternativas descartadas:**
  - *Go:* muy buen rendimiento y binario único, pero menos librerías listas para D-Bus y un segundo lenguaje nuevo que aprender a la vez que Dart.
  - *Rust:* máximo rendimiento y acceso nativo a iroh, pero curva de aprendizaje demasiado alta para el plazo.
  - *Flask:* síncrono por defecto; los WebSocket y la concurrencia son más incómodos.

### 2.2 Pseudoterminal (PTY)
- **Necesidad:** ejecutar la shell real del usuario de forma interactiva, como si fuera un emulador de terminal.
- **Tipo de tecnología:** interfaz de pseudoterminal del sistema operativo.
- **Elección:** **módulos estándar `pty`, `os`, `fcntl` y `termios` de Python**, integrados con asyncio. No requieren dependencias externas.
- **Alternativas descartadas:**
  - *ptyprocess / pexpect:* cómodos, pero pensados para automatizar programas más que para una terminal interactiva asíncrona.
  - *Ejecutar comandos sueltos (subprocess):* no es interactivo, no carga el prompt ni los alias y no permite programas como `htop` o `vim`.

### 2.2.1 Sesiones persistentes de terminal (tmux)
- **Necesidad:** que un comando lanzado desde la app siga ejecutándose si la app se cierra, se limpia de recientes o se pierde la cobertura, y que el usuario pueda ver la misma terminal en la ventana del PC.
- **Tipo de tecnología:** multiplexor de terminal.
- **Elección:** **tmux**, instalado en el PC. Cada terminal es una sesión de tmux; la ventana del PC y la app son clientes de esa sesión. tmux aporta el buffer de salida y el reenganche sin código propio.
- **Alternativas:**
  - *Cliente propio en el agente (PTY propio, buffer circular y `companion attach`):* sin dependencias nuevas, pero hay que programar y mantener lo que tmux ya hace. **Aplazada a muy largo plazo** (ver `06-ideas-de-futuro.md`).
  - *Zellij:* alternativa equivalente, menos extendida; no se elige.
  - *PTY ligado a la conexión (diseño inicial):* el comando se corta al desconectar. Se mantiene solo como alternativa si falta tmux.
  - *Abrir una terminal gráfica y leer su salida:* los emuladores no ofrecen una forma genérica de leer su pantalla desde fuera.
- **Dependencia del sistema:** `tmux` no lo instala `pipx`. La versión mínima necesaria está **por determinar**; no se ha verificado la licencia ni las opciones concretas de tmux.
- Diseño detallado en `../agente/terminal-sesiones-tmux.md`.

### 2.3 Métricas del sistema
- **Necesidad:** leer CPU, RAM, swap, discos, temperaturas, carga y procesos.
- **Tipo de tecnología:** librería de telemetría del sistema.
- **Elección:** **psutil.** Unifica la lectura de `/proc` y `/sys` con una API sencilla y muy probada.
- **Alternativas descartadas:** *leer `/proc` a mano:* más trabajo y más errores sin ventaja real.

### 2.4 Energía y sesión
- **Necesidad:** apagar, reiniciar, suspender, hibernar y bloquear la sesión sin privilegios de root.
- **Tipo de tecnología:** comunicación entre procesos del sistema (IPC).
- **Elección:** **D-Bus con la librería dbus-fast**, hablando con **systemd-logind**. Es la interfaz oficial para estas acciones desde un usuario normal y respeta las políticas de polkit.
- **Alternativas descartadas:**
  - *Ejecutar `systemctl` o `loginctl` con subprocess:* funciona, pero es más frágil (parseo de texto, errores menos claros). Útil como plan B.
  - *dbus-python:* más antiguo, no asíncrono.

### 2.5 Ejecutar acciones rápidas
- **Necesidad:** lanzar comandos guardados en segundo plano sin bloquear el agente, con tiempo máximo, captura de la salida y posibilidad de cancelarlos.
- **Tipo de tecnología:** ejecución asíncrona de procesos.
- **Elección:** **`asyncio.create_subprocess_shell`** (biblioteca estándar). Se integra con el resto del agente asíncrono, permite leer la salida mientras se ejecuta y cortar el proceso (SIGTERM → SIGKILL) si supera el tiempo máximo, reutilizando la lógica del gestor de procesos.
  - **Importante:** el proceso que devuelve es la shell (`/bin/sh`), no el comando, así que `terminate()` y `kill()` solo matarían la shell y sus procesos hijos podrían seguir vivos. Por eso el comando se lanza con `start_new_session=True` (su propio grupo de procesos) y las señales se envían a todo el grupo con `os.killpg`.
- **Alternativas descartadas:**
  - *`subprocess.run`:* bloquea el agente mientras dura el comando.
  - *Colas de tareas (Celery, RQ):* requieren un broker externo; excesivo para ejecuciones de un solo usuario.

### 2.6 Interfaz del agente en el PC (TUI y comandos)
- **Necesidad:** manejar el agente desde el PC: configuración inicial y QR de registro, QR de emparejamiento, instalar o quitar el servicio, estado, cambiar la contraseña, cerrar todas las sesiones, notas del espacio compartido y exportaciones de la base de datos. Además, dos comandos que no puede lanzar una persona desde una interfaz: `companion serve` (lo arranca systemd) y `companion notify "mensaje"` (scripts y *hooks*).
- **Tipo de tecnología:** framework de interfaz de texto (TUI) y framework de CLI.
- **Elección (decidida el 12/10/2026):**
  - **Textual** para la TUI: al escribir `companion` se abre una interfaz con botones. Es un framework de Python para aplicaciones de terminal (licencia MIT), con widgets como `Button` y una API de *workers* para tareas largas o de red sin bloquear la interfaz.
  - **Typer** solo para `companion serve` y `companion notify` (basado en Click, que va integrado dentro de Typer desde la versión 0.26).
  - **qrcode** para dibujar el QR en la terminal (licencia BSD; `print_ascii()` lo genera con caracteres de texto).
- **Alternativas descartadas:**
  - *Solo CLI con Typer:* era el diseño anterior; el autor prefiere botones para no tener que recordar comandos.
  - *curses* (estándar de Python): de bajo nivel, hay que dibujar a mano cada elemento.
  - *urwid:* librería de interfaces de terminal más antigua y con menos componentes listos para usar.
  - *segno* en lugar de qrcode: también válida; qrcode es suficiente.
- *Versiones a verificar al empezar la fase.*

---

## 3. Comunicación

### 3.1 Protocolo de comunicación entre app y agente
- **Necesidad:** peticiones puntuales (login, apagar, guardar una nota) y flujos continuos (terminal, métricas, avisos).
- **Tipo de tecnología:** API HTTP + canal bidireccional persistente.
- **Elección:** **REST (HTTP/JSON)** para lo puntual y **WebSocket** para lo continuo. Ambos los ofrece FastAPI de forma nativa; para WebSocket hay que instalar además el paquete `websockets`.
- **Alternativas descartadas:**
  - *gRPC:* potente, pero añade generación de código y complejidad innecesaria.
  - *MQTT:* requiere un broker intermedio.

### 3.2 Descubrimiento en red local
- **Necesidad:** que la app encuentre el PC en la Wi-Fi de casa sin escribir la IP.
- **Tipo de tecnología:** mDNS / DNS-SD (Zeroconf).
- **Elección:** **zeroconf** (Python) para anunciar el servicio y **bonsoir** (Flutter) para encontrarlo. Es el mismo estándar que usan impresoras y Chromecast.
- **Alternativas descartadas:** *broadcast UDP propio:* reinventar un estándar existente.
- **Nota sobre Android 17 (`ACCESS_LOCAL_NETWORK`):** detalle y estado en `01-memoria-tecnica.md` §10.

### 3.3 Acceso desde fuera de casa
- **Necesidad:** conectar desde 4G/5G u otra red sin abrir puertos del router, sin VPN y sin instalar nada más en el móvil.
- **Tipo de tecnología:** librería P2P con travesía de NAT y relé de respaldo.
- **Elección:** **iroh (1.x).** Identifica cada equipo por su clave pública. La conexión empieza a través de un relé cifrado y después iroh intenta convertirla en directa atravesando el NAT; si no lo consigue, sigue por el relé. Ofrece bindings oficiales para Python (agente) y Kotlin y relés públicos gratuitos (según iroh, solo para desarrollo y uso personal, con límite de tráfico; suficientes para el TFG). Licencia MIT/Apache-2.0.
  - **Versiones (consultadas el 02/10/2026):** núcleo 1.3.0 (28/09/2026); bindings de Python y Kotlin 1.1.0 (16/07/2026). El paquete de Kotlin publicado en Maven no incluye Android: para Android hay que compilarlo desde el código fuente con Rust y el NDK (docs.iroh.computer/languages/kotlin). Oficialmente solo se soportan aarch64 y armv7; x86_64 se puede compilar pero no está soportado, así que la prueba de concepto se hace en el móvil físico. El de Python, en Linux, solo tiene paquetes `manylinux_2_28` (glibc 2.28 o superior, x86_64 y aarch64): no hay versión para musl ni para ARM de 32 bits.
- **Alternativas descartadas:**
  - *Tailscale / WireGuard:* obliga a instalar y configurar una app VPN en el móvil.
  - *WebRTC con STUN/TURN propios:* exige programar la señalización y alojar y pagar servidores. Queda como **respaldo** solo si iroh da problemas reales (decisión del 27/09/2026).
  - *Relé propio:* exige programar el cifrado de extremo a extremo y mantener un servidor indefinidamente.
  - *Cloudflare Tunnel:* requiere cuenta y dominio, y el cifrado TLS termina en Cloudflare.
  - *Abrir puertos del router:* contradice el requisito de configuración mínima y expone el agente a Internet.

---

## 4. Integración con Android

### 4.1 Mantener la conexión en segundo plano
- **Necesidad:** recibir notificaciones del PC y mantener el túnel aunque la app esté minimizada.
- **Tipo de tecnología:** servicio en primer plano de Android (*foreground service*) + notificaciones locales.
- **Elección:** **servicio en primer plano** (el mismo que mantiene el túnel iroh) y `flutter_local_notifications`. La implementación concreta (servicio en Kotlin o paquete de Flutter para servicios en primer plano) se decide en la fase 8.
  - **Requisitos de Android:** pedir el permiso `POST_NOTIFICATIONS` en tiempo de ejecución (Android 13+) y declarar el tipo del servicio (obligatorio para apps con `targetSdk` 34 o superior). No se usará `dataSync`, que en apps con `targetSdk` 35 o superior se detiene tras 6 horas cada 24. Candidato: `connectedDevice`, que exige declarar en el manifiesto el permiso `FOREGROUND_SERVICE_CONNECTED_DEVICE` y cumplir alguna de las condiciones de Android; para una conexión por red basta con declarar uno de `CHANGE_NETWORK_STATE`, `CHANGE_WIFI_STATE` o `CHANGE_WIFI_MULTICAST_STATE` (las demás alternativas son de NFC, infrarrojos, Bluetooth, UWB o USB). *Pendiente de revisión:* se confirma en la fase 8.
- **Alternativas descartadas:** *Firebase Cloud Messaging:* requiere cuenta de Firebase y un servidor intermediario que envíe los avisos.

### 4.2 Usar iroh desde Flutter
- **Necesidad:** llamar a la librería iroh desde la app. iroh no tiene binding oficial para Flutter.
- **Tipo de tecnología:** puente entre Flutter y código nativo.
- **Elección (pendiente de revisión, se decide al empezar la fase 2):**
  - *Opción A, diseño actual:* **platform channels (MethodChannel)** con un módulo Kotlin mínimo (abrir y cerrar túnel) sobre el binding oficial de Kotlin. Es el mecanismo estándar de Flutter, pero el binding publicado no incluye Android: hay que compilar iroh-ffi desde el código fuente con Rust y el NDK.
  - *Opción B:* plugin **`iroh_flutter`** de pub.dev (1.0.3, 07/08/2026, comunitario, no de n0), que compila el núcleo Rust automáticamente con cargokit y expone la API de iroh en Dart.
  - Las dos opciones necesitan Rust y el NDK instalados, así que esa ya no es una razón para descartar la vía Rust. Hay que elegir con la prueba de concepto: cuál compila y funciona antes en el móvil físico.
- **Otra alternativa:** *flutter_rust_bridge con el núcleo Rust de iroh, escrito a mano:* más trabajo que la opción B.

---

## 5. Seguridad

### 5.1 Cifrado del tráfico
- **Necesidad:** que nadie pueda leer ni modificar el tráfico, incluida la terminal.
- **Tipo de tecnología:** TLS con certificado autofirmado y fijado (*certificate pinning*).
- **Elección:** **TLS 1.3** con un certificado generado desde la TUI en la configuración inicial (librería `cryptography`). La app guarda su huella al escanear el QR. Dentro del túnel iroh (que ya cifra con QUIC) se mantiene el mismo TLS, así que la seguridad no depende del modo de conexión.
- **Alternativas descartadas:** *certificados de una autoridad pública (Let's Encrypt):* requieren dominio público; no aplica a un PC doméstico.

### 5.2 Autenticación
- **Necesidad:** que solo el propietario pueda usar el agente.
- **Tipo de tecnología:** contraseña con hash + tokens de sesión.
- **Elección:** **contraseña con Argon2** (`argon2-cffi`) y **tokens de sesión opacos** (aleatorios) guardados con hash en SQLite. Se pueden revocar al instante (botón «Cerrar todas las sesiones» de la TUI).
- **Alternativas descartadas:**
  - *JWT:* no se pueden revocar hasta que caducan; con un único dispositivo no aportan nada frente a tokens opacos.
  - *2FA (TOTP):* descartado para mantener la configuración mínima; se compensa con límite de intentos y contraseña robusta.

---

## 6. Persistencia

### 6.1 Base de datos
- **Necesidad:** guardar de forma persistente y relacionada los usuarios, sesiones, intentos de login, grupos, acciones rápidas, ejecuciones, reglas de alerta, notificaciones y notas (9 tablas; diseño en 01-memoria-tecnica.md, sección 6).
- **Tipo de tecnología:** base de datos relacional embebida.
- **Elección:** **SQLite** con el módulo estándar `sqlite3`, en `~/.local/share/companion/companion.db`, creada con el script `agent/schema.sql`. Sin servidor que instalar ni mantener, con transacciones, claves foráneas y borrado en cascada. SQLite trae las claves foráneas desactivadas por defecto, así que el agente ejecuta `PRAGMA foreign_keys = ON` en cada conexión; sin eso no se aplican ni las claves foráneas ni el `ON DELETE CASCADE`.
- **Alternativas descartadas:**
  - *MySQL / PostgreSQL:* requieren un servidor aparte; excesivo para un agente de un solo usuario y contrario a la instalación mínima.
  - *Firebase:* los datos saldrían del PC a un servicio externo, en contra del diseño sin servidores de terceros.
  - *Todo en JSON:* sin relaciones ni transacciones; riesgo de corrupción con escrituras concurrentes.

### 6.2 Acceso a los datos
- **Necesidad:** que el resto del agente no dependa de cómo se guardan los datos y que el acceso esté organizado en clases.
- **Tipo de tecnología:** patrón repositorio.
- **Elección:** **una clase repositorio por entidad** (`UsuarioRepository`, `GrupoRepository`, `AccionRepository`…) con consultas SQL parametrizadas. Los servicios de negocio solo usan los repositorios.
- **Alternativas descartadas:** *ORM (SQLAlchemy):* añade otra herramienta que aprender; con 9 tablas sencillas, SQL directo en repositorios es más claro y más fácil de explicar en la memoria.

### 6.3 Configuración
- **Necesidad:** ajustes editables a mano (puertos, relés, umbrales por defecto).
- **Elección:** fichero **TOML** en `~/.config/companion/config.toml` (lectura con `tomllib`, estándar desde Python 3.11). `tomllib` solo lee TOML; si la TUI tiene que escribir el fichero, hace falta el paquete `tomli-w`.
- **Alternativas descartadas:** *guardarlo en la BD:* menos cómodo de editar y de documentar.

---

## 7. Ejecución y distribución

### 7.1 Ejecutar el agente en segundo plano
- **Necesidad:** que el agente arranque solo y se recupere si falla.
- **Tipo de tecnología:** gestor de servicios del sistema.
- **Elección:** **servicio de usuario de systemd**, con *linger* opcional para que arranque sin iniciar sesión (necesario para el reinicio remoto).
- **Alternativas descartadas:** *autostart del escritorio (.desktop):* solo arranca con sesión gráfica; *cron `@reboot`:* no reinicia el agente si falla.

### 7.2 Instalar el agente
- **Necesidad:** instalación sencilla en cualquier distribución.
- **Tipo de tecnología:** gestor de paquetes de aplicaciones Python.
- **Elección:** **pipx.** Crea un entorno aislado automáticamente y usa el Python de la distribución. El binding de iroh (ver 3.3) solo publica paquetes para Linux `manylinux_2_28` y no publica código fuente, así que el agente no es compatible con distribuciones basadas en musl (como Alpine). Las otras dependencias compiladas (cryptography, argon2) sí tienen paquetes para musl.
- **Dependencias del sistema:** `pipx` solo instala paquetes de Python. `tmux` y la terminal gráfica del usuario se instalan con el gestor de la distribución (ver 2.2.1).
- **Alternativas descartadas:**
  - *PyInstaller:* el binario queda ligado a la glibc de la máquina de compilación.
  - *`pip install` directo:* bloqueado en distribuciones modernas fuera de entornos virtuales.
  - *Flatpak / Snap:* para acceder al PTY del sistema y a D-Bus habría que desactivar su aislamiento, lo que anula su ventaja.
  - *Paquetes nativos (.deb, AUR…):* uno por distribución; trabajo futuro.

### 7.3 Distribuir la app
- **Necesidad:** que el usuario instale la app fácilmente.
- **Tipo de tecnología:** distribución de APK.
- **Elección:** **APK en las releases del repositorio.**
- **Alternativas descartadas (para el TFG):** *Google Play* (requiere cuenta de desarrollador y revisión) y *F-Droid* (proceso de inclusión largo). Ambas quedan como trabajo futuro.

---

## 8. Calidad: arquitectura, versiones y pruebas

### 8.1 Organización del código
- **Necesidad:** capas diferenciadas y código mantenible (requisito del proyecto).
- **Tipo de tecnología:** patrones de arquitectura.
- **Elección:**
  - **App:** patrón **MVVM** (vistas → ViewModels con `provider` → repositorios → servicios de red). Cada repositorio tiene una versión simulada para desarrollar pantallas sin el agente.
  - **Agente:** capas **rutas de la API → servicios → repositorios → modelos**.
- **Alternativas descartadas:** *BLoC (Flutter):* más potente pero con más código repetitivo; excesivo para quien empieza.

### 8.2 Control de versiones
- **Necesidad:** historial del trabajo y uso adecuado de ramas y commits (requisito del proyecto).
- **Elección:** **Git** con un repositorio (`App-movil/` + `agent/`), ramas `main` / `feature/*` (sin `develop` ni etiquetas) y commits convencionales. Alojado en GitHub, que además sirve para publicar el APK en *releases*.
- **Alternativas descartadas:** *dos repositorios separados:* complica mantener sincronizadas app y agente.

### 8.3 Pruebas automáticas
- **Necesidad:** comprobar que la lógica funciona y no se rompe al añadir cambios.
- **Elección:** **pytest** en el agente (repositorios, reglas de negocio, autenticación, reglas de alerta) y **flutter_test** en la app (validaciones de formularios). Los tests de la API usan `httpx2` en vez de `httpx`, que Starlette marca como obsoleto.
- **Alternativas descartadas:** *unittest* (estándar, pero más verboso que pytest).

### 8.4 Entorno de pruebas
- **Necesidad:** probar la app aunque la red del centro bloquee la comunicación entre el móvil y el PC.
- **Tipo de tecnología:** conexión directa entre dispositivos sin red externa.
- **Elección:**
  - **`adb reverse`** por USB (método principal): la app se conecta a `127.0.0.1` y llega al agente del portátil por el cable;
  - **emulador de Android Studio** (`10.0.2.2` apunta al anfitrión; no sirve para probar iroh, ver 3.3);
  - **punto de acceso del móvil** para probar como LAN real.
- **Alternativas descartadas:** *usar la red del centro:* no garantizada; *máquina virtual accesible por red:* mismo problema de red.
