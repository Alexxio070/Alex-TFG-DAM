# Memoria Técnica: Linux System Companion

**Título del proyecto:** Linux System Companion — Administración remota de tu PC Linux desde el móvil
**Tipo:** Proyecto final de DAM — aplicación móvil Android con backend propio
**Plataformas:** Android (cliente) — GNU/Linux con systemd (agente)
**Entorno de referencia (probado):** Android 10+ · KDE Plasma 6 · systemd · Python 3.11+
**Estado:** Propuesta / Memoria de diseño

---

## 0. Decisiones

| Decisión | Estado |
|---|---|
| Aceptación de Flutter por el centro (la normativa cita "Android Studio, Kotlin, Java") | **Resuelta (26/09/2026):** el tutor acepta Flutter. El plan B (Kotlin + Jetpack Compose) ya no es necesario |
| Registro de usuario desde la app frente a creación por CLI | Pendiente de revisión (ver 5.1) |

---

## 1. Resumen

Linux System Companion es una herramienta de código abierto para **administrar un PC con GNU/Linux desde el móvil cuando no estás delante de él**, tanto desde la red de casa como desde fuera (4G/5G u otra Wi-Fi), sin configurar el router ni instalar nada más en el móvil.

El sistema tiene dos piezas:

- **Una app Android** hecha con Flutter.
- **Un agente en el PC** escrito en Python (FastAPI) que se ejecuta como servicio de usuario de systemd.

Las funciones principales son:

- una terminal remota que abre la shell real del usuario;
- la monitorización del sistema en vivo;
- la gestión de procesos;
- el control de energía y sesión;
- las acciones rápidas (comandos guardados y organizados en grupos, con historial de ejecuciones);
- la transferencia de archivos;
- las notificaciones del PC al móvil con reglas de alerta configurables.

La filosofía de diseño es: **solo se incluyen funciones que tienen sentido estando lejos del equipo**. Lo que únicamente es útil delante del PC (control multimedia, portapapeles, personalización del escritorio…) queda fuera del alcance y se recoge en *06-ideas-de-futuro.md*.

El desarrollo es incremental. Una primera **beta (v0.1)** ofrece un conjunto reducido de funciones completamente operativas, y las versiones posteriores amplían el sistema sobre esa base. La planificación está en *04-plan-de-fases.md*.

---

## 2. Motivación y valor diferencial

Las herramientas existentes cubren partes del problema, pero ninguna lo resuelve completo:

- **KDE Connect** está pensado para cuando estás *cerca* del PC y en la misma red local: control multimedia, portapapeles, notificaciones. No ofrece una terminal interactiva completa y fuera de la LAN necesita una VPN configurada por el usuario.
- **Clientes SSH móviles** (Termius, ConnectBot…) ofrecen terminal, pero requieren que el PC sea accesible desde Internet (abrir puertos, IP pública o VPN) y no incluyen monitorización, gestión de energía ni notificaciones de eventos.
- **Cockpit** ofrece administración web completa, pero no es una app móvil y exponerlo fuera de casa requiere configuración de red.

**Valor diferencial:** una única app que combina terminal real, monitorización, procesos, energía, acciones rápidas, archivos y avisos, y que funciona desde cualquier sitio con una configuración mínima.

> KDE Connect es una herramienta para cuando estás cerca del PC; Linux System Companion es una herramienta para cuando no lo estás.

---

## 3. Módulos funcionales

### Módulo A — Terminal remota
- El agente abre un **pseudoterminal (PTY)** y lanza la shell configurada del usuario (`$SHELL`) en modo login (`-l`), así que se cargan sus alias, variables y prompt (Starship, Oh My Zsh…).
- La app muestra la terminal con **xterm.dart**, que interpreta las secuencias ANSI, incluido color de 24 bits (True Color).
- Barra de teclas especiales (Ctrl, Alt, Tab, Esc, flechas) y redimensionado dinámico (`TIOCSWINSZ`).
- **Shells:** el agente lanza `$SHELL` de forma genérica; Bash, Zsh y Fish funcionan igual a través del PTY, sin código específico. **La shell probada oficialmente es Zsh.**
- **Nota:** la paleta de colores y la fuente las define el emulador del móvil, no la shell. La app incluye una Nerd Font para que los iconos de prompts como Starship se vean bien.

