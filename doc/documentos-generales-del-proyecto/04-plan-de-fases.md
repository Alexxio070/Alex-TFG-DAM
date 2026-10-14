# Plan de Desarrollo por Fases: Linux System Companion

## Criterios de planificación

1. **Primero lo más arriesgado.** La conexión entre el móvil y el PC con iroh es la parte más crítica y con más incertidumbre, así que va justo después de la interfaz y las métricas (fase 2). Si da problemas, se descubre en noviembre, con tiempo para aplicar el plan B.
2. **Después, lo obligatorio y lo que más pesa en la nota.** Los requisitos mínimos del proyecto se completan entre la beta y marzo; las funciones de menor impacto, al final.
3. **Fases difíciles intercaladas con fáciles.** Así no se acumula todo lo complejo al final y cada fase difícil va seguida de un respiro.
4. **Cada fase termina con algo que funciona.** Nunca se empieza una fase dejando la anterior a medias.
5. **Una beta mínima en Navidad (decidido el 12/10/2026).** La interfaz definitiva, con *placeholders* en lo que aún no está hecho, las métricas y la conexión por iroh. Sin usuarios ni login: el agente solo expone métricas de solo lectura. Es la base sobre la que seguir añadiendo funciones y **no** necesita cumplir los requisitos mínimos.
6. **Hito de febrero:** una versión funcional con la app conectándose al PC a través de iroh, la terminal y las gráficas de rendimiento.
7. **Se parte de cero en desarrollo móvil.** Las estimaciones incluyen tiempo de aprendizaje y asumen dedicación a tiempo parcial, compaginada con clases.

**Calendario (12/10/2026):** la interfaz definitiva de la app ya está hecha (con *placeholders* y datos simulados), así que las fases empiezan antes. La terminal termina a mediados de febrero y las fases 9–10 coinciden con la redacción de la memoria en mayo. Si hay retraso, se aplica el orden de recortes.

*Fechas orientativas desde finales de septiembre de 2026. La defensa es la primera semana de junio de 2027. **Pendiente de revisión:** la fecha exacta del hito de febrero y la fecha oficial de entrega de la memoria; ajustar el plan cuando se conozcan, junto con el calendario de exámenes.*

**Leyenda de dificultad:** 🟢 fácil · 🟡 media · 🔴 difícil

---

## Decisiones

| Decisión | Estado | Cuándo resolverla |
|---|---|---|
| ¿El centro acepta Flutter? (la normativa cita "Android Studio, Kotlin, Java") | **Resuelta (26/09/2026):** el tutor acepta Flutter | — |
| ¿El agente en Python cuenta como parte del proyecto? | **Resuelta (02/10/2026):** es parte fundamental del proyecto; sin él la app no funciona | — |
| Orden de las fases | **Resuelta (02/10/2026 y 12/10/2026):** iroh en la fase 2 por ser la parte más crítica. La interfaz definitiva se hace primero (ya terminada el 12/10) y la beta se queda sin login; la seguridad va en enero, antes de la terminal | — |
| Herramienta del agente en el PC | **Resuelta (12/10/2026):** TUI con botones (Textual) al escribir `companion`; solo `companion serve` y `companion notify` quedan como comandos de terminal | — |
| Cómo se crea el usuario | **Resuelta (12/10/2026):** la TUI muestra un QR; la app lo escanea, muestra "Emparejado, se necesita crear autenticación" y abre un diálogo de usuario y contraseña | — |
| En qué fase va el registro por QR | **Resuelta (12/10/2026):** fase 9. Hasta entonces, el usuario se crea desde la TUI (fase 3) | — |
| Cómo usar iroh desde Flutter: binding de Kotlin compilado desde el código fuente + *platform channel*, o el plugin `iroh_flutter` de pub.dev | **Pendiente de revisión:** el binding de Kotlin publicado no incluye Android; las dos opciones necesitan Rust y el NDK | Al empezar la fase 2, con la prueba de concepto |
| Imágenes en el espacio compartido | **Aún pensándolo** (fuera del alcance confirmado) | Antes de la fase 9 |
| Tipo del servicio en primer plano de Android | **Pendiente de revisión:** no `dataSync`; candidato `connectedDevice` | En la fase 8 |
| ¿La red del centro deja salir HTTPS con WebSocket hacia los relés de iroh? | **Pendiente de revisión:** preguntar en el centro cómo está montada la red | Antes de la prueba en red restrictiva (fase 2) |
| Fecha exacta del hito de febrero y fecha oficial de entrega de la memoria | **Pendiente de revisión** | Cuando se conozcan |

