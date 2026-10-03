# Plan de Desarrollo por Fases: Linux System Companion

## Criterios de planificación

1. **Primero lo más arriesgado.** La conexión entre el móvil y el PC con iroh es la parte más crítica y con más incertidumbre, así que va justo después de las métricas (fase 2). Si da problemas, se descubre en noviembre, con tiempo para aplicar el plan B.
2. **Después, lo obligatorio y lo que más pesa en la nota.** Los requisitos mínimos del proyecto se completan entre la beta y marzo; las funciones de menor impacto, al final.
3. **Fases difíciles intercaladas con fáciles.** Así no se acumula todo lo complejo al final y cada fase difícil va seguida de un respiro.
4. **Cada fase termina con algo que funciona.** Nunca se empieza una fase dejando la anterior a medias.
5. **Una beta funcional y bien estructurada en Navidad.** Pocas funciones (métricas, conexión por iroh, login e instalación), pero completas y sólidas, como base sobre la que seguir añadiendo funciones. La beta **no** necesita cumplir todos los requisitos mínimos.
6. **Hito de febrero:** una versión funcional con la app conectándose al PC a través de iroh, la terminal y las gráficas de rendimiento.
7. **Se parte de cero en desarrollo móvil.** Las estimaciones incluyen tiempo de aprendizaje y asumen dedicación a tiempo parcial, compaginada con clases.

*Fechas orientativas desde finales de septiembre de 2026. La defensa es la primera semana de junio de 2027. **Pendiente de revisión:** la fecha exacta del hito de febrero y la fecha oficial de entrega de la memoria; ajustar el plan cuando se conozcan, junto con el calendario de exámenes.*

**Leyenda de dificultad:** 🟢 fácil · 🟡 media · 🔴 difícil

---

## Decisiones

| Decisión | Estado | Cuándo resolverla |
|---|---|---|
| ¿El centro acepta Flutter? (la normativa cita "Android Studio, Kotlin, Java") | **Resuelta (26/09/2026):** el tutor acepta Flutter | — |
| ¿El agente en Python cuenta como parte del proyecto? | **Resuelta (02/10/2026):** es parte fundamental del proyecto; sin él la app no funciona | — |
| Orden de las fases | **Resuelta (02/10/2026):** iroh pasa a la fase 2 (noviembre) por ser la parte más crítica | — |
| Registro de usuario en la app (código de un solo uso + formulario) frente a creación por CLI | **Pendiente de revisión** | Antes de la fase 9 |
| Cómo usar iroh desde Flutter: binding de Kotlin compilado desde el código fuente + *platform channel*, o el plugin `iroh_flutter` de pub.dev | **Pendiente de revisión:** el binding de Kotlin publicado no incluye Android; las dos opciones necesitan Rust y el NDK | Al empezar la fase 2, con la prueba de concepto |
| Tipo del servicio en primer plano de Android | **Pendiente de revisión:** no `dataSync`; candidato `connectedDevice` | En la fase 8 |
| ¿La red del centro deja salir HTTPS con WebSocket hacia los relés de iroh? | **Pendiente de revisión:** preguntar en el centro cómo está montada la red | Antes de la prueba en red restrictiva (fase 2) |
| Fecha exacta del hito de febrero y fecha oficial de entrega de la memoria | **Pendiente de revisión** | Cuando se conozcan |

---

## Tareas transversales (en todas las fases)

Se hacen de forma continua, no como una fase aparte. Son requisitos mínimos del proyecto.

- **Git:**
  - un repositorio con las carpetas `app/` (Flutter) y `agent/` (Python);
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
| **Emulador de Android** | Emulador de Android Studio en el mismo portátil; `10.0.2.2` apunta al portátil | Desarrollo sin móvil físico. Requiere virtualización activada. No sirve para iroh (su binding para Android solo admite ARM) |
| **Punto de acceso del móvil** | El portátil se conecta al punto de acceso del móvil; ambos quedan en una red privada propia | Probar como LAN real (incluido mDNS). Puede requerir abrir el puerto en el cortafuegos del portátil |
| **Repositorio simulado** | Versión falsa del repositorio de la app que devuelve datos inventados | Trabajar en pantallas sin el agente arrancado |
| **iroh (desde la fase 2)** | Túnel P2P que empieza por un relé y luego intenta pasar a conexión directa. **No necesita abrir puertos de entrada:** basta con que salga TCP 443 (HTTPS con WebSocket) hacia los relés. El UDP saliente es opcional: si está bloqueado, todo el tráfico va por el relé (docs.iroh.computer, "Configuring networks") | Acceder al PC desde fuera de casa, siempre con un móvil físico. Primero en casa con la matriz de pruebas de la fase 2 y después en una red restrictiva (centro o Wi-Fi pública). *Pendiente de revisión: confirmar con el centro que deja salir HTTPS con WebSocket y que no hay un proxy que inspeccione el tráfico* |

