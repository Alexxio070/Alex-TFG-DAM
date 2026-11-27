# Sysmote — especificación de la TUI

Aplicación de terminal (Textual, Python) para gestionar el emparejamiento con la app Android,
la seguridad y el servicio del propio agente, ver el historial de acciones y consultar la base
de datos SQLite local.

**Origen:** boceto inicial aportado por alex (estructura, banner, colores, comportamiento de
Emparejamiento/Historial/Base de datos). Las subpestañas de Emparejamiento (Seguridad, Servicio)
y el botón Notas se añadieron después para cubrir las fases del proyecto que el boceto inicial
no contemplaba (fase 3, fase 4, fase 8). El esquema de datos y las rutas son los ya documentados
en `../documentos-generales-del-proyecto/01-memoria-tecnica.md` (§6), no los de ejemplo del
boceto original.

## Estructura (de arriba abajo, todo a ancho completo)

1. **Banner** — "SYSMOTE" en arte ASCII ANSI Shadow, en una sola línea. Color verde, en negrita.
   Línea inferior gruesa.
   **Responsivo:** el arte ASCII tiene un ancho fijo (no se puede "encoger" sin romperse). Por
   debajo de 66 columnas de ancho de terminal (`BANNER_MIN_WIDTH` en `main_screen.py`) se
   sustituye por el texto plano "SYSMOTE" centrado, mismo color y negrita.
2. **Área de datos** — un marco redondeado con el título "Datos" arriba a la izquierda.
   Ocupa todo el espacio libre. Por defecto está **vacía**; muestra la sección del botón pulsado.
3. **Barra de botones** — cuatro botones de igual anchura, en este orden:
   "Emparejamiento", "Historial", "Base de datos", "Notas".
4. **Pie** — atajo `q` para salir.

## Secciones (contenido del área de datos)

### Emparejamiento

Tres subpestañas propias, que cambian el contenido del mismo marco sin volver al menú principal:

#### Dispositivo
- Izquierda: código QR de emparejamiento (texto con bloques `▀ ▄ █`, negro sobre fondo blanco para
  que se lea con cualquier tema, usando la librería `qrcode`, dependencia obligatoria del agente) y,
  debajo, **el mismo contenido en texto plano**: el URI del contrato
  (`sysmote://emparejar?v=1&dir=…&huella=…&iroh=…[&codigo=…]`).
  - Con el modo registro abierto lleva el `codigo` de registro.
  - Con una cuenta ya creada es el QR de volver a emparejar, sin `codigo`.
  - Sin certificado, o sin cuenta y sin modo registro abierto, muestra un aviso en su lugar.
  - Mide unas 25 filas: en terminales bajas la pestaña hace scroll.
- Derecha: dispositivo, fecha y hora de conexión, última conexión y estado — datos de `sesion`.
  Sin sesión activa pone «Sin dispositivo emparejado.».
- Debajo de los datos del dispositivo: botón rojo **Desemparejar**.
  Está desactivado si no hay ningún dispositivo emparejado. Al pulsarlo revoca la sesión con el
  motivo `desemparejado`: la app olvida el equipo en su siguiente petición (`401 desemparejado`;
  contrato: `contrato-api-fase3.md`).

#### Seguridad (fase 3)
- Texto: dirección del agente (IP de la LAN y puerto 8443), huella del certificado TLS,
  identificador iroh, estado de cada servidor (HTTPS, HTTP interno, iroh) y, si hay uno vigente,
  el código de registro con la hora de caducidad.
- Botón **Configuración inicial**: genera el certificado TLS autofirmado si falta y abre el modo
  registro: crea un código de un solo uso (16 caracteres en base32, caduca a los 10 minutos), del
  que solo se guarda el hash. **La cuenta no se crea en la TUI:** la crea la app con
  `POST /registro` y ese código (contrato de la fase 3). Deshabilitado cuando ya existe una cuenta.
- Botón **Cambiar contraseña**: diálogo con la contraseña nueva y su confirmación; muestra los
  motivos si es débil (mínimo 5 caracteres, un número y una mayúscula). Guarda el hash Argon2 y
  **cierra todas las sesiones** y levanta el bloqueo por intentos fallidos.
- Botón **Cerrar todas las sesiones**: sin diálogo de confirmación.
- Botón **Reiniciar intentos**: pone a 0 el contador de intentos de login fallidos y levanta el
  bloqueo (para pruebas; no existe ruta HTTP equivalente).
- Los tres botones anteriores están deshabilitados hasta que existe una cuenta.
- **Solicitud de nueva sesión:** si la app intenta iniciar sesión mientras hay otra sesión activa,
  la TUI muestra un diálogo: «Hay una sesión activa en {dispositivo}. ¿Quieres cerrarla e iniciar
  una nueva?», con el dispositivo que lo solicita y los botones **Sí, sobrescribir la sesión** y
  **No, mantener la sesión anterior**. La TUI consulta SQLite cada segundo **mientras esta
  subpestaña está abierta**; no avisa si está cerrada. Contrato: `contrato-api-fase3.md`.

#### Servicio (fase 4)
- Botones **Instalar servicio**, **Quitar servicio** y **Estado**: gestionan el servicio systemd
  de usuario que ejecuta `sysmote serve`.
- Deshabilitados hasta la fase 4.

