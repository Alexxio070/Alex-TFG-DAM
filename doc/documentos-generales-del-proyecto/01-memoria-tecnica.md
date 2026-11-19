# Memoria Técnica: Sysmote

**Título del proyecto:** Sysmote — Administración remota de tu PC Linux desde el móvil
**Tipo:** Proyecto final de DAM — aplicación móvil Android con backend propio
**Plataformas:** Android (cliente) — GNU/Linux con systemd (agente)
**Entorno de referencia:** Android 10+ (probado en Android 15) · KDE Plasma 6 · systemd · Python 3.11+
**Estado:** implementación en curso; estado por fase en `04-plan-de-fases.md`. Decisiones vigentes en `07-resumen-decisiones-y-contexto.md` §3.

---

## 1. Resumen

Sysmote es una herramienta de código abierto para **administrar un PC con GNU/Linux desde el móvil cuando no estás delante de él**, tanto desde la red de casa como desde fuera (4G/5G u otra Wi-Fi), sin configurar el router ni instalar nada más en el móvil.

El sistema tiene dos piezas: **una app Android** hecha con Flutter y **un agente en el PC** escrito en Python (FastAPI) que se ejecuta como servicio de usuario de systemd. Sus funciones (terminal remota, monitorización, procesos, energía, acciones rápidas, espacio compartido de notas y notificaciones) se detallan en §3.

La filosofía de diseño es: **solo se incluyen funciones que tienen sentido estando lejos del equipo**. Lo que únicamente es útil delante del PC (control multimedia, portapapeles, personalización del escritorio…) queda fuera del alcance y se recoge en `06-ideas-de-futuro.md`.

El desarrollo es incremental: una primera **beta (v0.1)** con la interfaz definitiva, las métricas y la conexión por iroh, y versiones posteriores que amplían el sistema sobre esa base (`04`).

---

## 2. Motivación y valor diferencial

Las herramientas existentes cubren partes del problema, pero ninguna lo resuelve completo: KDE Connect solo sirve cerca del PC y en la misma red; los clientes SSH móviles exigen exponer el PC a Internet y no monitorizan ni avisan; Cockpit no es una app móvil. Comparativa completa en §11.

**Valor diferencial:** una única app que combina terminal real, monitorización, procesos, energía, acciones rápidas, espacio compartido y avisos, y que funciona desde cualquier sitio con una configuración mínima.

> KDE Connect es una herramienta para cuando estás cerca del PC; Sysmote es una herramienta para cuando no lo estás.

---

## 3. Módulos funcionales

### Módulo A — Terminal remota
- **La sesión es del agente, no de la conexión.** La app solo pide al agente «abre una terminal y ejecuta esto». El agente crea una sesión de **tmux** con la shell configurada del usuario (`$SHELL`) en modo login (`-l`), así que se cargan sus alias, variables y prompt (Starship, Oh My Zsh…), y la app se engancha para ver la salida en tiempo real y teclear.
- **Persistencia:** si la app se cierra, pasa a segundo plano, se limpia de recientes o se pierde la cobertura, **la sesión y el comando siguen** en el PC. Al volver, la app se reengancha y recupera la salida que se perdió. Esto permite, por ejemplo, actualizar el sistema desde el móvil sin riesgo de dejarlo a medias.
- **Ventana en el PC:** al crear la sesión, el agente abre una ventana de la terminal gráfica del usuario (kitty, Konsole…) conectada a la misma sesión, para que al volver al PC se vea lo ocurrido. Sin sesión gráfica, la sesión funciona igual, solo en la app.
- **Cierre:** la sesión termina con `exit` (o Ctrl+D), al cerrar su ventana en la app o al cerrar su ventana en el PC. No hay caducidad por inactividad.
- **Sin sesiones activas, terminal vacía con aviso** («Toca para abrir una terminal en tu PC»): la sesión se crea al primer toque o tecla, con shell real desde ese momento.
- **Varias pestañas**, como las de un navegador: cada una es una terminal independiente con su propia sesión y su propia ventana en el PC; cerrar una pestaña cierra su terminal en el PC.
- **Requisitos en el PC:** `tmux`, y una terminal gráfica para la ventana. Sin `tmux`, la terminal funciona ligada a la conexión (se corta al desconectar) y la app avisa.
- La app muestra la terminal con **xterm.dart** (secuencias ANSI, color de 24 bits), con barra de teclas especiales (Ctrl, Alt, Tab, Esc, flechas) y redimensionado dinámico (`TIOCSWINSZ`). Usa la fuente monoespaciada del sistema Android, no una Nerd Font (ver `../ui/XTERM_DART.md`).
- **Shells:** el agente lanza `$SHELL` de forma genérica; Bash, Zsh y Fish funcionan igual a través del PTY. **La shell probada oficialmente es Zsh.**
- Diseño detallado en `../agente/terminal-sesiones-tmux.md`.