**Para la defensa:** USB o punto de acceso como opción principal y un vídeo grabado como respaldo. No depender de la red del tribunal.

---

## BLOQUE 1: Beta v0.1 (objetivo: Navidad)

### Fase 0 — Preparación y aprender Flutter 🟢
**Duración:** ~3 semanas (finales de septiembre – mediados de octubre)

**Objetivos:**
- Instalar Flutter y Android Studio.
- Configurar el **entorno de pruebas**: depuración USB en el móvil, `adb reverse` y emulador.
- Crear el repositorio Git con la estructura `app/` + `agent/` y las ramas `main`/`develop`.
- Aprender lo básico de Dart: variables, clases, `async`/`await`, `Future`, `Stream`.
- Hacer el tutorial oficial de Flutter (widgets, estado, navegación entre pantallas).
- Crear un agente FastAPI mínimo con un endpoint `/hello` y una app que lo llame por USB y muestre la respuesta.

**Terminada cuando:** la app, en tu móvil conectado por USB, muestra un dato enviado por tu portátil, y el repositorio tiene sus primeros commits.

---

### Fase 1 — Métricas 🟢
**Duración:** ~2 semanas (mediados – finales de octubre)

**Objetivos:**
- **Agente:** endpoint REST con CPU (total y por núcleo), RAM, swap, discos, temperaturas, carga y tiempo encendido (psutil). Estructura en capas desde el principio.
- **App:**
  - pantalla para indicar la dirección del agente (por defecto `127.0.0.1:8443`, para el modo USB);
  - pantalla de métricas que se actualiza cada 1–2 s;
  - gráfica de CPU y RAM (`fl_chart`);
  - estructura MVVM con repositorio real y repositorio simulado.

**Terminada cuando:** ves en el móvil el estado del portátil en vivo, con gráficas.

**Si vas con retraso:** muestra cifras sin gráficas y añádelas más adelante (las gráficas forman parte del hito de febrero).

---

### Fase 2 — Conexión remota con iroh 🔴
**Duración:** ~4 semanas (noviembre)

**Por qué va aquí:** es la parte más crítica y con más incertidumbre del proyecto. Hacerla pronto deja margen para resolver problemas o aplicar el plan B sin poner en riesgo la beta ni el hito de febrero.

**Objetivos:**
1. **Prueba de concepto (primera semana):**
   - en el PC, reenviar el puerto local del agente a través de iroh, empezando con el binario `dumbpipe` y después con un script Python mínimo (binding oficial de iroh);
   - instalar Rust y el NDK de Android: el binding de Kotlin publicado en Maven no incluye Android y hay que compilarlo desde el código fuente (docs.iroh.computer/languages/kotlin);
   - una app Flutter de prueba, separada del proyecto, que abre el túnel. *Pendiente de revisión:* probar las dos vías (módulo Kotlin con *platform channel* sobre el binding compilado, o el plugin `iroh_flutter`) y quedarse con la que funcione antes. Se prueba en el móvil físico: en Android solo hay soporte para ARM y no funciona en el emulador x86_64.
2. **Integración en el proyecto:**
   - **Agente:** punto de conexión iroh que reenvía al servidor local; identificador iroh estable (se guarda la clave y se muestra al arrancar).
   - **App:** módulo Kotlin del túnel (partiendo de la prueba de concepto); *platform channel* `openTunnel` / `closeTunnel`; en la pantalla de conexión, elegir entre dirección local (USB/LAN) y túnel iroh, introduciendo el identificador a mano por ahora (el QR llega en la fase 9).
   - Sin servicio en primer plano todavía: la conexión solo se mantiene con la app abierta. El servicio en primer plano se añade en la fase 8, con las notificaciones.
3. **Matriz de pruebas en casa:**
   1. Móvil y PC en la misma Wi-Fi: la conexión debe pasar a directa.
   2. Móvil con datos móviles (4G/5G) y PC en casa: empieza por el relé y debe intentar pasar a directa.
   3. Bloquear el UDP saliente en el cortafuegos del PC para simular una red restrictiva: todo el tráfico debe ir por el relé y seguir funcionando.
   4. Cambiar de Wi-Fi a datos móviles en mitad del uso: comprobar la reconexión.
   5. Reiniciar el agente y el PC: el identificador iroh debe ser el mismo (la parte de arranque automático se completa en la fase 4).