---

## Tareas transversales (en todas las fases)

Se hacen de forma continua, no como una fase aparte. Son requisitos mínimos del proyecto.

- **Git:**
  - un repositorio con las carpetas `App-movil/` (Flutter) y `agent/` (Python);
  - ramas `main` (versiones estables), `develop` (integración) y `feature/<nombre>` (una por tarea o fase);
  - commits pequeños con formato convencional (`feat:`, `fix:`, `docs:`, `test:`, `refactor:`);
  - una etiqueta por versión (`v0.1-beta`, `v0.2`…).
- **Arquitectura en capas:**
  - *App (MVVM):* vistas (pantallas) → *viewmodels* (estado, con provider) → repositorios → servicios de red.
  - *Agente:* rutas de la API → servicios (lógica de negocio) → repositorios (acceso a BD) → modelos.
- **Base de datos:** `agent/schema.sql` como script de creación, actualizado cada vez que se añade una tabla; acceso siempre a través de repositorios.
- **Pruebas:**
  - pytest para la lógica del agente;
  - algunas pruebas de widgets en Flutter;
  - una tabla de casos de prueba manuales por fase.
- **Material para la memoria:** al cerrar cada fase, capturas de pantalla, casos de prueba realizados y decisiones tomadas.

---

## Entorno de pruebas

La red del centro puede bloquear la comunicación entre el móvil y el PC, así que el desarrollo diario **no depende de ninguna red externa**:

| Método | Cómo funciona | Cuándo usarlo |
|---|---|---|
| **USB + `adb reverse`** (principal) | `adb reverse tcp:8443 tcp:8443`: la app se conecta a `127.0.0.1:8443` en el móvil y llega al agente del portátil por el cable | Desarrollo diario, en cualquier sitio |
| **Emulador de Android** | Emulador de Android Studio en el mismo portátil; `10.0.2.2` apunta al portátil | Desarrollo sin móvil físico. Requiere virtualización activada. No se usa para iroh: oficialmente solo ARM (aarch64, armv7); x86_64 se puede compilar pero no está soportado, así que iroh se prueba en el móvil físico |
| **Punto de acceso del móvil** | El portátil se conecta al punto de acceso del móvil; ambos quedan en una red privada propia | Probar como LAN real (incluido mDNS). Puede requerir abrir el puerto en el cortafuegos del portátil |
| **Repositorio simulado** | Versión falsa del repositorio de la app que devuelve datos inventados | Trabajar en pantallas sin el agente arrancado |
| **iroh (desde la fase 2)** | Túnel P2P que empieza por un relé y luego intenta pasar a conexión directa. **No necesita abrir puertos de entrada:** basta con que salga TCP 443 (HTTPS con WebSocket) hacia los relés. El UDP saliente es opcional: si está bloqueado, todo el tráfico va por el relé (docs.iroh.computer, "Configuring networks") | Acceder al PC desde fuera de casa, siempre con un móvil físico. Primero en casa con la matriz de pruebas de la fase 2 y después en una red restrictiva (centro o Wi-Fi pública). *Pendiente de revisión: confirmar con el centro que deja salir HTTPS con WebSocket y que no hay un proxy que inspeccione el tráfico* |

**Para la defensa:** USB o punto de acceso como opción principal y un vídeo grabado como respaldo. No depender de la red del tribunal.

---

## BLOQUE 1: Beta v0.1 (objetivo: Navidad)

### Fase 0 — Preparación y aprender Flutter 🟢
**Duración:** ~3 semanas (finales de septiembre – mediados de octubre)

**Estado (12/10/2026):** la app ya tiene la interfaz definitiva completa, con *placeholders* y datos simulados (ver *ESTRUCTURA_FLUTTER.md*). El agente FastAPI mínimo pasa a la fase 1.

**Objetivos:**
- Instalar Flutter y Android Studio.
- Configurar el **entorno de pruebas**: depuración USB en el móvil, `adb reverse` y emulador.
- Crear el repositorio Git con la estructura `App-movil/` + `agent/` y las ramas `main`/`develop`.
- Aprender lo básico de Dart: variables, clases, `async`/`await`, `Future`, `Stream`.
- Hacer el tutorial oficial de Flutter (widgets, estado, navegación entre pantallas).