### Módulo B — Monitorización del sistema
- Uso de CPU, temperatura de CPU, RAM y discos, leídos con **psutil** (`/proc` y `/sys/class/hwmon`).
- Gráficas en vivo en la app, actualizadas cada segundo sobre los últimos 60 s, con selector de partición (por defecto, la del sistema).
- Ampliación opcional: CPU por núcleo, swap, carga del sistema y tiempo encendido (psutil ya los da, pero ni el endpoint ni la pantalla los muestran hoy).

### Módulo C — Energía y sesión
- **Estado: pendiente de decidir si entra en el proyecto.** Motivos y contexto: `07` §3.8.
- Apagar, reiniciar, suspender e hibernar mediante **systemd-logind por D-Bus**.
- Bloquear la sesión gráfica abierta, por si se dejó el PC desbloqueado. Se usa `Session.Lock()` (o `LockSession(id)`) sobre la sesión del propio usuario, que no pide autorización; `LockSessions()` bloquea todas las sesiones y polkit exige permisos de administrador.
- Todas las acciones destructivas piden confirmación en la app.
- **Limitación sin sesión activa:** ver §10. Posible solución y sus riesgos de seguridad: pendiente de investigar, ver `07` §3.8.

### Módulo D — Gestión de procesos
- Sección propia de la app, «Procesos», en el menú lateral.
- Lista de todos los procesos del PC con lo que consumen (CPU y memoria), ordenados por nombre, con una barra de búsqueda para encontrarlos por nombre o PID. Se actualiza con la misma frecuencia que las métricas (cada segundo).
- Acciones sobre un proceso, ambas con confirmación: **finalizarlo** en dos pasos (primero SIGTERM, cierre ordenado; si sigue vivo tras unos segundos, SIGKILL, cierre forzado) y **congelarlo** (pausarlo), con opción de reanudarlo después.
- El agente se ejecuta sin privilegios: ve todos los procesos, pero **solo puede finalizar o congelar los del propio usuario**. La app lo indica claramente.

### Módulo E — Acciones rápidas (CRUD)
Comandos guardados, organizados en grupos, que se ejecutan con un toque desde el móvil. Por ejemplo:
- grupo "Proyecto" → acción "Actualizar repo" (`cd ~/proyecto && git pull`);
- grupo "Mantenimiento" → acción "Copia de seguridad" (`~/scripts/backup.sh`).

En la app, las acciones aparecen como una **cuadrícula de botones** en la pantalla de inicio y los grupos son **carpetas** que se abren con un toque. Es una cuadrícula de iconos grandes, pensada para ejecutar con un toque y no para buscar en una lista.

**Funciones:**
- **CRUD completo de grupos y de acciones:** crear, consultar, editar y borrar.
- **Ejecución en segundo plano** en el PC:
  - con tiempo máximo (al superarlo se corta con SIGTERM → SIGKILL). El comando se lanza en su propio grupo de procesos y la señal se envía a todo el grupo, porque la shell que lo ejecuta puede tener procesos hijos que, si no, seguirían vivos;
  - con una sola ejecución simultánea por acción;
  - con la salida recortada a un tamaño máximo.
- **Historial de ejecuciones** con estado (en curso, éxito, error, cortada por tiempo, cancelada), código de salida y salida del comando. Filtros por acción, estado y fechas; borrado individual o completo.
- **Estadísticas por acción:** número de ejecuciones, tasa de éxito, duración media y fecha de la última ejecución.
- **Organización por arrastre** en la cuadrícula:
  - mantener pulsado un botón lo levanta y permite **reordenarlo**;
  - soltarlo sobre otro botón **crea una carpeta** con los dos;
  - soltarlo sobre una carpeta lo **añade** a ella;
  - arrastrarlo a la papelera lo **elimina**;
  - mantener pulsada una carpeta abre su edición (nombre y color de entre seis).
- **Orden persistente:** el orden de la cuadrícula y el de cada carpeta se guardan en el agente, de modo que son los mismos en cualquier momento y desde cualquier sesión.

**Reglas de negocio y validaciones** (en la app, para respuesta inmediata, y en el agente, para la seguridad real):
- el nombre de una acción es único dentro de su grupo, obligatorio y de 1 a 50 caracteres;
- comando obligatorio; tiempo máximo entre 1 y 3600 s; el directorio de trabajo debe existir y ser accesible;
- al borrar un grupo con acciones, el usuario elige entre moverlas a "Sin grupo" o borrarlas;
- al borrar una acción se borra su historial;
- una carpeta solo contiene acciones (no hay carpetas dentro de carpetas);
- la cuadrícula admite como máximo 40 elementos de primer nivel (carpetas y acciones sin carpeta).

**Creación rápida:** desde la cuadrícula, el botón «+» abre un diálogo con solo **nombre, comando y «pedir confirmación»**. El resto de campos (directorio de trabajo, tiempo máximo y «notificar al terminar») toman sus valores por defecto y se editan después desde la ficha de la acción.

**Seguridad:** una acción ejecuta comandos con los permisos del usuario, igual que la terminal. No amplía lo que puede hacer quien ya tiene acceso a la app.