### Módulo B — Monitorización del sistema
- Uso de CPU (global y por núcleo), RAM, swap, discos, temperaturas, carga del sistema y tiempo encendido.
- Datos obtenidos con **psutil** (lee `/proc` y `/sys/class/hwmon`).
- Gráficas en vivo en la app.

### Módulo C — Energía y sesión
- Apagar, reiniciar, suspender e hibernar mediante **systemd-logind por D-Bus**.
- Bloquear la sesión gráfica abierta, por si se dejó el PC desbloqueado. Se usa `Session.Lock()` (o `LockSession(id)`) sobre la sesión del propio usuario, que no pide autorización; `LockSessions()` bloquea todas las sesiones y polkit exige permisos de administrador.
- Todas las acciones destructivas piden confirmación en la app.

### Módulo D — Gestión de procesos
- Lista de procesos en tiempo real con búsqueda, filtro y orden por CPU y memoria.
- Finalización en dos pasos: primero **SIGTERM** (cierre ordenado); si el proceso sigue vivo tras unos segundos, se ofrece **SIGKILL** (cierre forzado).
- El agente se ejecuta sin privilegios, así que **solo puede finalizar procesos del propio usuario**. La app lo indica claramente.

### Módulo E — Acciones rápidas (CRUD)
Comandos guardados, organizados en grupos, que se ejecutan con un toque desde el móvil. Por ejemplo:
- grupo "Proyecto" → acción "Actualizar repo" (`cd ~/proyecto && git pull`);
- grupo "Mantenimiento" → acción "Copia de seguridad" (`~/scripts/backup.sh`).

**Funciones:**
- **CRUD completo de grupos y de acciones:** crear, consultar, editar y borrar.
- **Ejecución en segundo plano** en el PC:
  - con tiempo máximo (al superarlo se corta con SIGTERM → SIGKILL). El comando se lanza en su propio grupo de procesos y la señal se envía a todo el grupo, porque la shell que lo ejecuta puede tener procesos hijos que, si no, seguirían vivos;
  - con una sola ejecución simultánea por acción;
  - con la salida recortada a un tamaño máximo.
- **Historial de ejecuciones** con estado (en curso, éxito, error, cortada por tiempo, cancelada), código de salida y salida del comando. Filtros por acción, estado y fechas; borrado individual o completo.
- **Estadísticas por acción:** número de ejecuciones, tasa de éxito, duración media y fecha de la última ejecución.
- **Búsqueda y ordenación:** por nombre, por grupo, por más usadas o por última ejecución.

**Reglas de negocio:**
- el nombre de una acción es único dentro de su grupo;
- al borrar un grupo con acciones, el usuario elige entre moverlas a "Sin grupo" o borrarlas;
- al borrar una acción se borra su historial.

**Validaciones:**
- nombre obligatorio (1–50 caracteres);
- comando obligatorio;
- tiempo máximo entre 1 y 3600 s;
- el directorio de trabajo debe existir y ser accesible.

Se valida en la app (respuesta inmediata) y en el agente (seguridad real).

**Seguridad:** una acción ejecuta comandos con los permisos del usuario, igual que la terminal. No amplía lo que puede hacer quien ya tiene acceso a la app.

**Pantallas de la app:**
1. **Lista de acciones**, agrupadas por grupo, con buscador, ordenación y botón "+".
2. **Formulario de grupo** (crear / editar).
3. **Formulario de acción** (crear / editar).
4. **Ficha de la acción:** datos, estadísticas, botón "Ejecutar" e historial reciente.
5. **Historial de ejecuciones** con filtros, y **detalle de ejecución** con estado, duración y salida del comando (opcionalmente mostrada con xterm.dart para conservar los colores).