**Terminada cuando:** la app se ejecuta en tu móvil conectado por USB y el repositorio tiene sus primeros commits.

---

### Fase 1 — Agente y métricas reales 🟢🟡
**Duración:** ~3 semanas (mediados de octubre – principios de noviembre)

**Ya hecho:** la interfaz definitiva de la app, con todas las pantallas, la navegación, *placeholders* y datos del repositorio simulado.

**Objetivos:**
- **Agente (se crea en esta fase, carpeta `agent/`):**
  - estructura en capas desde el principio: rutas de la API → servicios → repositorios → modelos;
  - endpoint REST con CPU (total y por núcleo), RAM, swap, discos, temperaturas, carga y tiempo encendido (psutil);
  - se arranca a mano (el servicio llega en la fase 5).
- **App:**
  - repositorio real de métricas que llama al agente, junto al simulado que ya existe;
  - pantalla para indicar la dirección del agente (por defecto `127.0.0.1:8443`, para el modo USB);
  - la pantalla de métricas pasa a mostrar datos reales cada 1 s, con sus gráficas (`CustomPainter`).
- Probar por USB con `adb reverse`.

**Terminada cuando:** la pantalla de métricas muestra el estado real del portátil en vivo, con gráficas, y el resto de pantallas siguen funcionando con datos simulados.

**Si vas con retraso:** cifras reales sin gráficas en vivo; las gráficas se completan para el hito de febrero.

---

### Fase 2 — Conexión remota con iroh 🔴
**Duración:** ~6 semanas (principios de noviembre – mediados de diciembre)

**Por qué va aquí:** es la parte más crítica y con más incertidumbre del proyecto. Hacerla pronto deja margen para resolver problemas o aplicar el plan B sin poner en riesgo la beta ni el hito de febrero.

**Objetivos:**
1. **Prueba de concepto (primera semana):**
   - en el PC, reenviar el puerto local del agente a través de iroh, empezando con el binario `dumbpipe` y después con un script Python mínimo (binding oficial de iroh);
   - instalar Rust y el NDK de Android: el binding de Kotlin publicado en Maven no incluye Android y hay que compilarlo desde el código fuente (docs.iroh.computer/languages/kotlin);
   - una app Flutter de prueba, separada del proyecto, que abre el túnel. *Pendiente de revisión:* probar las dos vías (módulo Kotlin con *platform channel* sobre el binding compilado, o el plugin `iroh_flutter`) y quedarse con la que funcione antes. Se prueba en el móvil físico: oficialmente solo hay soporte para ARM (aarch64, armv7); x86_64 se puede compilar pero no está soportado.
2. **Integración en el proyecto:**
   - **Agente:** punto de conexión iroh que reenvía al servidor local; identificador iroh estable (se guarda la clave y se muestra al arrancar).
   - **App:** el túnel con la vía elegida en la prueba de concepto (módulo Kotlin con *platform channel* `openTunnel` / `closeTunnel`, o el plugin `iroh_flutter`); en la pantalla de conexión, elegir entre dirección local (USB/LAN) y túnel iroh, introduciendo el identificador a mano por ahora (el QR llega en la fase 9).
   - Sin servicio en primer plano todavía: la conexión solo se mantiene con la app abierta. El servicio en primer plano se añade en la fase 8, con las notificaciones.
3. **Matriz de pruebas en casa:**
   1. Móvil y PC en la misma Wi-Fi: la conexión debe pasar a directa.
   2. Móvil con datos móviles (4G/5G) y PC en casa: empieza por el relé y debe intentar pasar a directa.
   3. Bloquear el UDP saliente en el cortafuegos del PC para simular una red restrictiva: todo el tráfico debe ir por el relé y seguir funcionando.
   4. Cambiar de Wi-Fi a datos móviles en mitad del uso: comprobar la reconexión.
   5. Reiniciar el agente y el PC: el identificador iroh debe ser el mismo (la parte de arranque automático se completa en la fase 5).
4. **Prueba en red restrictiva:** cuando todo funcione en casa, repetir la conexión desde el centro o una Wi-Fi pública.

**⚠️ Seguridad hasta la fase 3 (incluida la beta):** hasta que exista el login, cualquiera que conozca el identificador iroh puede llegar al agente. Mientras tanto, el agente solo expone las métricas (solo lectura), el identificador no se comparte y el agente se arranca a mano solo para probar.