**Pantallas de la app:**
1. **Inicio (cuadrícula):** botones de acción y carpetas, ejecución con un toque (con confirmación opcional), reordenado por arrastre, papelera y botón «+». Un aviso inferior muestra el nombre y el comando mientras se ejecuta.
2. **Carpeta:** diálogo con sus acciones, que también se ejecutan con un toque.
3. **Edición de carpeta** (nombre y color) y **creación rápida de acción** (nombre, comando y confirmación).
4. **Ficha de la acción** (pantalla secundaria; el acceso se define en la fase 7): todos sus datos editables, estadísticas, botón "Ejecutar" e historial reciente.
5. **Historial de ejecuciones** con filtros, y **detalle de ejecución** con estado, duración y salida del comando (opcionalmente mostrada con xterm.dart para conservar los colores).

Rutas de la API: ver «API REST (resumen)» al final de esta sección.

### Módulo F — Espacio compartido
- Un **espacio común entre el móvil y el PC** donde dejar **notas de texto y enlaces**, accesible desde los dos lados, para pasar información de uno a otro. Ejemplos: guardar un enlace en el móvil para abrirlo luego en el PC, o dejar desde el PC un texto o un comando para consultarlo fuera de casa.
- **CRUD completo desde la app:** crear, editar, borrar y buscar notas.
- **Tipo deducido por el agente:** el usuario solo pega o escribe el contenido. Al guardar, el agente marca la nota como `enlace` si incluye alguna dirección web (`http://`, `https://` o `www.`) en cualquier parte del texto, y como `texto` en caso contrario. La app usa la misma regla solo para mostrar los enlaces como pulsables.
- **Pantalla:** lista de tarjetas con texto seleccionable y enlaces que se abren al pulsarlos, botones de copiar y editar, y un formulario de un único campo.
- **En el PC:** desde la TUI (`sysmote`), con botones para añadir y ver notas.
- La app pide las notas al agente al abrir la pantalla del espacio compartido y al deslizar hacia abajo para recargar; no hace falta actualización al momento, porque es una app pensada para usarla lejos del PC.
- Si los dos lados editan la misma nota a la vez, se guarda el último cambio.
- *Imágenes en el espacio compartido: **aún pensándolo**.* No forman parte del alcance confirmado.
- El explorador y la transferencia de archivos quedan fuera del alcance (ver `06`).

Rutas de la API: ver «API REST (resumen)» al final de esta sección.

### Módulo G — Notificaciones y reglas de alerta
- **Avisos manuales:** el comando `sysmote notify "mensaje"` envía una notificación al móvil desde cualquier script o programa. Ejemplos:
  - `make && sysmote notify "Compilación terminada"`;
  - un *hook* de Claude Code al terminar de trabajar.
- **Avisos de acciones rápidas:** opción "notificar al terminar" en cada acción.
- **Reglas de alerta (CRUD completo desde la app):** métrica (CPU, RAM, temperatura, disco), operador, umbral, duración sostenida, tiempo mínimo entre avisos y activa/inactiva. Ejemplo: "CPU > 90 % durante 2 minutos".
- **Historial de notificaciones** con búsqueda, filtros, marcar como leída y borrar.
- En el móvil, un **servicio en primer plano** mantiene la conexión abierta y muestra los avisos como notificaciones de Android. No se usa Firebase ni ningún servidor externo.
- **Requisitos de Android:**
  - desde Android 13 la app debe pedir el permiso `POST_NOTIFICATIONS` en tiempo de ejecución; sin él, los avisos no se muestran;
  - tipo del servicio en primer plano (candidato `connectedDevice`, permisos del manifiesto): justificación y detalle en `02-necesidades-tecnologicas.md` §4.1; se confirma en la fase 8.

Rutas de la API: ver «API REST (resumen)» al final de esta sección.

### Módulo H — Conectividad
- **En red local:** conexión directa, con autodescubrimiento del PC por **mDNS**.
- **Emparejamiento por QR:** la app escanea con la cámara el código que muestra la TUI del agente (ver 5.1).
- **Desde fuera de casa:** túnel P2P cifrado con **iroh** (ver 4.4).
- El resto de la app no distingue entre ambos modos: usa exactamente el mismo código de comunicación.

### Navegación y pantallas de la app
La app se organiza con un **menú lateral (drawer)** con cinco secciones: **Inicio** (cuadrícula de acciones rápidas, Módulo E), **Métricas** (Módulo B), **Procesos** (Módulo D), **Terminal** (Módulo A) y **Notas** (espacio compartido, Módulo F). En el pie del menú están el botón de **Ajustes** (engranaje) y el estado de conexión ("Conectado" / "Sin emparejar").