**API del agente:**
```
GET    /grupos                         POST   /grupos
PUT    /grupos/{id}                    DELETE /grupos/{id}?modo=mover|borrar

GET    /acciones?grupo=&q=&orden=      POST   /acciones
GET    /acciones/{id}                  (incluye estadísticas)
PUT    /acciones/{id}                  DELETE /acciones/{id}
POST   /acciones/{id}/ejecutar         POST   /ejecuciones/{id}/cancelar

GET    /ejecuciones?accion=&estado=&desde=&hasta=
GET    /ejecuciones/{id}               DELETE /ejecuciones/{id}
DELETE /ejecuciones?accion=            (limpiar historial)
```

### Módulo F — Archivos
- Navegación por el sistema de archivos del PC.
- **Descarga** de archivos del PC al móvil y **subida** del móvil al PC (por defecto, a la carpeta de descargas del usuario).
- Los permisos los aplica el sistema operativo. Si una operación requiere permisos de administrador, la app indica que **las operaciones como root deben hacerse desde la terminal** (el agente nunca usa `sudo`).

### Módulo G — Notificaciones y reglas de alerta
- **Avisos manuales:** el comando `companion notify "mensaje"` envía una notificación al móvil desde cualquier script o programa. Ejemplos:
  - `make && companion notify "Compilación terminada"`;
  - un *hook* de Claude Code al terminar de trabajar.
- **Avisos de acciones rápidas:** opción "notificar al terminar" en cada acción.
- **Reglas de alerta (CRUD completo desde la app):** métrica (CPU, RAM, temperatura, disco), operador, umbral, duración sostenida, tiempo mínimo entre avisos y activa/inactiva. Ejemplo: "CPU > 90 % durante 2 minutos".
- **Historial de notificaciones** con búsqueda, filtros, marcar como leída y borrar.
- En el móvil, un **servicio en primer plano** mantiene la conexión abierta y muestra los avisos como notificaciones de Android. No se usa Firebase ni ningún servidor externo.
- **Requisitos de Android:**
  - desde Android 13 la app debe pedir el permiso `POST_NOTIFICATIONS` en tiempo de ejecución; sin él, los avisos no se muestran;
  - desde Android 14 hay que declarar el tipo del servicio en primer plano. No se usará `dataSync`, porque desde Android 15 el sistema lo detiene tras 6 horas cada 24. Candidato: `connectedDevice` (dispositivo externo conectado por red), que exige declarar en el manifiesto el permiso `FOREGROUND_SERVICE_CONNECTED_DEVICE` y al menos uno de `CHANGE_NETWORK_STATE`, `CHANGE_WIFI_STATE` o `CHANGE_WIFI_MULTICAST_STATE`. *Pendiente de revisión:* se confirma en la fase 8.

**API del agente:**
```
GET    /reglas                         POST   /reglas
PUT    /reglas/{id}                    DELETE /reglas/{id}
GET    /notificaciones?origen=&leida=&q=&desde=&hasta=
PATCH  /notificaciones/{id}            (marcar como leída)
DELETE /notificaciones/{id}            DELETE /notificaciones   (limpiar historial)
WS     /ws/events                      (avisos en tiempo real)
```

### Módulo H — Conectividad
- **En red local:** conexión directa, con autodescubrimiento del PC por **mDNS**.
- **Emparejamiento por QR:** la app escanea con la cámara el código que muestra la CLI.
- **Desde fuera de casa:** túnel P2P cifrado con **iroh** (ver 4.3).
- El resto de la app no distingue entre ambos modos: usa exactamente el mismo código de comunicación.

---

## 4. Arquitectura

### 4.1 Vista general

```
+------------------------------------------------------------------+
|                        APP ANDROID (Flutter)                     |
|   Vistas → ViewModels (provider) → Repositorios → Servicios red  |
|   xterm.dart · HTTP/REST · WebSocket · notificaciones locales    |
|------------------------------------------------------------------|
|  Kotlin (platform channel): túnel iroh + servicio en 1er plano   |
+------------------------------------------------------------------+
            |                                      |
   [ Red local (LAN) ]                  [ Fuera de casa (WAN) ]
   Conexión directa TLS                 Túnel iroh (QUIC cifrado):
   Descubrimiento mDNS                  empieza por un relé y pasa a
                                        directa si el NAT lo permite
            |                                      |
            +------------------+-------------------+
                               |
+------------------------------------------------------------------+
|                       AGENTE PC (Python)                         |
|   Rutas API (FastAPI) → Servicios → Repositorios → SQLite        |
|   PTY · psutil · dbus-fast · iroh · CLI "companion"              |
|   Socket Unix local para "companion notify"                      |
+------------------------------------------------------------------+
                               |
+------------------------------------------------------------------+
|                         GNU/LINUX                                |
|   /proc y /sys  ·  D-Bus (systemd-logind)  ·  systemd (usuario)  |
+------------------------------------------------------------------+
```