4. **Prueba en red restrictiva:** cuando todo funcione en casa, repetir la conexión desde el centro o una Wi-Fi pública.

**⚠️ Seguridad entre las fases 2 y 3:** hasta que exista el login, cualquiera que conozca el identificador iroh puede llegar al agente. Mientras tanto, el agente solo expone las métricas (solo lectura), el identificador no se comparte y el agente se arranca solo para probar.

**Terminada cuando:** las métricas de la fase 1 se ven en el móvil desde datos móviles contra el PC de casa, y la matriz de pruebas está documentada.

**Plan B:** si iroh no funciona, documentar por qué en la memoria, seguir en modo LAN (USB, punto de acceso o misma Wi-Fi) y dejar el acceso remoto como trabajo en curso, con la prueba de concepto como evidencia.

---

### Fase 3 — Seguridad 🔴
**Duración:** ~3 semanas (finales de noviembre – mediados de diciembre)

**Objetivos:**
- **CLI con Typer:**
  - `companion setup`: crear usuario y contraseña con validación de contraseña robusta y Argon2, y generar el certificado TLS autofirmado;
  - `companion show-pairing`: mostrar la dirección, la huella del certificado y el identificador iroh.
- **Base de datos:** primeras tablas (`usuario`, `sesion`, `intento_login`) en `schema.sql`, con sus repositorios.
- **Agente:**
  - HTTPS;
  - login que devuelve un token de sesión aleatorio (guardado con hash);
  - todas las rutas protegidas;
  - límite de intentos con esperas crecientes;
  - `companion logout-all` y `companion passwd`.
- **App:**
  - pantalla de login con validaciones (campos obligatorios, mensajes de error claros);
  - en la primera conexión, mostrar la huella del certificado para compararla con la CLI y guardarla (*certificate pinning*);
  - token en `flutter_secure_storage`.
- Comprobar que todo funciona igual por USB y a través del túnel iroh.

**Terminada cuando:** sin login no se puede hacer nada (tampoco por iroh), un certificado distinto es rechazado y `logout-all` expulsa al móvil.

**Lo que no se recorta:** el login y el TLS.

---

### Fase 4 — Instalación y servicio 🟡
**Duración:** ~1 semana + 1 semana de margen (mediados – finales de diciembre)

**Objetivos:**
- Empaquetar el agente para instalarlo con `pipx install`.
- `companion install-service` / `uninstall-service` / `status`: servicio systemd de usuario (`default.target`, `Restart=on-failure`), con el punto de conexión iroh activo desde el arranque.
- README con:
  - instalación en tres comandos;
  - uso básico;
  - cómo probar por USB y por iroh;
  - **nota sobre reinicio remoto:** `loginctl enable-linger $USER` y sus limitaciones.
- Generar el APK y publicarlo como release `v0.1-beta`.
- Semana de margen: corregir errores, probar la instalación desde cero, repetir la prueba 5 de la matriz de la fase 2 (el identificador iroh sobrevive al reinicio del PC) y hacer capturas para la memoria.

**Terminada cuando:** en un equipo limpio, con tres comandos y el APK, todo funciona, también por iroh, y sobrevive a un reinicio.

---

### ✅ Qué es la beta v0.1 (Navidad)
> Una app Android que se conecta al PC de casa desde cualquier red a través de iroh, con login seguro, y muestra el estado del sistema en vivo con gráficas, más un agente que se instala con un comando y arranca solo.

**Recortes posibles si vas con retraso, en este orden:**
1. Gráficas (dejar solo cifras y completarlas para el hito de febrero).
2. Prueba en red restrictiva (dejarla para enero).

**Nunca se recorta:** login, TLS e instalación del servicio. Si iroh no funciona, se aplica el plan B de la fase 2.

**Requisitos mínimos del proyecto que ya cumple la beta:** interfaz y navegación, login, gestión de errores, BD con tablas relacionadas, Git, capas y manual de instalación.
**Pendientes después de la beta:** lógica de negocio (fases 6 y 7), CRUD de dos entidades y BD de 3–4 tablas con contenido gestionado por el usuario (fase 7).

---

## BLOQUE 2: Núcleo del TFG (enero – mayo)