- **Ajustes:** unidades de temperatura (°C / °F) y de almacenamiento (GB / GiB), alerta de temperatura, tamaño de fuente de la terminal, tema claro u oscuro, color de acento (uno de seis), modo de conexión **Local / iroh** con la dirección del agente (`host:puerto` en Local, identificador a mano en iroh) y emparejar o desemparejar el móvil. Se guardan en el propio móvil. La alerta de temperatura de Ajustes solo resalta el valor en la pantalla de métricas cuando supera el límite elegido (60–95 °C); no es una regla de alerta del agente (Módulo G) ni genera notificaciones. Cerrar sesión y los datos del servidor se añaden cuando exista el login.
- **Pantallas secundarias de Inicio:** carpeta, edición de carpeta, creación rápida, ficha de la acción e historial de ejecuciones (ver Módulo E). El acceso a la ficha y al historial se define en la fase 7.
- **Aún sin ubicación decidida:** energía (Módulo C), reglas de alerta e historial de notificaciones (Módulo G), y las pantallas de login, conexión y escaneo del QR (Módulo H y §5). *Ubicación pendiente de revisión.*

### API REST (resumen)
Rutas ya definidas para los módulos con CRUD completo (grupos y acciones rápidas, notas, reglas y notificaciones). El resto de módulos aún no tiene rutas concretas documentadas.

```
GET    /grupos                         POST   /grupos
PUT    /grupos/{id}                    DELETE /grupos/{id}?modo=mover|borrar

GET    /acciones?grupo=                POST   /acciones
PUT    /orden                          (guarda el orden de la cuadrícula y de cada carpeta)
GET    /acciones/{id}                  (incluye estadísticas)
PUT    /acciones/{id}                  DELETE /acciones/{id}
POST   /acciones/{id}/ejecutar         POST   /ejecuciones/{id}/cancelar

GET    /ejecuciones?accion=&estado=&desde=&hasta=
GET    /ejecuciones/{id}               DELETE /ejecuciones/{id}
DELETE /ejecuciones?accion=            (limpiar historial)

GET    /notas?q=                       POST   /notas
PUT    /notas/{id}                     DELETE /notas/{id}

GET    /reglas                         POST   /reglas
PUT    /reglas/{id}                    DELETE /reglas/{id}
GET    /notificaciones?origen=&leida=&q=&desde=&hasta=
PATCH  /notificaciones/{id}            (marcar como leída)
DELETE /notificaciones/{id}            DELETE /notificaciones   (limpiar historial)
WS     /ws/events                      (avisos en tiempo real)
```

---

## 4. Arquitectura

### 4.1 Vista general

```
App Android (Flutter): Vistas → ViewModels (provider) → Repositorios → Servicios de red
  xterm.dart · HTTP/REST · WebSocket · notificaciones locales
  iroh_flutter (Dart): conexión iroh · Kotlin (platform channel): servicio en 1er plano (*)
        │
  LAN: conexión directa TLS, descubrimiento mDNS  │  WAN: túnel iroh (QUIC cifrado; relé → directa si el NAT lo permite)
        └──────────────────────────┬──────────────────────────┘
Agente PC (Python): Rutas API (FastAPI) → Servicios → Repositorios → SQLite
  PTY · psutil · dbus-fast · iroh · TUI "sysmote" · socket Unix para "sysmote notify"
        │
GNU/Linux: /proc y /sys · D-Bus (systemd-logind) · systemd (usuario)
```

*(\*) La implementación del servicio en primer plano se decide en la fase 8 (`02` §4.1).*

### 4.2 Arquitectura en capas

**App (patrón MVVM):**
- **Vistas:** pantallas y *widgets*; solo muestran datos y recogen acciones del usuario.
- **ViewModels:** estado de cada pantalla y lógica de presentación (gestionados con `provider`).
- **Repositorios:** punto único de acceso a los datos. Cada repositorio tiene una versión real (llama al agente) y una **versión simulada** con datos inventados, útil para desarrollar pantallas sin el agente.
- **Servicios de red:** cliente HTTP/WebSocket, gestión del token y del certificado fijado.

**Agente:**
- **Rutas de la API:** reciben peticiones, validan datos de entrada (Pydantic) y devuelven respuestas.
- **Servicios:** lógica de negocio (ejecución de acciones, evaluación de reglas de alerta, gestión de sesiones…).
- **Repositorios:** único punto de acceso a SQLite (`UsuarioRepository`, `GrupoRepository`, `AccionRepository`, `EjecucionRepository`, `ReglaAlertaRepository`, `NotificacionRepository`, `NotaRepository`…).
- **Modelos:** clases de datos que representan cada entidad.

### 4.3 Comunicación
- **REST (HTTP/JSON):** peticiones puntuales, como login, energía y el CRUD de grupos, acciones, notas, reglas y notificaciones.
- **WebSocket:** canales continuos para la terminal, las métricas en vivo y los eventos o notificaciones.
- En la beta las métricas se obtienen por consulta periódica REST (cada 1 s) por simplicidad.

### 4.4 Diseño del acceso remoto: túnel local
Para no duplicar código entre LAN y WAN, el acceso remoto funciona como un **túnel transparente**, siguiendo el patrón de la herramienta *dumbpipe* del proyecto iroh:

1. **En el PC,** el agente crea un punto de conexión iroh que reenvía todo lo que recibe a su propio servidor FastAPI local.
2. **En el móvil,** la app usa el plugin `iroh_flutter` desde Dart, sin puente en Kotlin: `IrohMetricsRepository` abre una conexión iroh con el identificador del PC y, por cada petición, un *stream* en el que escribe la petición HTTP y lee la respuesta. Detalle en `doc/iroh/02-implementacion.md` y `02` §4.2.
3. **El resto de la app** no cambia: `ConnectionModeMetricsRepository` elige entre el repositorio HTTP (LAN) y el de iroh según el modo de Ajustes, y los ViewModels y vistas usan la misma interfaz. De momento solo las métricas viajan por iroh; el resto de funciones, en sus fases (login desde la fase 3; el TLS propio solo se aplica en red local, ver §5.1).

iroh identifica a cada equipo por su clave pública. La conexión empieza a través de un relé cifrado y después intenta pasar a directa atravesando el NAT; si no lo consigue, sigue por el relé. Se usan los relés públicos del proyecto (límites en §10). Cada arranque genera una identidad nueva por defecto, así que el agente guarda su clave secreta (`SecretKey`) y la carga al arrancar para conservar el mismo identificador.

**Plan B:** si el acceso remoto no pudiera completarse, el sistema es plenamente funcional en red local. Las notificaciones tampoco dependen de iroh.

---

## 5. Seguridad

### 5.1 Configuración inicial, registro y emparejamiento
El usuario escribe `sysmote` en el PC y se abre la **TUI** (interfaz de texto con botones, ver 8.1). El botón de configuración inicial:
- genera un certificado TLS autofirmado propio del equipo;
- abre el **modo registro** y muestra en la terminal un **código QR** con la dirección, la huella del certificado, el identificador iroh (cuando exista) y un **código de registro de un solo uso** con caducidad corta.

Con el escáner de la fase 9, la app escanea el QR con la cámara (`mobile_scanner`), guarda la huella del certificado (**certificate pinning**) y muestra el mensaje "Emparejado, se necesita crear autenticación". Después abre un diálogo para crear el usuario y la contraseña, con confirmación y validación de robustez. El agente comprueba el código de registro, guarda la contraseña con hash **Argon2** y **cierra el modo registro** en cuanto se crea la primera cuenta. Un código caducado o ya usado no sirve.

A partir de entonces la app solo confía en ese certificado. Esto vale para la conexión por red local (USB o LAN). **Por iroh no se añade un TLS propio:** la conexión de iroh ya va cifrada de extremo a extremo (QUIC con TLS 1.3) y autentica al agente por su clave pública, el identificador iroh, que viaja en el QR. El identificador cumple así el papel de la huella, y el login sigue siendo obligatorio. El túnel reenvía a un puerto HTTP interno que solo escucha en `127.0.0.1`. Para volver a emparejar la app (por ejemplo, reinstalada), la TUI tiene un botón que muestra el QR de emparejamiento (sin código de registro); tras escanearlo, la app pide el login.

La TUI no crea la cuenta: solo abre el modo registro. La cuenta la crea la app con `POST /registro` y el código de registro (16 caracteres en base32, un solo uso, 10 minutos; se acepta sin guiones y en minúsculas). La contraseña debe tener como mínimo 5 caracteres, un número y una mayúscula. Hasta que llegue el escáner de QR de la app (fase 9), la dirección, la huella y el código se escriben a mano y la huella se compara a ojo con la de la TUI.

### 5.2 Autenticación
- Login con usuario y contraseña; el agente devuelve un **token de sesión** aleatorio que se guarda con hash en SQLite.
- El token se guarda en el móvil en almacenamiento cifrado (Android Keystore) y en memoria para las peticiones. Sin sesión, la app solo muestra el login. Si el agente no responde, un token guardado no se borra (puede ser solo un fallo de red); sí se borra con un `401`.
- **Una sola sesión activa:** si ya hay una, un nuevo login no la sobrescribe hasta que el usuario lo confirme en la TUI del PC (diálogo «Hay una sesión activa en…, ¿quieres cerrarla e iniciar una nueva?»).
- **Revocación:** el botón «Cerrar todas las sesiones» de la TUI invalida todas las sesiones; cambiar la contraseña desde la TUI también.
- **Límite de intentos:** se permiten 5 intentos fallidos seguidos y el 6.º queda bloqueado (`429`) durante 10 minutos por defecto, configurable (`doc/agente/contrato-api-fase3.md` §5).
- **Mínimo privilegio:** el agente se ejecuta como servicio de usuario, nunca como root ni con `sudo`.

### 5.3 Modelo de amenazas