**Al terminar:** generar el APK y publicarlo como release `v0.1-beta`.

**Terminada cuando:** las métricas de la fase 1 se ven en el móvil desde datos móviles contra el PC de casa, y la matriz de pruebas está documentada.

**Plan B:** si iroh no funciona, documentar por qué en la memoria, seguir en modo LAN (USB, punto de acceso o misma Wi-Fi) y dejar el acceso remoto como trabajo en curso, con la prueba de concepto como evidencia.

---

### ✅ Qué es la beta v0.1 (mediados de diciembre – Navidad)
> Una app Android con la interfaz definitiva (lo que aún no está hecho muestra *placeholders*) que se conecta al PC de casa desde cualquier red a través de iroh y muestra las métricas en vivo con gráficas. Sin login: el agente solo expone métricas de solo lectura y se arranca a mano.

**Recortes posibles si vas con retraso, en este orden:**
1. Gráficas (dejar solo cifras y completarlas para el hito de febrero).
2. Prueba en red restrictiva (dejarla para enero).

**Nunca se recorta:** la interfaz navegable y la conexión por iroh. Si iroh no funciona, se aplica el plan B de la fase 2.

**Requisitos mínimos del proyecto que ya cumple la beta:** interfaz y navegación, Git y capas.
**Pendientes después de la beta:** login y BD (fase 3), manual de instalación (fase 5), lógica de negocio (fases 6 y 7), CRUD de dos entidades y BD de 3–4 tablas con contenido gestionado por el usuario (fase 7).

---

## BLOQUE 2: Núcleo del TFG (mediados de diciembre – mayo)

### Fase 3 — Seguridad 🔴
**Duración:** ~3 semanas (mediados de diciembre – principios de enero, con las vacaciones de Navidad)

**Por qué va aquí:** la terminal (fase 4) da acceso a tu shell, así que no puede exponerse por iroh sin login.

**Objetivos:**
- **TUI mínima con Textual** (al escribir `companion` se abre la interfaz con botones) y **Typer** solo para `companion serve`:
  - botón de configuración inicial: generar el certificado TLS autofirmado y crear el usuario y la contraseña (validación de robustez y Argon2). Es la vía hasta la fase 9, cuando llega el registro por QR;
  - mostrar como texto la dirección, la huella del certificado y el identificador iroh;
  - botones «Cambiar contraseña» y «Cerrar todas las sesiones».
- **Base de datos:** primeras tablas (`usuario`, `sesion`, `intento_login`) en `schema.sql`, con sus repositorios.
- **Agente:**
  - HTTPS;
  - login que devuelve un token de sesión aleatorio (guardado con hash);
  - todas las rutas protegidas;
  - límite de intentos con esperas crecientes.
- **App:**
  - la pantalla de login (ya diseñada en la fase 1) con validaciones (campos obligatorios, mensajes de error claros);
  - en la primera conexión, mostrar la huella del certificado para compararla con la de la TUI y guardarla (*certificate pinning*);
  - token en `flutter_secure_storage`.
- Comprobar que todo funciona igual por USB y a través del túnel iroh.

**Terminada cuando:** sin login no se puede hacer nada (tampoco por iroh), un certificado distinto es rechazado y «Cerrar todas las sesiones» expulsa al móvil.

**Lo que no se recorta:** el login y el TLS.

---

### Fase 4 — Terminal (v0.2) 🔴
**Duración:** ~5 semanas (enero – mediados de febrero)

**Objetivos:**
- **Prototipos previos** (antes de implementar; ver `doc/agente/terminal-sesiones-tmux.md`, §9): cierre de la sesión al cerrar la ventana del PC, historial sin duplicados al reenganchar, apertura de la ventana en kitty y Konsole, versión mínima de tmux y supervivencia al reinicio del agente.
- **Agente:**
  - sesiones de terminal sobre **tmux** con `$SHELL -l`: crear, listar y cerrar (`/terminales`);
  - WebSocket `/ws/terminal/{id}` que engancha a una sesión, reenvía su salida y las teclas, y recupera el historial al reenganchar;
  - ventana en la terminal gráfica del usuario (si hay sesión gráfica) conectada a la misma sesión;
  - la sesión termina con `exit`, al cerrar su ventana en la app (`DELETE`) o al cerrar su ventana en el PC;
  - redimensionado con `TIOCSWINSZ` y *keepalive* para detectar un móvil que desaparece;
  - sin tmux: PTY ligado a la conexión, con aviso.