### Fase 5 — Terminal (v0.2) 🔴
**Duración:** ~5 semanas (enero – principios de febrero)

**Objetivos:**
- **Agente:**
  - WebSocket `/ws/terminal`;
  - PTY con `$SHELL -l` integrado con asyncio;
  - redimensionado con `TIOCSWINSZ`;
  - cierre limpio al desconectar.
- **App:**
  - xterm.dart conectado al WebSocket;
  - barra de teclas especiales (Ctrl, Alt, Tab, Esc, flechas);
  - Nerd Font incluida;
  - redimensionado al girar el móvil.
- Pruebas con Zsh, un prompt tipo Starship y programas a pantalla completa (`htop`, `vim`), por USB y a través de iroh (también por relé, para comprobar que la latencia es usable).

**Terminada cuando:** puedes trabajar con tu shell real desde el móvil, incluidos `htop` y `vim`, desde fuera de casa.

**Nunca se recorta:** es la función estrella del proyecto.

---

### 🎯 Hito de febrero
> La app se conecta al agente Python del PC a través de iroh y ofrece la terminal y las gráficas de rendimiento.

*Pendiente de revisión: fecha exacta de la presentación.* Si alguna parte no está lista, el explorador de archivos (fase 9) puede sustituir a las gráficas; en ese caso, adelantar la parte de archivos de la fase 9.

---

### Fase 6 — Energía y procesos 🟢🟡
**Duración:** ~2 semanas (febrero)

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
**Duración:** ~3 semanas (marzo)

**Por qué es importante:** completa los requisitos mínimos obligatorios (CRUD de dos entidades relacionadas y BD de 3–4 tablas).

**Modelo de datos:**
```
usuario ──1:N── grupo ──1:N── accion_rapida ──1:N── ejecucion
```

**Objetivos:**
- **BD:**
  - tablas `grupo`, `accion_rapida` y `ejecucion` en `schema.sql`, con repositorios;
  - diagrama entidad-relación completo para la memoria.
- **Agente:**
  - CRUD de grupos y acciones;
  - ejecución en segundo plano con timeout (corta con SIGTERM → SIGKILL a todo el grupo de procesos, con `start_new_session=True` y `os.killpg`);
  - una sola ejecución a la vez por acción;
  - salida recortada a un tamaño máximo;
  - historial de ejecuciones con filtros por acción, estado y fechas;
  - estadísticas por acción: número de ejecuciones, tasa de éxito, duración media y última ejecución.
- **Reglas de negocio:**
  - al borrar un grupo con acciones, elegir entre moverlas a "Sin grupo" o borrarlas;
  - nombre único dentro de cada grupo.
- **App:**
  - lista de acciones agrupadas, con buscador y ordenación;
  - formularios de crear y editar grupo y acción, con validaciones (nombre obligatorio y sin duplicados, comando obligatorio, timeout entre 1 y 3600 s, directorio existente validado por el agente);
  - ficha de acción con estadísticas y botón "Ejecutar";
  - historial y detalle de ejecución con la salida del comando.
- Validación doble: en la app (respuesta inmediata) y en el agente (seguridad real).
- Opcional: mostrar la salida de las ejecuciones con xterm.dart (fase 5) para conservar los colores.

**Terminada cuando:** puedes crear el grupo "Proyecto", añadirle la acción "Actualizar repo", ejecutarla desde el móvil, ver su salida, consultar su historial y estadísticas, editarla y borrarla.

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
  - servicio en primer plano que mantiene el túnel iroh y la conexión con `/ws/events` con la app en segundo plano. Hay que declarar su tipo (obligatorio desde Android 14): no `dataSync`, que desde Android 15 se detiene tras 6 h cada 24; candidato `connectedDevice` *(pendiente de revisión, se confirma en esta fase)*, que exige declarar en el manifiesto el permiso `FOREGROUND_SERVICE_CONNECTED_DEVICE` y al menos uno de `CHANGE_NETWORK_STATE`, `CHANGE_WIFI_STATE` o `CHANGE_WIFI_MULTICAST_STATE` (u otra de las alternativas de Bluetooth, UWB o USB);
  - los eventos se muestran con `flutter_local_notifications`. Hay que pedir el permiso `POST_NOTIFICATIONS` en tiempo de ejecución (Android 13+); sin él no se ven los avisos. *Cubre el elemento diferenciador "notificaciones / servicios en segundo plano".*