| Amenaza | Riesgo | Mitigación |
|---|---|---|
| Alguien en la misma Wi-Fi intercepta el tráfico o suplanta al PC | Robo de credenciales, acceso a la shell | TLS con certificado fijado en la primera conexión |
| Ataque de fuerza bruta a la contraseña | Acceso completo como el usuario | Contraseña robusta obligatoria, Argon2, límite de intentos con esperas crecientes |
| Robo o pérdida del móvil | Acceso con la sesión guardada | Token en almacenamiento cifrado; revocación desde la TUI (cerrar todas las sesiones). Riesgo residual aceptado: si el móvil está desbloqueado, la app es accesible (mitigación futura: desbloqueo biométrico) |
| Alguien usa el QR de registro antes que el usuario | Crear la cuenta en su lugar | Código de un solo uso con caducidad corta; el QR solo se muestra en la pantalla del PC; el modo registro se cierra tras la primera cuenta |
| Acceso desde Internet a través de iroh | Conexiones no autorizadas | El túnel solo da acceso al servidor de la aplicación, que exige login (desde la fase 3). La conexión va cifrada de extremo a extremo y autenticada con la clave pública del agente, así que nadie puede hacerse pasar por él sin su clave secreta |
| Acceso al agente durante la beta (hasta la fase 3, sin TLS de aplicación ni login) | Cualquiera que conozca el identificador iroh llega al agente | El agente solo expone métricas de solo lectura, el identificador no se comparte y el agente se arranca a mano solo para probar |
| Acciones rápidas con comandos maliciosos | Ejecución de comandos arbitrarios | Solo las crea y ejecuta un usuario autenticado, con sus propios permisos; no amplía lo que ya permite la terminal |
| Otro usuario local del PC | Uso del agente ajeno, lectura de la base de datos o de las claves | El agente crea `~/.config/sysmote` y `~/.local/share/sysmote` con permisos `0700`, y la base de datos, la clave privada TLS y la clave secreta de iroh con `0600` (la especificación XDG no garantiza por sí misma que esas carpetas sean privadas); socket Unix `0600`. Hoy solo está implementada la clave secreta de iroh con `0600` (fase 2); las carpetas `0700` y el resto llegan con la fase 3 |
| Escalada de privilegios mediante la app | Control de root | El agente no tiene más permisos que el usuario; nunca eleva privilegios |

Sin 2FA, a propósito (motivo en `02` §5.2).

---

## 6. Diseño de la base de datos

Base de datos **SQLite** en el agente (`~/.local/share/sysmote/sysmote.db`), creada con `agent/sysmote/schema.sql` y accesible solo a través de la capa de repositorios. El esquema tiene versión (`PRAGMA user_version`): cuando una actualización del agente cambia una tabla, las bases de datos que ya tienen los usuarios se migran al abrirse con los cambios de `agent/sysmote/migraciones.py`, y una base de una versión más nueva que el agente se rechaza con un error claro (detalles de SQLite, como `PRAGMA foreign_keys`, en `02` §6.1).

El historial de comandos de terminal **no** vive en esta base de datos: va en un archivo de log aparte (ver `../agente/tui.md`, «Historial de comandos de terminal»).

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

*(`accion_rapida` también referencia a `usuario` para las acciones "Sin grupo". La tabla `nota` cuelga de `usuario` con relación 1:N; no se dibuja para no complicar el diagrama.)*

### 6.2 Tablas

| Tabla | Campos principales | Relaciones |
|---|---|---|
| **usuario** | id, nombre_usuario (único), hash_contrasena, creado_en | — |
| **sesion** | id, usuario_id, hash_token, dispositivo, creado_en, ultimo_acceso, revocada, motivo_revocacion (distingue el `401 desemparejado` del `401 no_autenticado`) | N:1 usuario |
| **solicitud_login** (efímera) | id (32 bytes aleatorios en base64url), usuario_id, dispositivo, creada, estado (pendiente / aprobada / rechazada / caducada), caduca_en. Es el canal entre la TUI y el agente: ambos la leen y la escriben | N:1 usuario |
| **codigo_registro** (efímera) | id, hash_codigo (SHA-256), creado, caduca_en, usado. Código de 16 caracteres en base32, un solo uso, 10 minutos | — |
| **intento_login** | id, usuario_id (nulo si el usuario no existe), nombre_usuario, origen, fecha, exito | N:1 usuario |
| **grupo** | id, usuario_id, nombre, color, orden, creado_en · único (usuario_id, nombre) | N:1 usuario · 1:N accion_rapida |
| **accion_rapida** | id, usuario_id, grupo_id (nulo = "Sin grupo"), nombre, comando, icono, orden, directorio, timeout_seg, confirmar, notificar_al_terminar, creado_en, actualizado_en | N:1 usuario · N:1 grupo · 1:N ejecucion |
| **ejecucion** | id, accion_id, inicio, fin, estado, codigo_salida, salida | N:1 accion_rapida (borrado en cascada) |
| **regla_alerta** | id, usuario_id, nombre, metrica, operador, umbral, duracion_seg, cooldown_seg, activa, creado_en | N:1 usuario · 1:N notificacion |
| **notificacion** | id, usuario_id, origen (manual / regla / acción), regla_id (nulo), ejecucion_id (nulo), titulo, mensaje, fecha, leida | N:1 usuario · N:1 regla_alerta · N:1 ejecucion |
| **nota** | id, usuario_id, tipo (texto / enlace), contenido, origen (móvil / PC), creado_en, actualizado_en | N:1 usuario |

**Entidades con CRUD completo desde la app:** grupo, accion_rapida, regla_alerta y nota.

