# Plan de Desarrollo por Fases: Linux System Companion

## Criterios de planificación

1. **Primero lo obligatorio y lo que más pesa en la nota.** Los requisitos mínimos del proyecto van justo después de la beta; las funciones de menor impacto, al final.
2. **Fases difíciles intercaladas con fáciles.** Así no se acumula todo lo complejo al final y cada fase difícil va seguida de un respiro.
3. **Cada fase termina con algo que funciona.** Nunca se empieza una fase dejando la anterior a medias.
4. **Una beta funcional en diciembre.** Pocas funciones, pero completas y sólidas. La beta **no** necesita cumplir todos los requisitos mínimos; eso se completa en enero.
5. **Se parte de cero en desarrollo móvil.** Las estimaciones incluyen tiempo de aprendizaje y asumen dedicación a tiempo parcial, compaginada con clases.

*Fechas orientativas desde finales de septiembre de 2026. **Ajustar a la fecha real de entrega** y al calendario de exámenes.*

**Leyenda de dificultad:** 🟢 fácil · 🟡 media · 🔴 difícil

---

## Decisiones pendientes

| Decisión | Estado | Cuándo resolverla |
|---|---|---|
| ¿El centro acepta Flutter? (la normativa cita "Android Studio, Kotlin, Java") | **Preguntar al tutor por escrito** | Antes de empezar la fase 0. Si no se acepta, plan B: Kotlin + Jetpack Compose |
| ¿El agente en Python cuenta como parte del proyecto? | Preguntar al tutor | Junto a la anterior |
| Registro de usuario en la app (código de un solo uso + formulario) frente a creación por CLI | **Pendiente de revisión** | Antes de la fase 7 |

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

La red del centro puede bloquear la comunicación entre el móvil y el PC, así que las pruebas **no dependen de ninguna red externa**:

| Método | Cómo funciona | Cuándo usarlo |
|---|---|---|
| **USB + `adb reverse`** (principal) | `adb reverse tcp:8443 tcp:8443`: la app se conecta a `127.0.0.1:8443` en el móvil y llega al agente del portátil por el cable | Desarrollo diario, en cualquier sitio |
| **Emulador de Android** | Emulador de Android Studio en el mismo portátil; `10.0.2.2` apunta al portátil | Desarrollo sin móvil físico. Requiere virtualización activada |
| **Punto de acceso del móvil** | El portátil se conecta al punto de acceso del móvil; ambos quedan en una red privada propia | Probar como LAN real (incluido mDNS). Puede requerir abrir el puerto en el cortafuegos del portátil |
| **Repositorio simulado** | Versión falsa del repositorio de la app que devuelve datos inventados | Trabajar en pantallas sin el agente arrancado |
| **iroh (desde la fase 8)** | Túnel P2P a través de relés que se parecen a tráfico web normal | Comprobar si se puede acceder al PC de casa desde la red del centro |

**Para la defensa:** USB o punto de acceso como opción principal y un vídeo grabado como respaldo. No depender de la red del tribunal.

---

## BLOQUE 1: Beta v0.1 (objetivo: mediados de diciembre)

### Fase 0 — Preparación y aprender Flutter 🟢
**Duración:** ~3 semanas (finales de septiembre – mediados de octubre)

**Objetivos:**
- **Consultar al tutor** las decisiones pendientes (Flutter y agente Python).
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

**Si vas con retraso:** muestra cifras sin gráficas y añádelas más adelante.

---

### Fase 2 — Seguridad 🔴
**Duración:** ~3 semanas (noviembre)

**Objetivos:**
- **CLI con Typer:**
  - `companion setup`: crear usuario y contraseña con validación de contraseña robusta y Argon2, y generar el certificado TLS autofirmado;
  - `companion show-pairing`: mostrar la dirección y la huella del certificado.
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

**Terminada cuando:** sin login no se puede hacer nada, un certificado distinto es rechazado y `logout-all` expulsa al móvil.

**Lo que no se recorta:** el login y el TLS.

---

### Fase 3 — Energía y procesos 🟢🟡
**Duración:** ~2 semanas (finales de noviembre – principios de diciembre)