- Opción "notificar al terminar" en las acciones rápidas de la fase 7.
- Ejemplos documentados:
  - `make && companion notify "Compilación terminada"`;
  - un *hook* de Claude Code.

**Terminada cuando:** con el móvil bloqueado y fuera de casa recibes un aviso al terminar un comando en el PC y cuando salta una regla de alerta.

---

### Fase 9 — Descubrimiento, emparejamiento y archivos 🟢🟡
**Duración:** ~3 semanas (finales de abril – mediados de mayo)

**Objetivos:**
- **mDNS:** el agente se anuncia (zeroconf) y la app lo encuentra sin escribir la dirección (bonsoir). Se prueba con el punto de acceso del móvil.
- **QR:** `companion show-pairing` muestra un QR en la terminal con la dirección, la huella y el identificador iroh; la app lo escanea (`mobile_scanner`) y rellena los datos automáticamente. *Cubre el elemento diferenciador "uso de sensores/cámara".*
- **Registro en la app** *(pendiente de revisión: registro en la app o creación por CLI)*: `companion setup` genera un código de un solo uso y la app muestra un formulario de registro (código, usuario, contraseña con confirmación y validación de robustez).
- **Archivos:**
  - navegar por el sistema de archivos del PC;
  - descargar archivos al móvil;
  - aviso cuando algo requiere root.

**Terminada cuando:** una instalación nueva se empareja escaneando un QR y puedes bajarte un archivo del PC.

---

### Fase 10 — Subida de archivos y pulido 🟢
**Duración:** ~2 semanas (mayo)

**Objetivos:**
- Subir archivos del móvil al PC (por defecto, a la carpeta de descargas del usuario).
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

1. **Subida de archivos** (fase 10): la descarga ya cubre el caso principal.
2. **Reglas de alerta con CRUD** (fase 8): mantener solo `companion notify`.
3. **mDNS** (fase 9): el QR ya evita escribir la dirección.
4. **Hibernar y ordenación de procesos** (fase 6): dejar el listado y el botón de finalizar.

**Nunca se recortan:** conexión por iroh (o el plan B ya documentado), terminal (función estrella), CRUD de acciones rápidas (requisito mínimo) y pulido mínimo de errores.

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
| 1 | Métricas | 🟢 | Oct |
| 2 | Conexión remota con iroh (prueba de concepto, integración y pruebas) | 🔴 | Nov |
| 3 | Seguridad | 🔴 | Nov – Dic |
| 4 | Instalación y servicio | 🟡 | Dic |
| **Beta v0.1** | | | **Navidad** |
| 5 | Terminal (v0.2) | 🔴 | Ene – Feb |
| **Hito** | iroh + terminal + gráficas | | **Febrero** (fecha pendiente de revisión) |
| 6 | Energía y procesos | 🟢🟡 | Feb |
| 7 | CRUD de acciones rápidas | 🟡 | Mar |
| 8 | Notificaciones, reglas de alerta y servicio en primer plano | 🟡🔴 | Abr |
| 9 | mDNS, QR, registro (pendiente) y archivos | 🟢🟡 | Abr – May |
| 10 | Subida y pulido | 🟢 | May |
| Memoria | Redacción final | | May (entrega pendiente de revisión) |
| **Defensa** | | | **Primera semana de junio** |
| Extra | Temas de terminal | 🟢 | Si da tiempo |

## Cobertura de los requisitos mínimos

| Requisito | Dónde se cubre |
|---|---|
| App Android | Todo el proyecto (Flutter, aceptado por el tutor) |
| Capas, Git, manual de instalación | Tareas transversales · Fase 4 |
| Interfaz, navegación, validaciones | Fases 1 y 3 · formularios de las fases 7, 8 y 9 |
| Registro / login | Login: fase 3 · Registro: fase 9 *(pendiente de revisión)* |
| CRUD de 2 entidades relacionadas | **Fase 7** (grupo y acción rápida) · refuerzo en la fase 8 (regla de alerta) |
| Lógica de negocio | Filtros de procesos (fase 6), estadísticas y reglas (fase 7), umbrales (fase 8) |
| Gestión de errores | Todas las fases · revisión en la fase 10 |
| BD de 3–4 tablas con relaciones, `schema.sql`, repositorios | Fases 3 y 7 (6 tablas) · fase 8 (8 tablas) |
| Documentación completa | Material por fase · redacción final |
| Elemento diferenciador | P2P con iroh (fase 2), terminal remota (fase 5), servicios en segundo plano y notificaciones (fase 8), cámara/QR (fase 9) |