- **App:**
  - xterm.dart conectado al WebSocket de la sesión;
  - reenganche a la sesión al volver a abrir la app;
  - sin sesiones activas, terminal vacía con aviso de que tocar o escribir abre una ventana en el PC; la sesión se crea al primer toque o tecla y la app guarda las teclas hasta estar enganchada;
  - al abrir la app, `GET /terminales` restaura solo las pestañas propias que seguían abiertas al cerrarla;
  - barra de teclas especiales (Ctrl, Alt, Tab, Esc, flechas);
  - Nerd Font incluida;
  - redimensionado al girar el móvil.
- Pruebas con Zsh, un prompt tipo Starship y programas a pantalla completa (`htop`, `vim`), por USB y a través de iroh (también por relé, para comprobar que la latencia es usable).
- Pruebas de persistencia: dejar un comando largo en marcha, cerrar la app, limpiarla de recientes y cortar la red; comprobar que sigue y que se recupera la salida al volver.
- **Ampliación opcional** (solo si una sesión funciona bien y sin fallos): **varias pestañas** en la app, como las de un navegador. Cada pestaña es una terminal independiente (una sesión de tmux y una ventana del PC); cerrar la pestaña cierra su terminal en el PC. Requiere diseñar la barra de pestañas en `doc/ui/`.

**Terminada cuando:** puedes trabajar con tu shell real desde el móvil, incluidos `htop` y `vim`, desde fuera de casa, y un comando largo sigue ejecutándose tras cerrar la app y se recupera al volver a abrirla.

**Nunca se recorta:** es la función estrella del proyecto.

---

### 🎯 Hito de febrero
> La app se conecta al agente Python del PC a través de iroh y ofrece la terminal y las gráficas de rendimiento.

*Pendiente de revisión: fecha exacta de la presentación.* Las gráficas se hacen en la fase 1 (o, si se recortaron, antes del hito); para el hito hay que tener el login (fase 3) y la terminal a través de iroh (fase 4). La terminal termina a mediados de febrero: si el hito es antes, hay que ajustar.

---

### Fase 5 — Instalación y servicio 🟡
**Duración:** ~1 semana (finales de febrero)

**Objetivos:**
- Empaquetar el agente para instalarlo con `pipx install`.
- Documentar y comprobar las dependencias del sistema: `tmux` y una terminal gráfica para la ventana del PC. La TUI avisa si faltan.
- Botones de la TUI «Instalar servicio», «Quitar servicio» y «Estado»: servicio systemd de usuario que ejecuta `companion serve` (`default.target`, `Restart=on-failure`), con el punto de conexión iroh activo desde el arranque.
- README con:
  - instalación (`pipx install` y la TUI);
  - uso básico;
  - cómo probar por USB y por iroh;
  - **nota sobre reinicio remoto:** `loginctl enable-linger $USER` y sus limitaciones.
- Probar la instalación desde cero, repetir la prueba 5 de la matriz de la fase 2 (el identificador iroh sobrevive al reinicio del PC) y hacer capturas para la memoria.

**Terminada cuando:** en un equipo limpio, con `pipx install`, la TUI y el APK, todo funciona, también por iroh, y sobrevive a un reinicio.

---

### Fase 6 — Energía y procesos 🟢🟡
**Duración:** ~2 semanas (principios – mediados de marzo)

**Objetivos:**
- **Agente:**
  - apagar, reiniciar, suspender, hibernar (solo si está disponible) y bloquear sesión vía systemd-logind (dbus-fast). Para bloquear se usa `Session.Lock()` sobre la sesión del propio usuario (`LockSessions()` exige permisos de administrador);
  - listado de procesos;
  - finalización con SIGTERM y, si sigue vivo, opción de SIGKILL.
- **App:**
  - botones de energía con confirmación;
  - lista de procesos con búsqueda y orden por CPU y RAM;
  - mensajes claros cuando no se puede finalizar un proceso de otro usuario o polkit deniega una acción.

**Terminada cuando:** puedes apagar, reiniciar y bloquear el portátil y finalizar un proceso colgado desde el móvil.