**Objetivos:**
- **Agente:**
  - apagar, reiniciar, suspender, hibernar (solo si está disponible) y bloquear sesión vía systemd-logind (dbus-fast);
  - listado de procesos;
  - finalización con SIGTERM y, si sigue vivo, opción de SIGKILL.
- **App:**
  - botones de energía con confirmación;
  - lista de procesos con búsqueda y orden por CPU y RAM;
  - mensajes claros cuando no se puede finalizar un proceso de otro usuario o polkit deniega una acción.

**Terminada cuando:** puedes apagar, reiniciar y bloquear el portátil y finalizar un proceso colgado desde el móvil.

**Nota:** las pruebas de apagado y reinicio se hacen mejor en una máquina virtual o al final de cada sesión de trabajo.

---

### Fase 4 — Instalación y servicio 🟡
**Duración:** ~1 semana + 1 semana de margen (mediados de diciembre)

**Objetivos:**
- Empaquetar el agente para instalarlo con `pipx install`.
- `companion install-service` / `uninstall-service` / `status`: servicio systemd de usuario (`default.target`, `Restart=on-failure`).
- README con:
  - instalación en tres comandos;
  - uso básico;
  - cómo probar por USB;
  - **nota sobre reinicio remoto:** `loginctl enable-linger $USER` y sus limitaciones.
- Generar el APK y publicarlo como release `v0.1-beta`.
- Semana de margen: corregir errores, probar la instalación desde cero y hacer capturas para la memoria.

**Terminada cuando:** en un equipo limpio, con tres comandos y el APK, todo funciona y sobrevive a un reinicio del agente.

---

### ✅ Qué es la beta v0.1
> Una app Android que se conecta al PC con login seguro, muestra el estado del sistema en vivo, gestiona procesos y controla el encendido y el bloqueo del equipo, más un agente que se instala con un comando y arranca solo.

**Recortes posibles si vas con retraso, en este orden:**
1. Gráficas (dejar solo cifras).
2. Hibernar.
3. Ordenación y búsqueda de procesos (dejar solo el listado y el botón de finalizar).

**Nunca se recorta:** login, TLS e instalación del servicio.

**Requisitos mínimos del proyecto que ya cumple la beta:** interfaz y navegación, login, lógica de negocio (búsqueda y filtrado de procesos), gestión de errores, BD con tablas relacionadas, Git, capas y manual de instalación.
**Pendientes para enero:** CRUD de dos entidades y BD de 3–4 tablas con contenido gestionado por el usuario.

---

## BLOQUE 2: Núcleo del TFG (enero – mayo)

### Prueba de concepto de iroh 🔴 (pequeña)
**Duración:** 2–3 días (primera semana de enero)

**Objetivos:**
- En el PC, un script Python mínimo que reenvía un puerto local a través de iroh (se puede empezar probando con el binario `dumbpipe`).
- Una app Flutter de prueba, separada del proyecto, con el módulo Kotlin que abre el túnel mediante un *platform channel*.
- Hacer una petición al agente **desde 4G** y **desde la red del centro**.

**Por qué ahora:** si iroh da problemas, se descubre en enero y no en abril, con tiempo para decidir el plan B (solo LAN).

**Terminada cuando:** una petición llega del móvil al agente por datos móviles, o se documenta por qué no, y se decide el plan.

---

### Fase 5 — CRUD de acciones rápidas 🟡
**Duración:** ~3 semanas (enero)

**Por qué va primero:** completa los requisitos mínimos obligatorios (CRUD de dos entidades relacionadas y BD de 3–4 tablas).

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
  - ejecución en segundo plano con timeout (corta con SIGTERM → SIGKILL);
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

**Terminada cuando:** puedes crear el grupo "Proyecto", añadirle la acción "Actualizar repo", ejecutarla desde el móvil, ver su salida, consultar su historial y estadísticas, editarla y borrarla.

**Nunca se recorta:** es requisito mínimo.

---