### 4.2 Arquitectura en capas

**App (patrón MVVM):**
- **Vistas:** pantallas y *widgets*; solo muestran datos y recogen acciones del usuario.
- **ViewModels:** estado de cada pantalla y lógica de presentación (gestionados con `provider`).
- **Repositorios:** punto único de acceso a los datos. Cada repositorio tiene una versión real (llama al agente) y una **versión simulada** con datos inventados, útil para desarrollar pantallas sin el agente.
- **Servicios de red:** cliente HTTP/WebSocket, gestión del token y del certificado fijado.

**Agente:**
- **Rutas de la API:** reciben peticiones, validan datos de entrada (Pydantic) y devuelven respuestas.
- **Servicios:** lógica de negocio (ejecución de acciones, evaluación de reglas de alerta, gestión de sesiones…).
- **Repositorios:** único punto de acceso a SQLite (`UsuarioRepository`, `GrupoRepository`, `AccionRepository`, `EjecucionRepository`, `ReglaAlertaRepository`, `NotificacionRepository`…).
- **Modelos:** clases de datos que representan cada entidad.

### 4.3 Comunicación
- **REST (HTTP/JSON):** peticiones puntuales, como login, energía, procesos, archivos y el CRUD de grupos, acciones, reglas y notificaciones.
- **WebSocket:** canales continuos para la terminal, las métricas en vivo y los eventos o notificaciones.
- En la beta las métricas se obtienen por consulta periódica REST (cada 1–2 s) por simplicidad.

### 4.4 Diseño del acceso remoto: túnel local
Para no duplicar código entre LAN y WAN, el acceso remoto funciona como un **túnel transparente**, siguiendo el patrón de la herramienta *dumbpipe* del proyecto iroh:

1. **En el PC,** el agente crea un punto de conexión iroh que reenvía todo lo que recibe a su propio servidor FastAPI local.
2. **En el móvil,** un pequeño módulo en Kotlin (binding oficial de iroh, que para Android hay que compilar desde el código fuente con Rust y el NDK) abre un puerto en `127.0.0.1` y reenvía las conexiones al PC a través de iroh.
3. **La parte Flutter** se conecta a `127.0.0.1:puerto` con el mismo código HTTP/WebSocket que en LAN. El TLS y el login siguen funcionando dentro del túnel.

iroh identifica a cada equipo por su clave pública. La conexión empieza a través de un servidor relé cifrado, que los dos equipos usan para intercambiar sus direcciones; después iroh intenta convertirla en directa atravesando el NAT y, si no lo consigue, sigue por el relé. Por defecto se usan los relés públicos gratuitos del proyecto (según iroh, solo para desarrollo y uso personal, con límite de tráfico y sin garantía de disponibilidad; suficientes para el TFG); opcionalmente pueden configurarse relés propios. Por defecto cada arranque genera una identidad nueva, así que el agente debe guardar su clave secreta (`SecretKey`) y cargarla al arrancar para conservar el mismo identificador.

*Pendiente de revisión (se decide al empezar la fase 2):* cómo usar iroh desde Flutter. El binding de Kotlin publicado en Maven no incluye Android: hay que compilarlo desde el código fuente con Rust y el NDK (docs.iroh.computer/languages/kotlin). La alternativa es el plugin `iroh_flutter` de pub.dev (comunitario, no de n0), que compila el núcleo Rust automáticamente; también necesita Rust y el NDK instalados.