### Historial
- Tabla con tres columnas: **Fecha y hora** (dd/mm/aaaa hh:mm:ss), **Origen** y **Comando**.
- Origen: `MACRO` (ejecuciones de acciones rápidas, tabla `ejecucion`, fase 5) o `TERMINAL`
  (comandos enviados desde la app en la terminal, fase 5 — ver más abajo).
- Las dos fuentes se combinan **solo al mostrarlas**, sin guardarlas juntas: `ejecucion` es una
  tabla SQLite y los comandos de terminal vienen de un archivo de log aparte (ver "Historial de
  comandos de terminal").
- Orden: lo más reciente primero. Las filas se pueden seleccionar con el cursor.
- Vacía hasta que exista alguna de las dos fuentes.

### Base de datos
**Diseño, todavía sin implementar:** la base de datos ya existe (fase 3), pero la sección solo
muestra "Sin tablas todavía.". Cuando se implemente:
- Lista de **todas las tablas** del esquema real (`usuario`, `sesion`, `intento_login`,
  `solicitud_login`, `codigo_registro`, `grupo`, `accion_rapida`, `ejecucion`, `regla_alerta`,
  `notificacion`, `nota`, según se vayan creando fase a fase), una debajo de otra y separadas por
  un divisor grueso.
- Cada tabla tiene:
  1. Título con el nombre y el número de filas (`nombre · N filas`).
  2. Etiqueta **Columnas** y una tabla con las propiedades de cada columna:
     Columna · Tipo · Clave primaria · No nulo · Por defecto.
  3. Un espacio y la etiqueta **Datos** con las filas de la tabla.
- Si el contenido no cabe, **toda la lista hace scroll** (con la rueda del ratón o con las flechas).
- Debajo de la lista, fijos, dos botones: **Exportar datos** y **Exportar estructura** (fase 5,
  ver `01-memoria-tecnica.md` §6.3). Deshabilitados hasta esa fase.

### Notas (fase 8)
- Tabla con **Fecha**, **Origen** (Móvil/PC) y **Contenido** — datos de la tabla `nota`.
- Botón **Añadir nota**.
- Vacía y sin botón activo hasta que la fase 8 implemente el CRUD de notas del espacio compartido.

## Comportamiento

- Al arrancar, el área de datos está vacía y ningún botón aparece marcado.
- Pulsar un botón de sección muestra su vista y carga sus datos. Cambiar de sección reemplaza la vista.
- El botón de la sección activa se resalta con el estilo "primario" del tema de Textual; igual
  para la subpestaña activa dentro de Emparejamiento.
- Los datos se leen de la base de datos SQLite en `~/.local/share/sysmote/sysmote.db`
  (creada por `agent/sysmote/schema.sql`), salvo el historial de comandos de terminal. Las rutas de
  todos los archivos del agente están en `agent/sysmote/rutas.py`.
- Consultas previstas para la sección Base de datos: `sqlite_master` para las tablas,
  `PRAGMA table_info` para las columnas y `SELECT * ... LIMIT 200` para las filas.
- **El comando `sysmote` abre la TUI y arranca el agente** (hasta que exista el servicio de la
  fase 4): HTTPS en `0.0.0.0:8443` para USB y LAN, HTTP en `127.0.0.1:8444` como puerto interno
  y el túnel iroh que reenvía a ese puerto. Al salir de la TUI se paran. Si un servidor no
  arranca (por ejemplo, un puerto ocupado) la TUI lo avisa con una notificación a los 2 segundos
  y los demás siguen funcionando.
- La TUI y la API **solo se comunican por la base de datos SQLite**, cada una con su propia
  conexión: no hay socket entre ellas.
- Los datos de Emparejamiento (dispositivo, QR, estado de los servidores) se refrescan cada
  segundo mientras la subpestaña está visible, y al cambiar de subpestaña.

### Historial de comandos de terminal
- El agente solo ve las teclas que la app manda por el WebSocket de la terminal (fase 5); lo
  escrito directamente en la ventana del PC no pasa por el agente y no se registra (una captura
  completa necesitaría integración de shell con OSC 133, descartada del TFG — ver
  `../documentos-generales-del-proyecto/06-ideas-de-futuro.md` §5).
- Cada línea enviada por la app, al pulsar Enter, se añade a un archivo de log (no a SQLite, para
  no duplicar el dato) en una carpeta dentro de `~/.cache`, formato `ISO-8601<TAB>comando`, sin
  límite de tamaño por ahora.

## Colores

- **Cambiado (20/10/2026):** se usa la paleta propia de Textual (tema por defecto), no los
  16 colores ANSI de la terminal. Con `ansi_color=True` varios colores con nombre (incluido
  el blanco) resultaron casi ilegibles en terminales con una paleta ANSI personalizada —
  depender de nombres de color no es fiable si el usuario ha recoloreado su terminal.
- La sección o subpestaña activa se marca con `variant="primary"` del propio `Button` de
  Textual (mecanismo del framework, con contraste garantizado por su tema), no con CSS propio.
- La fuente es la de la propia terminal.

## Pendiente (marcado con TODO en el código)

- Exportar datos y Exportar estructura: deshabilitados hasta la fase 5.
- Servicio: deshabilitado hasta la fase 4.
- El QR ya se muestra en la fase 3; el escáner en la app (que lo lee) llega con la fase 8, y hasta
  entonces la app introduce a mano dirección, huella, identificador iroh y código.
- Historial y Base de datos: vacíos hasta que existan acciones rápidas (fase 5) o comandos de
  terminal (fase 5) reales.
- Notas: deshabilitada hasta la fase 8.