**Nota:** las pruebas de apagado y reinicio se hacen mejor en una máquina virtual o al final de cada sesión de trabajo. Si se apaga el PC a través de iroh, no se puede volver a encender desde el móvil (ver Wake-on-LAN en las ideas de futuro).

---

### Fase 7 — CRUD de acciones rápidas 🟡
**Duración:** ~3 semanas (mediados de marzo – principios de abril)

**Por qué es importante:** completa los requisitos mínimos obligatorios (CRUD de dos entidades relacionadas y BD de 3–4 tablas).

**Modelo de datos:**
```
usuario ──1:N── grupo ──1:N── accion_rapida ──1:N── ejecucion
```

**Objetivos:**
- **BD:**
  - tablas `grupo` (con `color` y `orden`), `accion_rapida` (con `icono` y `orden`) y `ejecucion` en `schema.sql`, con repositorios;
  - diagrama entidad-relación completo para la memoria.
- **Agente:**
  - CRUD de grupos y acciones, y `PUT /orden` para guardar el orden de la cuadrícula;
  - ejecución en segundo plano con timeout (corta con SIGTERM → SIGKILL a todo el grupo de procesos, con `start_new_session=True` y `os.killpg`);
  - una sola ejecución a la vez por acción;
  - salida recortada a un tamaño máximo;
  - historial de ejecuciones con filtros por acción, estado y fechas;
  - estadísticas por acción: número de ejecuciones, tasa de éxito, duración media y última ejecución.
- **Reglas de negocio:**
  - al borrar un grupo con acciones, elegir entre moverlas a "Sin grupo" o borrarlas;
  - nombre único dentro de cada grupo;
  - una carpeta solo contiene acciones (un único nivel) y la cuadrícula admite hasta 40 elementos de primer nivel.
- **App:**
  - cuadrícula de inicio con acciones y carpetas (ya diseñada en la fase 1 con datos simulados): se conecta al agente para cargar, guardar el orden, crear, editar y borrar;
  - edición de carpeta (nombre y color) y creación rápida de acción (nombre, comando y confirmación);
  - ficha de acción editable (directorio, timeout y «notificar al terminar», con validaciones: nombre obligatorio y sin duplicados, comando obligatorio, timeout entre 1 y 3600 s, directorio existente validado por el agente), con estadísticas y botón "Ejecutar"; el acceso a la ficha se define aquí;
  - historial y detalle de ejecución con la salida del comando.
- Validación doble: en la app (respuesta inmediata) y en el agente (seguridad real).
- Opcional: mostrar la salida de las ejecuciones con xterm.dart (fase 4) para conservar los colores.
- **Exportaciones desde la TUI** (detalle en *01-memoria-tecnica.md*, 6.3), al escritorio del usuario (`XDG_DESKTOP_DIR`, o la carpeta personal si no existe):
  - «Exportar datos»: un JSON `companion-datos-AAAAMMDD-HHMM.json` con una sección por tabla, sin `sesion`, `intento_login` ni el hash de la contraseña;
  - «Exportar estructura»: carpeta `companion-estructura-AAAAMMDD-HHMM/` con `tablas.sql`, `indices.sql`, `vistas.sql` y `triggers.sql`, leídos de `sqlite_schema`.

**Terminada cuando:** puedes crear el grupo "Proyecto", añadirle la acción "Actualizar repo", ejecutarla desde el móvil, ver su salida, consultar su historial y estadísticas, editarla y borrarla, y los dos botones de exportación dejan sus archivos en el escritorio.

**Nunca se recorta:** es requisito mínimo.

---

### Fase 8 — Notificaciones, reglas de alerta y servicio en primer plano 🟡🔴
**Duración:** ~3 semanas (abril)

**Objetivos:**
- **Agente:**
  - WebSocket `/ws/events`;
  - socket Unix `$XDG_RUNTIME_DIR/companion.sock` (permisos `0600`);
  - comando `companion notify "mensaje"`.