El puente entre Flutter y Kotlin se limita a dos operaciones: *abrir túnel (identificador del PC) → puerto local* y *cerrar túnel*.

**Plan B:** si el acceso remoto no pudiera completarse, el sistema es plenamente funcional en red local. Las notificaciones tampoco dependen de iroh.

---

## 5. Seguridad

### 5.1 Configuración inicial y emparejamiento
El usuario ejecuta `companion setup` en el PC. Este comando:
- crea el usuario y una contraseña robusta, que se guarda con hash **Argon2**;
- genera un certificado TLS autofirmado propio del equipo;
- muestra los datos de conexión: dirección, huella del certificado y, cuando exista, el identificador iroh. Los muestra como texto y como código QR en la propia terminal.

**Alternativa pendiente de revisión — registro desde la app:** `companion setup` solo generaría el certificado y un **código de emparejamiento de un solo uso**. La app mostraría un formulario de registro con el código, el nombre de usuario y la contraseña (con confirmación y validación de robustez).

En la primera conexión, la app guarda la huella del certificado (**certificate pinning**) y solo confía en ese certificado a partir de entonces. En la beta la huella se confirma comparándola visualmente con la CLI; después se añade el escaneo del QR.

### 5.2 Autenticación
- Login con usuario y contraseña; el agente devuelve un **token de sesión** aleatorio que se guarda con hash en SQLite.
- El token se guarda en el móvil en almacenamiento cifrado (Android Keystore).
- **Revocación:** `companion logout-all` invalida todas las sesiones; cambiar la contraseña con `companion passwd` también.
- **Límite de intentos:** tras varios fallos seguidos, el agente impone esperas crecientes.

### 5.3 Principio de mínimo privilegio
- El agente se ejecuta como servicio **de usuario**, nunca como root, y nunca usa `sudo`.
- El socket Unix de `companion notify` tiene permisos `0600`.

### 5.4 Modelo de amenazas

| Amenaza | Riesgo | Mitigación |
|---|---|---|
| Alguien en la misma Wi-Fi intercepta el tráfico o suplanta al PC | Robo de credenciales, acceso a la shell | TLS con certificado fijado en la primera conexión |
| Ataque de fuerza bruta a la contraseña | Acceso completo como el usuario | Contraseña robusta obligatoria, Argon2, límite de intentos con esperas crecientes |
| Robo o pérdida del móvil | Acceso con la sesión guardada | Token en almacenamiento cifrado; revocación con `companion logout-all`. Riesgo residual aceptado: si el móvil está desbloqueado, la app es accesible (mitigación futura: desbloqueo biométrico) |
| Acceso desde Internet a través de iroh | Conexiones no autorizadas | El túnel solo da acceso al servidor de la aplicación, que sigue exigiendo TLS con huella fijada y login |
| Acciones rápidas con comandos maliciosos | Ejecución de comandos arbitrarios | Solo las crea y ejecuta un usuario autenticado, con sus propios permisos; no amplía lo que ya permite la terminal |
| Otro usuario local del PC | Uso del agente ajeno | Datos en `~/.config` y `~/.local/share` con permisos del usuario; socket Unix `0600` |
| Escalada de privilegios mediante la app | Control de root | El agente no tiene más permisos que el usuario; nunca eleva privilegios |

**Decisión documentada:** se descartó el 2FA (TOTP) para mantener la configuración mínima. Se compensa con contraseña robusta obligatoria, límite de intentos y revocación de sesiones.

---

## 6. Diseño de la base de datos

Base de datos **SQLite** en el agente (`~/.local/share/companion/companion.db`). Se crea con el script `agent/schema.sql` y se accede exclusivamente a través de la capa de repositorios.

### 6.1 Diagrama entidad-relación (simplificado)