### Fase 6 — Terminal (v0.2) 🔴
**Duración:** ~4 semanas (febrero)

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
- Pruebas con Zsh, un prompt tipo Starship y programas a pantalla completa (`htop`, `vim`).
- Opcional: mostrar la salida de las ejecuciones de la fase 5 con xterm.dart para conservar los colores.

**Terminada cuando:** puedes trabajar con tu shell real desde el móvil, incluidos `htop` y `vim`.

**Nunca se recorta:** es la función estrella del proyecto.

---

### Fase 7 — Descubrimiento, emparejamiento y archivos 🟢🟡
**Duración:** ~3 semanas (marzo)

**Objetivos:**
- **mDNS:** el agente se anuncia (zeroconf) y la app lo encuentra sin escribir la dirección (bonsoir). Se prueba con el punto de acceso del móvil.
- **QR:** `companion show-pairing` muestra un QR en la terminal; la app lo escanea (`mobile_scanner`) y rellena dirección y huella automáticamente. *Cubre el elemento diferenciador "uso de sensores/cámara".*
- **Registro en la app** *(pendiente de revisión)*: `companion setup` genera un código de un solo uso y la app muestra un formulario de registro (código, usuario, contraseña con confirmación y validación de robustez).
- **Archivos:**
  - navegar por el sistema de archivos del PC;
  - descargar archivos al móvil;
  - aviso cuando algo requiere root.

**Terminada cuando:** una instalación nueva se empareja escaneando un QR y puedes bajarte un archivo del PC.

---

### Fase 8 — Acceso remoto con iroh 🔴
**Duración:** ~4 semanas (finales de marzo – abril)

**Objetivos:**
- **Agente:**
  - punto de conexión iroh que reenvía al servidor local;
  - identificador iroh estable, incluido en `show-pairing` y en el QR.
- **App:**
  - módulo Kotlin del túnel (partiendo de la prueba de enero);
  - *platform channel* `openTunnel` / `closeTunnel`;
  - servicio en primer plano para mantener la conexión en segundo plano.
- Cambio automático entre LAN y túnel.
- Pruebas desde 4G, otra Wi-Fi y la red del centro.

**Terminada cuando:** todas las funciones anteriores funcionan igual desde fuera de casa.

**Plan B:** si no se completa, el TFG se entrega en modo LAN y el acceso remoto se documenta como trabajo en curso, con la prueba de concepto como evidencia.

---

### Fase 9 — Notificaciones y reglas de alerta 🟡
**Duración:** ~2 semanas (finales de abril – principios de mayo)

**Objetivos:**
- **Agente:**
  - WebSocket `/ws/events`;
  - socket Unix `$XDG_RUNTIME_DIR/companion.sock` (permisos `0600`);
  - comando `companion notify "mensaje"`.
- **BD:** tablas `regla_alerta` y `notificacion` (relación regla 1:N notificaciones).
- **Reglas de alerta con CRUD completo desde la app:** métrica, operador, umbral, duración sostenida, tiempo mínimo entre avisos y activa/inactiva.
- **Historial de notificaciones** con búsqueda, filtros, marcar como leída y borrar.
- **App:** el servicio en primer plano escucha los eventos y los muestra con `flutter_local_notifications`. *Cubre el elemento diferenciador "notificaciones / servicios en segundo plano".*
- Opción "notificar al terminar" en las acciones rápidas de la fase 5.
- Ejemplos documentados:
  - `make && companion notify "Compilación terminada"`;
  - un *hook* de Claude Code.

**Terminada cuando:** con el móvil bloqueado recibes un aviso al terminar un comando en el PC y cuando salta una regla de alerta.

**Nota:** no depende de iroh; funciona en LAN y por USB.

---

### Fase 10 — Subida de archivos y pulido 🟢
**Duración:** ~2 semanas (mayo)

**Objetivos:**
- Subir archivos del móvil al PC (por defecto, a la carpeta de descargas del usuario).
- Revisión general:
  - mensajes de error comprensibles;
  - estados de carga;
  - reconexión automática;
  - pruebas de instalación desde cero.
- Completar las pruebas automáticas y la tabla de casos de prueba.
- Manual de usuario (uso de cada pantalla, con capturas).

