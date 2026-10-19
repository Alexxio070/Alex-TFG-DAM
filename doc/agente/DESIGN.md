# Linux System Companion — especificación de la TUI

Aplicación de terminal (Textual, Python) para gestionar el emparejamiento con la app Android,
la seguridad y el servicio del propio agente, ver el historial de acciones y consultar la base
de datos SQLite local.

**Origen:** boceto inicial aportado por alex (estructura, banner, colores, comportamiento de
Emparejamiento/Historial/Base de datos). Las subpestañas de Emparejamiento (Seguridad, Servicio)
y el botón Notas se añadieron después para cubrir las fases del proyecto que el boceto inicial
no contemplaba (fase 3, fase 5, fase 9). El esquema de datos y las rutas son los ya documentados
en `../documentos-generales-del-proyecto/01-memoria-tecnica.md` (§6) y `03-system-context.md`
(§5), no los de ejemplo del boceto original.

## Estructura (de arriba abajo, todo a ancho completo)

1. **Banner** — nombre de la app en arte ASCII ANSI Shadow, en una sola línea:
   "LINUX" y "SYSTEM" uno al lado del otro. Color verde, en negrita. Línea inferior gruesa.
2. **Área de datos** — un marco redondeado con el título "Datos" arriba a la izquierda.
   Ocupa todo el espacio libre. Por defecto está **vacía**; muestra la sección del botón pulsado.
3. **Barra de botones** — cuatro botones de igual anchura, en este orden:
   "Emparejamiento", "Historial", "Base de datos", "Notas".
4. **Pie** — atajo `q` para salir.

## Secciones (contenido del área de datos)

### Emparejamiento

Tres subpestañas propias, que cambian el contenido del mismo marco sin volver al menú principal:

#### Dispositivo
- Izquierda: código QR de emparejamiento (texto con bloques `▀ ▄ █`, usando la librería `qrcode`).
  Si `qrcode` no está instalada, muestra el texto del emparejamiento.
- Derecha: nombre del dispositivo, fecha y hora de conexión, estado de conexión — datos de `sesion`.
- Debajo de los datos del dispositivo: botón rojo **Desemparejar**.
  Está desactivado si no hay ningún dispositivo emparejado.

#### Seguridad (fase 3)
- Texto: dirección del agente, huella del certificado TLS, identificador iroh (cuando exista).
- Botón **Configuración inicial**: genera el certificado TLS autofirmado y crea el usuario y la
  contraseña (validación de robustez y Argon2). Es la vía hasta la fase 9, cuando llega el
  registro por QR.
- Botones **Cambiar contraseña** y **Cerrar todas las sesiones**: deshabilitados hasta que existe
  una cuenta creada.

#### Servicio (fase 5)
- Botones **Instalar servicio**, **Quitar servicio** y **Estado**: gestionan el servicio systemd
  de usuario que ejecuta `companion serve`.
- Deshabilitados hasta la fase 5.

### Historial
- Tabla con tres columnas: **Fecha y hora** (dd/mm/aaaa hh:mm:ss), **Origen** y **Comando**.
- Origen: `MACRO` (ejecuciones de acciones rápidas, tabla `ejecucion`, fase 7) o `TERMINAL`
  (comandos enviados desde la app en la terminal, fase 4 — ver más abajo).
- Las dos fuentes se combinan **solo al mostrarlas**, sin guardarlas juntas: `ejecucion` es una
  tabla SQLite y los comandos de terminal vienen de un archivo de log aparte (ver "Historial de
  comandos de terminal").
- Orden: lo más reciente primero. Las filas se pueden seleccionar con el cursor.
- Vacía hasta que exista alguna de las dos fuentes.

### Base de datos
- Lista de **todas las tablas** del esquema real (`usuario`, `sesion`, `intento_login`, `grupo`,
  `accion_rapida`, `ejecucion`, `regla_alerta`, `notificacion`, `nota`, según se vayan creando
  fase a fase), una debajo de otra y separadas por un divisor grueso.
- Cada tabla tiene:
  1. Título con el nombre y el número de filas (`nombre · N filas`).
  2. Etiqueta **Columnas** y una tabla con las propiedades de cada columna:
     Columna · Tipo · Clave primaria · No nulo · Por defecto.
  3. Un espacio y la etiqueta **Datos** con las filas de la tabla.
- Si el contenido no cabe, **toda la lista hace scroll** (con la rueda del ratón o con las flechas).
- Debajo de la lista, fijos, dos botones: **Exportar datos** y **Exportar estructura** (fase 7,
  ver `01-memoria-tecnica.md` §6.3). Deshabilitados hasta esa fase.

### Notas (fase 9)
- Tabla con **Fecha**, **Origen** (Móvil/PC) y **Contenido** — datos de la tabla `nota`.
- Botón **Añadir nota**.
- Vacía y sin botón activo hasta que la fase 9 implemente el CRUD de notas del espacio compartido.

## Comportamiento

- Al arrancar, el área de datos está vacía y ningún botón aparece marcado.
- Pulsar un botón de sección muestra su vista y carga sus datos. Cambiar de sección reemplaza la vista.
- El botón de la sección activa se resalta (fondo y borde azules); igual para la subpestaña activa
  dentro de Emparejamiento.
- Los datos se leen de la base de datos SQLite en `~/.local/share/companion/companion.db`
  (creada por `agent/schema.sql`), salvo el historial de comandos de terminal.
- Consultas de la base de datos: `sqlite_master` para las tablas, `PRAGMA table_info` para las
  columnas y `SELECT * ... LIMIT 200` para las filas.

### Historial de comandos de terminal
- El agente solo ve las teclas que la app manda por el WebSocket de la terminal (fase 4); lo
  escrito directamente en la ventana del PC no pasa por el agente y no se registra (una captura
  completa necesitaría integración de shell con OSC 133, descartada del TFG — ver
  `../documentos-generales-del-proyecto/06-ideas-de-futuro.md` §5).
- Cada línea enviada por la app, al pulsar Enter, se añade a un archivo de log (no a SQLite, para
  no duplicar el dato) en una carpeta dentro de `~/.cache`, formato `ISO-8601<TAB>comando`, sin
  límite de tamaño por ahora.

## Colores

- Se usan los 16 colores ANSI del tema de la terminal (`ansi_green`, `ansi_blue`, `ansi_cyan`,
  `ansi_red`, `ansi_bright_black`, etc.), no la paleta fija de Textual.
- La app se crea con `ansi_color=True`.
- La fuente es la de la propia terminal.

## Pendiente (marcado con TODO en el código)

- Desemparejar, Exportar datos y Exportar estructura: solo muestran un aviso hasta sus fases.
- Dispositivo emparejado y código QR: sin datos hasta la fase 9 (registro/emparejamiento real).
- Seguridad y Servicio: deshabilitados hasta las fases 3 y 5.
- Historial y Base de datos: vacíos hasta que existan acciones rápidas (fase 7) o comandos de
  terminal (fase 4) reales.
- Notas: deshabilitada hasta la fase 9.