```
                    ┌──────────────┐
                    │   usuario    │
                    └──────┬───────┘
      ┌───────────┬────────┼─────────────┬────────────────┐
      │1:N        │1:N     │1:N          │1:N             │1:N
┌─────▼─────┐┌────▼─────┐┌─▼──────┐┌─────▼───────┐┌───────▼──────┐
│  sesion   ││ intento_ ││ grupo  ││regla_alerta ││ notificacion │
│           ││  login   │└─┬──────┘└─────┬───────┘└──▲────────▲──┘
└───────────┘└──────────┘  │1:N          │1:N (0..1)  │        │
                         ┌─▼────────────┐└────────────┘        │
                         │accion_rapida │                      │
                         └─┬────────────┘                      │
                           │1:N                     1:N (0..1) │
                         ┌─▼────────────┐                      │
                         │  ejecucion   ├──────────────────────┘
                         └──────────────┘
```

*(`accion_rapida` también referencia a `usuario` para las acciones "Sin grupo".)*

### 6.2 Tablas

| Tabla | Campos principales | Relaciones |
|---|---|---|
| **usuario** | id, nombre_usuario (único), hash_contrasena, creado_en | — |
| **sesion** | id, usuario_id, hash_token, dispositivo, creado_en, ultimo_acceso, revocada | N:1 usuario |
| **intento_login** | id, usuario_id (nulo si el usuario no existe), nombre_usuario, origen, fecha, exito | N:1 usuario |
| **grupo** | id, usuario_id, nombre, icono, orden, creado_en · único (usuario_id, nombre) | N:1 usuario · 1:N accion_rapida |
| **accion_rapida** | id, usuario_id, grupo_id (nulo = "Sin grupo"), nombre, comando, directorio, timeout_seg, confirmar, notificar_al_terminar, creado_en, actualizado_en | N:1 usuario · N:1 grupo · 1:N ejecucion |
| **ejecucion** | id, accion_id, inicio, fin, estado, codigo_salida, salida | N:1 accion_rapida (borrado en cascada) |
| **regla_alerta** | id, usuario_id, nombre, metrica, operador, umbral, duracion_seg, cooldown_seg, activa, creado_en | N:1 usuario · 1:N notificacion |
| **notificacion** | id, usuario_id, origen (manual / regla / acción), regla_id (nulo), ejecucion_id (nulo), titulo, mensaje, fecha, leida | N:1 usuario · N:1 regla_alerta · N:1 ejecucion |

**Entidades con CRUD completo desde la app:** grupo, accion_rapida y regla_alerta.
**Entidades de historial:** ejecucion y notificacion (creación automática, consulta, filtrado, marcado y borrado).

La configuración editable a mano (puertos, relés, umbrales por defecto) se guarda aparte en `~/.config/companion/config.toml`.

---

## 7. Casos de uso

**Actores:**
- **Usuario:** la persona propietaria del PC, que usa la app.
- **Programa del PC:** un script o herramienta que llama a `companion notify`.
- **Sistema:** el agente, cuando evalúa las reglas de alerta.

| Caso de uso | Actor | Módulo |
|---|---|---|
| Configurar el agente (`companion setup`) | Usuario (en el PC) | Seguridad |
| Registrarse desde la app *(pendiente de revisión)* | Usuario | Seguridad |
| Emparejar el móvil (huella / QR) | Usuario | Conectividad |
| Iniciar y cerrar sesión | Usuario | Seguridad |
| Consultar métricas del sistema | Usuario | B |
| Apagar, reiniciar, suspender o bloquear | Usuario | C |
| Buscar y finalizar procesos | Usuario | D |
| Gestionar grupos (crear, editar, borrar) | Usuario | E |
| Gestionar acciones rápidas (crear, editar, borrar) | Usuario | E |
| Ejecutar una acción rápida y ver su salida | Usuario | E |
| Consultar historial y estadísticas de ejecuciones | Usuario | E |
| Usar la terminal remota | Usuario | A |
| Explorar, descargar y subir archivos | Usuario | F |
| Gestionar reglas de alerta | Usuario | G |
| Consultar y gestionar notificaciones | Usuario | G |
| Enviar una notificación (`companion notify`) | Programa del PC | G |
| Generar una alerta por umbral | Sistema | G |
| Recibir una notificación en el móvil | Usuario | G |

El diagrama de casos de uso y la descripción detallada de los principales se incluyen en la memoria final.

---

## 8. Despliegue e instalación