- **BD:** tablas `regla_alerta` y `notificacion` (relación regla 1:N notificaciones).
- **Reglas de alerta con CRUD completo desde la app:** métrica, operador, umbral, duración sostenida, tiempo mínimo entre avisos y activa/inactiva.
- **Historial de notificaciones** con búsqueda, filtros, marcar como leída y borrar.
- **App:**
  - servicio en primer plano que mantiene el túnel iroh y la conexión con `/ws/events` con la app en segundo plano. Hay que declarar su tipo (obligatorio desde Android 14): no `dataSync`, que en apps con `targetSdk` 35 o superior (Android 15) se detiene tras 6 h cada 24 en segundo plano; candidato `connectedDevice` *(pendiente de revisión, se confirma en esta fase)*, que exige declarar en el manifiesto el permiso `FOREGROUND_SERVICE_CONNECTED_DEVICE` y al menos uno de `CHANGE_NETWORK_STATE`, `CHANGE_WIFI_STATE` o `CHANGE_WIFI_MULTICAST_STATE` (u otra de las alternativas: `NFC`, `TRANSMIT_IR`, Bluetooth, UWB o USB);
  - los eventos se muestran con `flutter_local_notifications`. Hay que pedir el permiso `POST_NOTIFICATIONS` en tiempo de ejecución (Android 13+); sin él no se ven los avisos. *Cubre el elemento diferenciador "notificaciones / servicios en segundo plano".*
- Opción "notificar al terminar" en las acciones rápidas de la fase 7.
- Ejemplos documentados:
  - `make && companion notify "Compilación terminada"`;
  - un *hook* de Claude Code.

**Terminada cuando:** con el móvil bloqueado y fuera de casa recibes un aviso al terminar un comando en el PC y cuando salta una regla de alerta.

---

### Fase 9 — Descubrimiento, emparejamiento y espacio compartido 🟡
**Duración:** ~3 semanas (finales de abril – mediados de mayo)

**Objetivos:**
- **mDNS:** el agente se anuncia (zeroconf) y la app lo encuentra sin escribir la dirección (bonsoir). Se prueba con el punto de acceso del móvil.
- **QR de emparejamiento:** botón de la TUI que muestra el QR (dirección, huella e identificador iroh) para emparejar otro móvil o la app reinstalada; la app lo escanea (`mobile_scanner`), rellena los datos y pide el login. *Cubre el elemento diferenciador "uso de sensores/cámara".*
- **Registro por QR** (sustituye a la creación del usuario desde la TUI de la fase 3):
  - la TUI muestra un QR (`qrcode`) con la dirección, la huella del certificado, el identificador iroh y un código de registro de un solo uso con caducidad corta;
  - la app lo escanea (`mobile_scanner`), guarda la huella, muestra "Emparejado, se necesita crear autenticación" y abre el diálogo de usuario y contraseña (con confirmación y validación de robustez);
  - el agente guarda la contraseña con Argon2 y cierra el modo registro tras la primera cuenta.
- **Espacio compartido** (notas de texto y enlaces entre el móvil y el PC):
  - **BD:** tabla `nota` en `schema.sql`, con su repositorio;
  - **Agente:** CRUD de notas (`/notas`) y botones de la TUI para añadir y ver notas;
  - **App:** lista de notas con buscador y recarga al deslizar; tarjetas con texto seleccionable y enlaces pulsables en cualquier parte del texto, con botones de copiar y editar; formulario de un único campo (contenido obligatorio) para crear y editar, y borrado con confirmación. El tipo (texto o enlace) lo deduce el agente al guardar;
  - la app pide las notas al abrir la pantalla y al deslizar hacia abajo para recargar (sin actualización al momento); si los dos lados editan la misma nota, se guarda el último cambio;
  - *imágenes: **aún pensándolo**, fuera del alcance confirmado.*

**Terminada cuando:** una instalación nueva se empareja y crea la cuenta escaneando un QR, y una nota guardada desde el móvil aparece en el PC al consultarla (y al revés).

---

### Fase 10 — Pulido 🟢
**Duración:** ~2 semanas (mayo)

**Objetivos:**
- Revisión general:
  - mensajes de error comprensibles;
  - estados de carga;
  - reconexión automática y cambio automático entre conexión local y túnel iroh;
  - pruebas de instalación desde cero.
- Completar las pruebas automáticas y la tabla de casos de prueba.
- Manual de usuario (uso de cada pantalla, con capturas).

**Terminada cuando:** la app se siente como un producto terminado, no como un prototipo.

---

## Si vas con retraso después de la beta

Recortar en este orden (lo primero es lo que menos se pierde):

1. **Reglas de alerta con CRUD** (fase 8): mantener solo `companion notify`.
2. **mDNS** (fase 9): el QR ya evita escribir la dirección.
3. **Hibernar y ordenación de procesos** (fase 6): dejar el listado y el botón de finalizar.
4. **Registro por QR** (fase 9): mantener la creación del usuario desde la TUI.