**Terminada cuando:** la app se siente como un producto terminado, no como un prototipo.

---

## Si vas con retraso después de la beta

Recortar en este orden (lo primero es lo que menos se pierde):

1. **Subida de archivos** (fase 10): la descarga ya cubre el caso principal.
2. **Reglas de alerta con CRUD** (fase 9): mantener solo `companion notify`.
3. **mDNS** (fase 7): el QR ya evita escribir la dirección.
4. **Acceso remoto con iroh** (fase 8): aplicar el plan B y documentarlo como trabajo en curso.

**Nunca se recortan:** CRUD de acciones rápidas (requisito mínimo), terminal (función estrella) y pulido mínimo de errores.

---

## BLOQUE 3: Si da tiempo

### Temas de la terminal 🟢
- Paleta de colores configurable en la app.
- Opcional: importar los colores del esquema del PC.

---

## Redacción y defensa (mayo – entrega)

**Memoria final:**
- introducción y justificación;
- planificación;
- tecnologías;
- diseño de la BD (diagrama entidad-relación);
- diagrama de casos de uso;
- capturas;
- pruebas;
- manual de instalación y de uso;
- estado del arte actualizado;
- decisiones tomadas en cada fase.

**Demo recomendada:**
1. Instalar el agente.
2. Emparejar por QR.
3. Mostrar las métricas.
4. Ejecutar una acción rápida y ver su historial.
5. Usar la terminal.
6. Finalizar un proceso.
7. Recibir una notificación al terminar un comando.
8. Apagar el PC.

Si iroh funciona, hacerlo todo desde datos móviles contra el PC de casa.

**Respaldo:** conexión por USB o punto de acceso y vídeo grabado de la demo.

---

## Resumen visual

| Fase | Contenido | Dificultad | Fechas orientativas |
|---|---|---|---|
| 0 | Preparación, entorno de pruebas y Flutter | 🟢 | Sep – Oct |
| 1 | Métricas | 🟢 | Oct |
| 2 | Seguridad | 🔴 | Nov |
| 3 | Energía y procesos | 🟢🟡 | Nov – Dic |
| 4 | Instalación y servicio | 🟡 | Dic |
| **Beta v0.1** | | | **Mediados de diciembre** |
| PoC | Prueba de iroh | 🔴 | Ene (2–3 días) |
| 5 | CRUD de acciones rápidas | 🟡 | Ene |
| 6 | Terminal (v0.2) | 🔴 | Feb |
| 7 | mDNS, QR, registro (pendiente) y archivos | 🟢🟡 | Mar |
| 8 | Acceso remoto iroh | 🔴 | Mar – Abr |
| 9 | Notificaciones y reglas de alerta | 🟡 | Abr – May |
| 10 | Subida y pulido | 🟢 | May |
| Extra | Temas de terminal | 🟢 | Si da tiempo |

## Cobertura de los requisitos mínimos

| Requisito | Dónde se cubre |
|---|---|
| App Android | Todo el proyecto *(Flutter pendiente de confirmar con el tutor)* |
| Capas, Git, manual de instalación | Tareas transversales · Fase 4 |
| Interfaz, navegación, validaciones | Fases 1–3 · formularios de las fases 5, 7 y 9 |
| Registro / login | Login: fase 2 · Registro: fase 7 *(pendiente de revisión)* |
| CRUD de 2 entidades relacionadas | **Fase 5** (grupo y acción rápida) · refuerzo en la fase 9 (regla de alerta) |
| Lógica de negocio | Filtros de procesos (fase 3), estadísticas y reglas (fase 5), umbrales (fase 9) |
| Gestión de errores | Todas las fases · revisión en la fase 10 |
| BD de 3–4 tablas con relaciones, `schema.sql`, repositorios | Fases 2 y 5 (6 tablas) · fase 9 (8 tablas) |
| Documentación completa | Material por fase · redacción final |
| Elemento diferenciador | Cámara/QR (fase 7), servicios en segundo plano y notificaciones (fases 8 y 9), P2P con iroh, terminal remota |