### 8.1 Agente en el PC
```bash
pipx install linux-system-companion   # instala el agente en un entorno aislado
companion setup                       # crea credenciales y muestra los datos de conexión
companion install-service             # instala y activa el servicio systemd de usuario
```
Se usa **pipx** porque las distribuciones actuales bloquean `pip install` fuera de entornos virtuales. pipx usa pip por debajo, crea el entorno aislado automáticamente y utiliza el Python de la propia distribución. Las dependencias compiladas (iroh, cryptography, argon2) se instalan como paquetes precompilados que requieren **glibc 2.28 o superior**, así que el agente no es compatible con distribuciones basadas en musl (como Alpine).

### 8.2 Servicio systemd
`companion install-service` crea `~/.config/systemd/user/companion.service`:

```ini
[Unit]
Description=Linux System Companion agent

[Service]
ExecStart=%h/.local/bin/companion serve
Restart=on-failure

[Install]
WantedBy=default.target
```

El agente arranca con el gestor de usuario de systemd y se reinicia automáticamente si falla. Como casi todas las funciones no dependen del escritorio gráfico, no necesita esperar a la sesión gráfica.

### 8.3 Reinicio remoto (nota para el README)
Por defecto, el gestor de usuario de systemd solo se ejecuta mientras el usuario tiene una sesión abierta. **Tras un reinicio remoto, el agente no volvería hasta que alguien iniciara sesión en el PC.** Para mantener el acceso después de reiniciar:

```bash
loginctl enable-linger $USER
```

Con *linger* activado, el agente arranca al encender el PC aunque nadie inicie sesión. Limitaciones en ese estado:
- no hay sesión gráfica que bloquear;
- apagar o reiniciar sin una sesión activa puede requerir autorización de polkit. Opcionalmente, se puede añadir una regla de polkit que lo permita, asumiendo el riesgo que implica.

### 8.4 App móvil
- Distribución como **APK** en las *releases* del repositorio. La publicación en tiendas queda como trabajo futuro.
- El usuario solo instala la app, introduce o escanea los datos de conexión e inicia sesión.

---

## 9. Metodología, control de versiones y pruebas

### 9.1 Control de versiones
- Un repositorio Git con las carpetas `app/` (Flutter) y `agent/` (Python).
- Ramas:
  - `main`: versiones estables;
  - `develop`: integración;
  - `feature/<nombre>`: una por tarea o fase.
- Commits pequeños con formato convencional (`feat:`, `fix:`, `docs:`, `test:`, `refactor:`).
- Una etiqueta por versión (`v0.1-beta`, `v0.2`…).

### 9.2 Entorno de pruebas
Las pruebas no dependen de ninguna red externa (la red del centro puede bloquear la comunicación entre dispositivos):

| Método | Uso |
|---|---|
| **USB + `adb reverse tcp:8443 tcp:8443`** | Método principal: la app se conecta a `127.0.0.1:8443` y llega al agente del portátil por el cable |
| **Emulador de Android** | App y agente en el mismo portátil; `10.0.2.2` apunta al anfitrión. No sirve para probar iroh: el binding de Kotlin para Android solo admite arquitecturas ARM (aarch64 y armv7) y hay que compilarlo desde el código fuente |
| **Punto de acceso del móvil** | Red privada propia para probar como LAN real, incluido mDNS |
| **Repositorios simulados** | Desarrollar pantallas sin el agente |
| **iroh** (desde la fase 2) | Probar el acceso al PC de casa desde otras redes, siempre con un móvil físico: primero en casa (misma Wi-Fi, datos móviles, UDP bloqueado en el cortafuegos, cambio de red y reinicio) y después en una red restrictiva. No necesita abrir puertos de entrada, solo salida HTTPS (TCP 443) hacia los relés |

### 9.3 Pruebas
- **Agente:** pruebas automáticas con **pytest** de la lógica de negocio (repositorios, reglas de negocio de grupos y acciones, evaluación de reglas de alerta, autenticación y límite de intentos).
- **App:** pruebas de *widgets* de los formularios principales (validaciones) con `flutter_test`.
- **Pruebas manuales:** tabla de casos de prueba por fase (entrada, resultado esperado, resultado obtenido, captura).
- **Pruebas de instalación:** instalación desde cero en una máquina limpia o virtual.