**Nunca se recortan:** conexión por iroh (o su plan B documentado), terminal (función estrella), CRUD de acciones rápidas (requisito mínimo), login y TLS, y pulido mínimo de errores.

---

## BLOQUE 3: Si da tiempo

### Temas de la terminal 🟢
- Paleta de colores configurable en la app.
- Opcional: importar los colores del esquema del PC.

---

## Redacción y defensa (mayo – primera semana de junio)

**Memoria final** (*pendiente de revisión: fecha oficial de entrega*):
- introducción y justificación;
- planificación;
- tecnologías;
- diseño de la BD (diagrama entidad-relación);
- diagrama de casos de uso;
- capturas;
- pruebas (incluida la matriz de pruebas de iroh);
- manual de instalación y de uso;
- estado del arte actualizado;
- decisiones tomadas en cada fase.

**Demo recomendada:**
1. Instalar el agente.
2. Emparejar por QR.
3. Mostrar las métricas.
4. Usar la terminal.
5. Ejecutar una acción rápida y ver su historial.
6. Finalizar un proceso.
7. Recibir una notificación al terminar un comando.
8. Apagar el PC.

Si la red lo permite, hacerlo todo desde datos móviles contra el PC de casa a través de iroh.

**Respaldo:** conexión por USB o punto de acceso y vídeo grabado de la demo.

---

## Resumen visual

| Fase | Contenido | Dificultad | Fechas orientativas |
|---|---|---|---|
| 0 | Preparación, entorno de pruebas y Flutter | 🟢 | Sep – Oct |
| 1 | Agente y métricas reales (interfaz ya hecha) | 🟢🟡 | Oct – Nov |
| 2 | Conexión remota con iroh (prueba de concepto, integración y pruebas) | 🔴 | Nov – Dic |
| **Beta v0.1** | Interfaz + métricas por iroh, sin login | | **Mediados de diciembre – Navidad** |
| 3 | Seguridad (TUI mínima y login) | 🔴 | Dic – Ene |
| 4 | Terminal (v0.2) | 🔴 | Ene – Feb |
| **Hito** | iroh + terminal + gráficas | | **Febrero** (fecha pendiente de revisión) |
| 5 | Instalación y servicio | 🟡 | Feb |
| 6 | Energía y procesos | 🟢🟡 | Mar |
| 7 | CRUD de acciones rápidas y exportaciones | 🟡 | Mar – Abr |
| 8 | Notificaciones, reglas de alerta y servicio en primer plano | 🟡🔴 | Abr |
| 9 | mDNS, QR, registro por QR y espacio compartido | 🟡 | Abr – May |
| 10 | Pulido | 🟢 | May |
| Memoria | Redacción final | | May (entrega pendiente de revisión) |
| **Defensa** | | | **Primera semana de junio** |
| Extra | Temas de terminal | 🟢 | Si da tiempo |

## Cobertura de los requisitos mínimos

| Requisito | Dónde se cubre |
|---|---|
| App Android | Todo el proyecto (Flutter, aceptado por el tutor) |
| Capas, Git, manual de instalación | Tareas transversales · Fase 5 |
| Interfaz, navegación, validaciones | Interfaz definitiva (ya hecha) · fase 3 (login) · formularios de las fases 7, 8 y 9 |
| Registro / login | Login: fase 3 (usuario creado desde la TUI) · Registro por QR: fase 9 |
| CRUD de 2 entidades relacionadas | **Fase 7** (grupo y acción rápida) · refuerzo en la fase 8 (regla de alerta) y la fase 9 (nota) |
| Lógica de negocio | Filtros de procesos (fase 6), estadísticas y reglas (fase 7), umbrales (fase 8) |
| Gestión de errores | Todas las fases · revisión en la fase 10 |
| BD de 3–4 tablas con relaciones, `schema.sql`, repositorios | Fase 3 (3 tablas) · fase 7 (6 tablas) · fase 8 (8 tablas) · fase 9 (9 tablas) |
| Documentación completa | Material por fase · redacción final |
| Elemento diferenciador | P2P con iroh (fase 2), terminal remota (fase 4), servicios en segundo plano y notificaciones (fase 8), cámara/QR (fase 9) |