**Campos que sostienen la cuadrícula de inicio:**
- `grupo.color`: color de la carpeta, uno de los seis de la paleta de la app;
- `accion_rapida.icono`: icono del botón (`volume`, `lock`, `moon` o `bolt`, por defecto `bolt`);
- `orden`: posición. En `grupo` y en las `accion_rapida` sin grupo comparten una misma secuencia (el primer nivel de la cuadrícula); en las acciones con grupo es la posición dentro de la carpeta.

**Entidades de historial:** ejecucion y notificacion (creación automática, consulta, filtrado, marcado y borrado).

La configuración editable a mano (puertos, relés, umbrales por defecto) se guarda aparte en `~/.config/sysmote/config.toml`.

### 6.3 Exportación desde la TUI
La TUI tiene dos botones de exportación (fase 7). Los archivos se guardan en el escritorio del usuario (`XDG_DESKTOP_DIR`, normalmente `~/Escritorio`) o, si no está definido, en la carpeta personal, con la fecha y la hora en el nombre para no sobrescribir exportaciones anteriores.
- **Exportar datos:** un único archivo JSON, `sysmote-datos-AAAAMMDD-HHMM.json`, con una sección por tabla. Se excluyen las tablas `sesion` e `intento_login` (datos de seguridad sin utilidad fuera del agente) y el hash de la contraseña. Alternativas descartadas: CSV (un archivo por tabla y se pierden los tipos) y SQL con `INSERT` (mezcla datos y estructura).
- **Exportar estructura:** una carpeta `sysmote-estructura-AAAAMMDD-HHMM/` con `tablas.sql`, `indices.sql`, `vistas.sql` y `triggers.sql`, generados a partir de la tabla `sqlite_schema` de SQLite, que guarda la sentencia de creación de cada tabla, índice, vista y trigger. Los índices que SQLite crea automáticamente no tienen sentencia y no aparecen. Los *joins* no se guardan en la base de datos, porque forman parte de las consultas; las relaciones están como claves foráneas dentro de `tablas.sql`. Si un archivo no tiene contenido (el diseño actual no tiene vistas ni triggers), lleva un comentario que lo explica.

---

## 7. Casos de uso

**Actores:**
- **Usuario:** la persona propietaria del PC, que usa la app.
- **Programa del PC:** un script o herramienta que llama a `sysmote notify`.
- **Sistema:** el agente, cuando evalúa las reglas de alerta.

| Caso de uso | Actor | Módulo |
|---|---|---|
| Configurar el agente desde la TUI | Usuario (en el PC) | Seguridad |
| Escanear el QR de registro y crear la cuenta en la app | Usuario | Seguridad |
| Emparejar el móvil (QR) | Usuario | Conectividad |
| Iniciar y cerrar sesión | Usuario | Seguridad |
| Consultar métricas del sistema | Usuario | B |
| Apagar, reiniciar, suspender o bloquear | Usuario | C |
| Buscar, congelar y finalizar procesos | Usuario | D |
| Gestionar grupos (crear, editar, borrar) | Usuario | E |
| Gestionar acciones rápidas (crear, editar, borrar) | Usuario | E |
| Ejecutar una acción rápida y ver su salida | Usuario | E |
| Consultar historial y estadísticas de ejecuciones | Usuario | E |
| Usar la terminal remota | Usuario | A |
| Gestionar notas del espacio compartido (crear, editar, borrar, buscar) | Usuario (en el móvil o en el PC) | F |
| Gestionar reglas de alerta | Usuario | G |
| Consultar y gestionar notificaciones | Usuario | G |
| Enviar una notificación (`sysmote notify`) | Programa del PC | G |
| Generar una alerta por umbral | Sistema | G |
| Exportar los datos o la estructura de la base de datos | Usuario (en el PC) | Base de datos |
| Recibir una notificación en el móvil | Usuario | G |

El diagrama de casos de uso y la descripción detallada de los principales se incluyen en la memoria final.

---

## 8. Despliegue e instalación

### 8.1 Agente en el PC
```bash
pipx install sysmote   # instala el agente en un entorno aislado
sysmote                             # abre la TUI: configuración inicial, QR de registro, servicio…
```
Escribir `sysmote` abre una **TUI** hecha con **Textual**, con cuatro secciones fijas (Emparejamiento, Historial, Base de datos, Notas). Especificación completa: `doc/agente/tui.md`.

Solo quedan como comandos de terminal (con **Typer**) `sysmote serve`, que es lo que arranca systemd, y `sysmote notify "mensaje"`, pensado para scripts y *hooks*.

**Dependencias del sistema** (las instala el gestor de paquetes de la distribución, no `pipx`): `tmux` y una terminal gráfica (kitty, Konsole…) para la ventana del PC. La TUI comprueba al arrancar si están y avisa si faltan.

Elección de **pipx** y límites de compatibilidad del binding de iroh (glibc, arquitecturas): ver `02` §7.2.

### 8.2 Servicio systemd
El botón «Instalar servicio» de la TUI crea `~/.config/systemd/user/sysmote.service`:

```ini
[Unit]
Description=Sysmote agent

[Service]
ExecStart=%h/.local/bin/sysmote serve
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

Con *linger* activado, el agente arranca al encender el PC aunque nadie inicie sesión. Limitaciones en ese estado y posible solución: ver §10.

### 8.4 App móvil
- Distribución como **APK** en las *releases* del repositorio. La publicación en tiendas queda como trabajo futuro.
- El usuario solo instala la app, introduce o escanea los datos de conexión e inicia sesión.

---

## 9. Metodología, control de versiones y pruebas

### 9.1 Control de versiones
Un repositorio Git con `App-movil/` (Flutter) y `agent/` (Python). Ramas y convención de commits: `CLAUDE.md`.

### 9.2 Entorno de pruebas
Métodos y alternativas descartadas: `02` §8.4. Tabla operativa completa, con la matriz de pruebas de iroh: `04`, «Entorno de pruebas».

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
- **Apagado o reinicio sin sesión activa:** con la política por defecto de systemd, polkit lo permite si el usuario tiene una sesión activa (aunque haya otras abiertas), pero pide autorización si no la tiene (por ejemplo, con *linger* y nadie conectado) o si la distribución endurece la política. Posible solución (una regla de polkit que lo permita sin sesión) y sus riesgos de seguridad: **pendiente de investigar**, ver `07` §3.8.
- **Batería del móvil:** el servicio en primer plano consume algo de batería y muestra una notificación persistente, que es el comportamiento estándar de Android. Desde Android 14 el usuario puede descartarla, y sin el permiso `POST_NOTIFICATIONS` solo aparece en el gestor de tareas.
- **Desemparejamiento al desinstalar:** desinstalar la app del móvil o el agente del PC **no desempareja automáticamente**. Android no avisa a una app cuando se desinstala, y la app no puede distinguir un agente desinstalado de un PC apagado. El emparejamiento se deshace con «Desemparejar» en la TUI o en la app, por inactividad (30 días) o con el aviso al quitar el servicio; la TUI muestra la última conexión de cada dispositivo (contrato en `doc/agente/contrato-api-fase3.md`).
- **Relés públicos de iroh:** gratuitos pero con límites de tráfico que pueden cambiar y sin garantía de disponibilidad; el propio proyecto iroh los considera aptos solo para desarrollo y uso aficionado (para un producto real recomienda relés gestionados o propios). Se puede configurar un relé propio.
- **Android 17 y red local:** las apps que declaren `targetSdk` 37 o superior deben pedir el permiso `ACCESS_LOCAL_NETWORK` para conectar con equipos de la red local y usar mDNS. Flutter 3.47 declara `targetSdk` 36 y el móvil de pruebas usa Android 15, así que de momento no aplica; al subir a 37 habrá que pedirlo en la pantalla de conexión. *Pendiente de confirmar:* que no afecta a `127.0.0.1` (USB con `adb reverse`) y si afecta a iroh cuando la conexión pasa a directa dentro de la red local.

---

## 11. Estado del arte (resumen)

| Herramienta | Uso fuera de casa sin configurar red | Terminal interactiva completa | Monitorización | Procesos y energía | App móvil | Avisos del PC al móvil |
|---|---|---|---|---|---|---|
| KDE Connect | No (requiere VPN) | No | Muy limitada | Parcial | Sí | Sí (notificaciones del escritorio) |
| Clientes SSH (Termius, ConnectBot) | No (requiere IP accesible o VPN) | Sí | No | Solo vía comandos | Sí | No |
| Cockpit | No (requiere exponerlo o VPN) | Sí (web) | Sí | Sí | No (web) | No |
| RustDesk | Sí (servidor de encuentro/relé) | Sí (desde la versión 1.4.1; su función principal es el escritorio remoto) | No | No | Sí | No |
| **Sysmote** | **Sí (iroh)** | **Sí** | **Sí** | Sí (energía pendiente de decidir) | **Sí** | **Sí** |

*Tabla orientativa; revisar cada entrada en la redacción final. Detalle de proyectos y licencias en 05-referencias-y-proyectos.md.*

---

## 12. Elemento diferenciador

El proyecto incluye varias funcionalidades no vistas en clase, entre ellas algunas que la normativa cita expresamente como ejemplo:

- **Uso de la cámara:** registro y emparejamiento escaneando el código QR que muestra la TUI.
- **Servicios en segundo plano y notificaciones:** servicio en primer plano que mantiene la conexión y muestra avisos del PC.
- **Comunicación P2P con travesía de NAT (iroh):** acceso remoto sin configurar el router.
- **Terminal remota con pseudoterminal (PTY):** ejecución interactiva de la shell real del usuario.
- **Seguridad avanzada:** TLS con *certificate pinning*, hash Argon2 y límite de intentos.
- **Integración con el sistema operativo:** D-Bus (systemd-logind) y servicios de usuario de systemd.
- **Flutter** como framework de desarrollo (aceptado por el tutor).

---

## 13. Trabajo futuro
Las funciones descartadas del alcance y las ideas de evolución posterior se recogen en `06`.