---

## 10. Compatibilidad y limitaciones conocidas

- **Distribución:** cualquier distribución con systemd, Python 3.11+ y D-Bus. El entorno de pruebas oficial es KDE Plasma 6. El bloqueo de sesión depende de que el escritorio responda a la señal de logind (Plasma lo hace).
- **Temperaturas:** dependen de los sensores que exponga el kernel en `/sys/class/hwmon`. Las GPU NVIDIA con controlador propietario no aparecen ahí; su soporte (vía `nvidia-smi`) es opcional.
- **Hibernación:** muchas instalaciones no la tienen configurada. La app la ofrece solo si logind indica que está disponible.
- **Apagado o reinicio con otras sesiones abiertas:** polkit puede pedir autorización adicional.
- **Procesos:** solo se pueden finalizar los del propio usuario.
- **Batería del móvil:** el servicio en primer plano consume algo de batería y muestra un icono permanente en la barra de estado, que es el comportamiento estándar de Android.
- **Relés públicos de iroh:** gratuitos pero con límites de tráfico que pueden cambiar y sin garantía de disponibilidad; el propio proyecto iroh los considera aptos solo para desarrollo y uso personal (para un producto real recomienda relés gestionados o propios). Se puede configurar un relé propio.
- **Android 17 y red local:** las apps que declaren `targetSdk` 37 o superior deben pedir el permiso `ACCESS_LOCAL_NETWORK` para conectar con equipos de la red local y usar mDNS. Flutter 3.47 declara `targetSdk` 36, así que de momento no aplica; cuando se suba a 37 habrá que pedir este permiso en la pantalla de conexión. El móvil de pruebas usa Android 15, donde no se exige. *Pendiente de revisión:* comprobar si las conexiones a `127.0.0.1` (USB y túnel iroh) cuentan como red local a efectos de ese permiso.

---

## 11. Estado del arte (resumen)

| Herramienta | Uso fuera de casa sin configurar red | Terminal interactiva completa | Monitorización | Procesos y energía | App móvil | Avisos del PC al móvil |
|---|---|---|---|---|---|---|
| KDE Connect | No (requiere VPN) | No | Muy limitada | Parcial | Sí | Sí (notificaciones del escritorio) |
| Clientes SSH (Termius, ConnectBot) | No (requiere IP accesible o VPN) | Sí | No | Solo vía comandos | Sí | No |
| Cockpit | No (requiere exponerlo o VPN) | Sí (web) | Sí | Sí | No (web) | No |
| RustDesk | Sí (servidor de encuentro/relé) | Sí (desde la versión 1.4.1; su función principal es el escritorio remoto) | No | No | Sí | No |
| **Linux System Companion** | **Sí (iroh)** | **Sí** | **Sí** | **Sí** | **Sí** | **Sí** |

*Tabla orientativa; revisar cada entrada en la redacción final. Detalle de proyectos y licencias en 05-referencias-y-proyectos.md.*

---

## 12. Elemento diferenciador

El proyecto incluye varias funcionalidades no vistas en clase, entre ellas algunas que la normativa cita expresamente como ejemplo:

- **Uso de la cámara:** emparejamiento escaneando un código QR.
- **Servicios en segundo plano y notificaciones:** servicio en primer plano que mantiene la conexión y muestra avisos del PC.
- **Comunicación P2P con travesía de NAT (iroh):** acceso remoto sin configurar el router.
- **Terminal remota con pseudoterminal (PTY):** ejecución interactiva de la shell real del usuario.
- **Seguridad avanzada:** TLS con *certificate pinning*, hash Argon2 y límite de intentos.
- **Integración con el sistema operativo:** D-Bus (systemd-logind) y servicios de usuario de systemd.
- **Flutter** como framework de desarrollo (aceptado por el tutor).

---

## 13. Trabajo futuro
Las funciones descartadas del alcance y las ideas de evolución posterior se recogen en **06-ideas-de-futuro.md**.
