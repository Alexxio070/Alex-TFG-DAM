# Plan de Desarrollo por Fases: Sysmote

## Criterios de planificación

1. **Primero lo más arriesgado.** La conexión entre el móvil y el PC con iroh es la parte más crítica y con más incertidumbre, así que va justo después de la interfaz y las métricas (fase 2). Si da problemas, se descubre en noviembre, con tiempo para aplicar el plan B.
2. **Después, lo obligatorio y lo que más pesa en la nota.** Los requisitos mínimos del proyecto se completan en la fase 5 (febrero); las funciones de menor impacto, al final.
3. **Fases difíciles intercaladas con fáciles.** Así no se acumula todo lo complejo al final y cada fase difícil va seguida de un respiro.
4. **Cada fase termina con algo que funciona.** Nunca se empieza una fase dejando la anterior a medias.
5. **Dos hitos intermedios:** una beta mínima en Navidad y una versión funcional en febrero (ver sus apartados más abajo).
6. **Se parte de cero en desarrollo móvil.** Las estimaciones incluyen tiempo de aprendizaje y asumen dedicación a tiempo parcial, compaginada con clases.

*Fechas orientativas desde finales de septiembre de 2026. Calendario académico: primera evaluación, semana del 8 de diciembre; segunda evaluación, segunda semana de marzo. Cierre funcional el 14 de mayo; después, solo corrección de errores, memoria y defensa. La defensa es la primera o la segunda semana de junio de 2027. **Pendiente de revisión:** la fecha exacta del hito de febrero y la de entrega de la memoria (`07-resumen-decisiones-y-contexto.md` §3.8); ajustar el plan cuando se conozcan.*

**Leyenda de dificultad:** 🟢 fácil · 🟡 media · 🔴 difícil

---

## Calendario

Las fases van numeradas en el orden en que se hacen.

| Fase | Contenido | Dificultad | Fechas orientativas |
|---|---|---|---|
| 0 | Preparación, entorno de pruebas y Flutter | 🟢 | Sep – Oct (cerrada) |
| 1 | Agente y métricas reales (interfaz ya hecha) | 🟢🟡 | Oct – Nov (cerrada) |
| 2 | Conexión remota con iroh (prueba de concepto, integración y pruebas) | 🔴 | Nov – Dic (cerrada) |
| **Beta v0.1** | Interfaz + métricas por iroh, sin login | | **Publicada el 16/11/2026** |
| 3 | Seguridad (login, dentro de la TUI ya construida en la fase 1) | 🔴 | Dic – Ene (cerrada el 19/11/2026) |
| 4 | Instalación y servicio | 🟡 | Dic (primera quincena; semana de exámenes el 8) |
| 5 | Terminal y acciones rápidas (v0.2) | 🔴 | Mediados de dic – principios de feb |
| **Hito** | iroh + terminal + gráficas | | **Febrero** |
| 6 | Notificaciones, reglas de alerta y servicio en primer plano | 🟡🔴 | Mediados de feb – principios de mar |
| 7 | Procesos | 🟢 | Mediados – finales de mar (segunda evaluación en la segunda semana) |
| 8 | mDNS, escáner de QR en la app y espacio compartido | 🟡 | Abr – principios de may |
| 9 | Pulido | 🟢 | May (cierre funcional el 14/05) |
| Memoria | Redacción final | | May – jun |
| **Defensa** | | | **Primera o segunda semana de junio** |
| Extra | Temas de terminal (`06-ideas-de-futuro.md`) | 🟢 | Si da tiempo |

---

## Estado actual (27/11/2026)

- **Cerradas:** fases 0 a 3. Beta v0.1 publicada el 16/11/2026; agente publicado en PyPI como `sysmote` 0.1.0 (19/11/2026).
- **Interfaz:** pantalla de bienvenida del primer inicio y avisos de sesión caducada y no válida, implementados (27/11/2026).
- **En curso:** caducidad de la sesión a 7 días y error `sesion_caducada` en el agente (rama `feature/caducidad-sesion`, en revisión).
- **Siguiente:** fase 4, Instalación y servicio.
- **Sin probar de punta a punta:** el aviso de `sesion_caducada` con el agente real; el cliente HTTPS tras dejar la app parada más de 5 s; qué camino usa iroh (directo o relé) y el cambio de Wi-Fi a datos con la app abierta.

---

## BLOQUE 1: Beta v0.1 (objetivo: Navidad)

### Fase 0 — Preparación y aprender Flutter 🟢
**Duración:** ~3 semanas (finales de septiembre – mediados de octubre)

**Estado (12/10/2026): fase cerrada.** Además, la interfaz definitiva de la app quedó hecha con *placeholders* y datos simulados (ver `doc/ui/estructura-app.md`).

**Objetivos:**
- Instalar Flutter y Android Studio.
- Configurar el **entorno de pruebas**: depuración USB en el móvil, `adb reverse` y emulador.
- Crear el repositorio Git con la estructura `App-movil/` + `agent/` y la rama `main`.
- Aprender lo básico de Dart: variables, clases, `async`/`await`, `Future`, `Stream`.
- Hacer el tutorial oficial de Flutter (widgets, estado, navegación entre pantallas).

**Terminada cuando:** la app se ejecuta en tu móvil conectado por USB y el repositorio tiene sus primeros commits.

---

### Fase 1 — Agente y métricas reales 🟢🟡
**Duración:** ~3 semanas (mediados de octubre – principios de noviembre)

**Estado (20/10/2026): fase cerrada.** Todos los objetivos cumplidos, más el comando `sysmote` instalable y el aviso «No se puede conectar con el agente» con reintento. Probado por USB con `adb reverse` contra el agente real y con el APK release en el móvil.

**Objetivos:**
- Crear el agente (`agent/`), en capas, con endpoint de métricas (CPU, RAM, discos, temperatura).
- Construir la TUI definitiva de `sysmote` (banner, cuatro secciones fijas: Emparejamiento, Historial, Base de datos, Notas), vacías o con solo lo que ya existe en la BD.
- App: repositorio real de métricas, pantalla de dirección del agente, gráficas con datos reales cada 1 s.
- Probar por USB con `adb reverse`.

Detalle técnico: `01-memoria-tecnica.md` §3 (Módulo B) y `doc/agente/tui.md`.

**Terminada cuando:** la pantalla de métricas muestra el estado real del portátil en vivo, con gráficas, el resto de pantallas siguen funcionando con datos simulados, y `sysmote` abre la TUI definitiva con sus cuatro secciones.

**Si vas con retraso:** cifras reales sin gráficas en vivo; las gráficas se completan para el hito de febrero.

---

### Fase 2 — Conexión remota con iroh 🔴
**Duración:** ~6 semanas (principios de noviembre – mediados de diciembre)

**Estado (12/11/2026): fase cerrada.** Túnel iroh en el agente, repositorio iroh en la app con el selector local/iroh de Ajustes, matriz de pruebas hecha en casa (los 5 casos) y conexión probada en una red restrictiva real. Detalle y resultados: `doc/iroh/`.

**Por qué va aquí:** es la parte más crítica y con más incertidumbre del proyecto. Hacerla pronto deja margen para resolver problemas o aplicar el plan B sin poner en riesgo la beta ni el hito de febrero.

**Objetivos:**
- Prueba de concepto del túnel iroh (primera semana): reenviar el puerto local del agente a través de iroh.
- Integrar iroh en el agente (punto de conexión, identificador estable) y en la app (el túnel real; el selector local/iroh de Ajustes ya existe).
- Matriz de pruebas en casa:
  1. Móvil y PC en la misma Wi-Fi: la conexión debe pasar a directa.
  2. Móvil con datos móviles y PC en casa: empieza por el relé y debe intentar pasar a directa.
  3. Bloquear el UDP saliente en el cortafuegos del PC (red restrictiva simulada): todo el tráfico debe ir por el relé.
  4. Cambiar de Wi-Fi a datos móviles en mitad del uso: comprobar la reconexión.
  5. Reiniciar el agente y el PC: el identificador iroh debe ser el mismo.
- Después, repetir la conexión desde una red restrictiva real (centro o Wi-Fi pública): probada y funciona (12/11/2026). No era la red del centro, que sigue pendiente (`07` §3.8).

Detalle técnico: `02-necesidades-tecnologicas.md` §3.3 y §4.2.

**⚠️ Seguridad hasta la fase 3 (incluida la beta):** hasta que exista el login, cualquiera que conozca el identificador iroh puede llegar al agente. Mientras tanto, el agente solo expone las métricas (solo lectura), el identificador no se comparte y el agente se arranca a mano solo para probar.

**Al terminar:** generar el APK y publicarlo como release `v0.1-beta`.

**Terminada cuando:** las métricas de la fase 1 se ven en el móvil desde datos móviles contra el PC de casa, y la matriz de pruebas está documentada.

**Plan B:** si iroh no funciona, documentar por qué en la memoria, seguir en modo LAN (USB, punto de acceso o misma Wi-Fi) y dejar el acceso remoto como trabajo en curso, con la prueba de concepto como evidencia.

---

### ✅ Qué es la beta v0.1 (mediados de diciembre – Navidad)
> Una app Android con la interfaz definitiva (lo que aún no está hecho muestra *placeholders*) que se conecta al PC de casa desde cualquier red a través de iroh y muestra las métricas en vivo con gráficas. Sin login: el agente solo expone métricas de solo lectura y se arranca a mano.

La conexión por iroh ya está hecha (fase 2) y la release `v0.1-beta` está publicada desde el 16/11/2026.

La beta **no** necesita cumplir los requisitos mínimos del proyecto (qué fase cubre cada uno: «Cobertura de los requisitos mínimos», al final).

---

## BLOQUE 2: Núcleo del TFG (mediados de diciembre – mayo)

### Fase 3 — Seguridad 🔴
**Duración:** ~3 semanas (mediados de diciembre – principios de enero, con las vacaciones de Navidad)

**Por qué va aquí:** la terminal (fase 5) da acceso a tu shell, así que no puede exponerse por iroh sin login.

**Objetivos:**
- Activar dentro de «Emparejamiento» (TUI ya construida en la fase 1): configuración inicial (certificado TLS y modo registro con el QR y el código de un solo uso; la cuenta la crea la app con `POST /registro`), cambiar contraseña, cerrar todas las sesiones, reiniciar los intentos de login y QR de emparejamiento en «Dispositivo». Hasta que haya escáner (fase 8), la dirección, la huella y el código se escriben a mano en la app.
- Base de datos: primeras tablas (`usuario`, `sesion`, `intento_login`).
- Agente: HTTPS, login con token de sesión, todas las rutas protegidas, límite de intentos.
- App: pantalla de login (se diseña en esta fase), certificate pinning, token seguro y botón «Desemparejar» en Ajustes.
- Comprobar que todo funciona igual por red local y por iroh. (El USB con `adb reverse` ya no se usa como método de prueba: obsoleto desde el 19/11/2026.)

Detalle técnico: `01` §5 (Seguridad).

**Terminada cuando:** sin login no se puede hacer nada (tampoco por iroh), un certificado distinto es rechazado y «Cerrar todas las sesiones» expulsa al móvil.

**Lo que no se recorta:** el login y el TLS.

**Estado (19/11/2026): fase cerrada.** El agente y la app tienen login, registro con código de un solo uso, token en el Keystore, huella del certificado fijada, «Cerrar sesión» y «Desemparejar», y la TUI de emparejamiento con configuración inicial, cambio de contraseña, cierre de todas las sesiones y reinicio de intentos. Probado por el autor en un móvil físico (Xiaomi Redmi 13C, Android 15) por red local y por iroh con datos móviles, con los tres criterios de «Terminada cuando» comprobados: sin login no se puede hacer nada, una huella distinta es rechazada y «Cerrar todas las sesiones» expulsa al móvil. El USB con `adb reverse` queda fuera: ya no se usa como método de prueba. Las limitaciones conocidas del túnel iroh (IPv6, relé caído, fugas de memoria y la falta de un test automático de la conexión real) se dan por cerradas sin probarlas, porque el autor no puede reproducirlas, y quedan documentadas como limitaciones conocidas en `doc/iroh/04-pruebas.md`.

---

### Fase 4 — Instalación y servicio 🟡
**Duración:** ~2 semanas (primera quincena de diciembre; la semana del 8 es de exámenes)

**Por qué va aquí:** es corta y deja el agente instalable con `pipx` y activo desde el arranque, sin tener la TUI abierta, que es lo que necesita la terminal para usarse desde fuera de casa.

**Objetivos:**
- Empaquetar el agente para instalarlo con `pipx install` (el agente está publicado en PyPI como `sysmote` desde el 19/11/2026, con publicación automática desde GitHub Actions); comprobar las dependencias del sistema (`tmux`, terminal gráfica).
- Activar dentro de «Emparejamiento» los botones «Instalar servicio», «Quitar servicio» y «Estado»: servicio systemd de usuario con el punto de conexión iroh activo desde el arranque. «Quitar servicio» avisa a la app si está conectada, para que olvide el equipo.
- Completar el README (ya tiene una guía de instalación manual) con la instalación por `pipx`, el uso básico y la prueba por red local y por iroh.
- Probar la instalación desde cero, repetir la prueba 5 de la matriz de la fase 2 (el identificador iroh sobrevive al reinicio) y hacer capturas para la memoria.

Detalle técnico: `01` §8 (Despliegue) y `02` §7.

**Terminada cuando:** en un equipo limpio, con `pipx install`, la TUI y el APK, todo funciona, también por iroh, y sobrevive a un reinicio.

---

### Fase 5 — Terminal y acciones rápidas (v0.2) 🔴
**Duración:** ~8 semanas (mediados de diciembre – principios de febrero, con las vacaciones de Navidad)

**Por qué van juntas:** una acción rápida es un comando que se ejecuta en una sesión de terminal. Ejecutarla es abrir esa sesión con su comando, así que no hace falta un motor de ejecución aparte y las dos piezas comparten agente, WebSocket y pantalla de la app.

**Objetivos, terminal:**
- Prototipos previos de los puntos abiertos (ver «Pendientes de cada fase»).
- Agente: sesiones de terminal sobre tmux (crear, listar, cerrar), WebSocket que engancha la sesión y recupera el historial. La ventana en la terminal gráfica del PC es opcional: una casilla en la sección Terminal de la app la abre o no (decisión del 27/11/2026; valor por defecto por confirmar).
- App: xterm.dart conectado al WebSocket, reenganche al volver a abrir la app; cada pestaña (la maqueta ya está hecha) engancha su propia sesión de tmux.
- Pruebas con Zsh, un prompt tipo Starship y programas a pantalla completa (`htop`, `vim`), por red local y por iroh (incluido por relé).
- Pruebas de persistencia: dejar un comando largo en marcha, cerrar la app y cortar la red; comprobar que sigue y se recupera al volver.

**Objetivos, acciones rápidas:**
- BD: tablas `grupo`, `accion_rapida` y `ejecucion`, con repositorios. El historial recoge solo el comando ejecutado, la fecha y hora y, si es posible, un pequeño resumen de la salida.
- Agente: CRUD completo de grupos y acciones. Ejecutar una acción es crear una sesión de terminal con su comando; cuando el comando termina, la pestaña se cierra sola.
- App: cuadrícula de inicio conectada al agente (crear, editar, borrar, reordenar), ficha de acción e historial. Al pulsar una acción (y confirmar, si lo pide), la app abre la pantalla de Terminal con una pestaña nueva con el trabajo de la macro, para ver su salida en directo.
- Aviso al crear o ejecutar una acción que apague o reinicie el PC: no se podrá volver a encender desde el móvil.
- Ajustes: la opción «Enviar notificación cuando un comando termine» se guarda aquí; empieza a funcionar en la fase 6.
- Exportaciones desde la TUI (datos y estructura de la BD).

Detalle técnico: `01` §3 (Módulos A y E, el E pendiente de actualizar al nuevo diseño) y §6.3 (exportaciones), `doc/agente/terminal-sesiones-tmux.md` y `07` §3.10.

**Terminada cuando:** puedes trabajar con tu shell real desde el móvil, incluidos `htop` y `vim`, desde fuera de casa, y un comando largo sigue ejecutándose tras cerrar la app y se recupera al volver a abrirla; y puedes crear el grupo "Proyecto", añadirle la acción "Actualizar repo", pulsarla y ver su salida en directo en una pestaña de la terminal que se cierra sola al terminar, consultar el historial, editarla y borrarla, y los dos botones de exportación dejan sus archivos en el escritorio.

**Nunca se recorta:** la terminal (función estrella del proyecto) ni el CRUD de acciones rápidas (requisito mínimo).

---

### 🎯 Hito de febrero
> La app se conecta al agente Python del PC a través de iroh y ofrece la terminal y las gráficas de rendimiento.

Requiere las gráficas (fase 1), el login (fase 3) y la terminal por iroh (fase 5). Si la fecha es antes de mediados de febrero, la terminal no llega y hay que ajustar.

---

### Fase 6 — Notificaciones, reglas de alerta y servicio en primer plano 🟡🔴
**Duración:** ~3 semanas (mediados de febrero – principios de marzo; la segunda evaluación es la segunda semana de marzo)

**Objetivos:**
- Agente: WebSocket de eventos, comando `sysmote notify`, BD de reglas de alerta y notificaciones.
- Reglas de alerta con CRUD completo desde la app; historial de notificaciones con filtros.
- App: servicio en primer plano (mantiene el túnel iroh y la conexión de eventos) y notificaciones locales. *Cubre el elemento diferenciador "notificaciones / servicios en segundo plano".*
- Activar la opción de Ajustes «Enviar notificación cuando un comando termine» (se guarda desde la fase 5), que avisa al terminar una acción rápida.

Detalle técnico: `01` §3 (Módulo G) y `02` §4.1 (tipo del servicio en primer plano, decisión abierta en `07` §3.8).

**Terminada cuando:** con el móvil bloqueado y fuera de casa recibes un aviso al terminar un comando en el PC y cuando salta una regla de alerta.

---

### Fase 7 — Procesos 🟢
**Duración:** ~2 semanas (mediados – finales de marzo; fase ligera, coincide con la segunda evaluación)

**Objetivos:**
- Agente: lista de procesos con consumo (CPU y memoria), búsqueda por nombre o PID, finalizar (SIGTERM → SIGKILL) y congelar.
- App: sección «Procesos» en el menú lateral, con confirmación al finalizar o congelar.

Detalle técnico: `01` §3 (Módulo D). El control de energía (apagar, reiniciar, suspender, hibernar, bloquear) queda fuera del proyecto (`07` §3.2 y §3.10); solo se avisa al crear acciones rápidas que apaguen o reinicien el PC.

**Terminada cuando:** puedes ver qué procesos consumen más, buscar uno, congelarlo y finalizarlo desde el móvil.

---

### Fase 8 — Descubrimiento, emparejamiento y espacio compartido 🟡
**Duración:** ~3 semanas (abril – principios de mayo)

**Objetivos:**
- mDNS: el agente se anuncia y la app lo encuentra sin escribir la dirección.
- Escáner de QR en la app (la TUI ya muestra el QR desde la fase 3): la app lo escanea, guarda la huella y crea la cuenta sin escribir a mano la dirección, la huella ni el código. *Cubre el elemento diferenciador "uso de sensores/cámara".*
- Espacio compartido: BD y CRUD de notas, sección «Notas» de la TUI y pantalla de notas de la app conectada al agente (la interfaz ya existe con datos simulados).

Detalle técnico: `01` §3 (Módulo F) y §5.1 (registro por QR). Decisión abierta sobre imágenes en el espacio compartido: `07` §3.8.

**Terminada cuando:** una instalación nueva se empareja y crea la cuenta escaneando un QR, y una nota guardada desde el móvil aparece en el PC al consultarla (y al revés).

---

### Fase 9 — Pulido 🟢
**Duración:** ~2 semanas (mayo, hasta el cierre funcional del 14/05)

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

1. **Reglas de alerta con CRUD** (fase 6): mantener solo `sysmote notify`.
2. **Resumen de la salida en el historial** (fase 5): dejar solo el comando y la fecha.
3. **mDNS** (fase 8): el QR ya evita escribir la dirección.
4. **Escáner de QR** (fase 8): mantener la introducción a mano de la dirección, la huella y el código.

**Nunca se recortan:** conexión por iroh (o su plan B documentado), terminal (función estrella), CRUD de acciones rápidas (requisito mínimo), login y TLS, y pulido mínimo de errores.

---

## Sueltas y cierres

Lo que no entra estrictamente en ninguna fase (pulidos, auditorías, pruebas pendientes, limpieza) se hace al cerrar cada fase o en una de las tres rondas fijas.

### Al cerrar cada fase

- Pruebas automáticas pasando (`pytest` y `ruff` en el agente; `flutter test` y `dart format` en la app).
- Documentación al día: estructura del agente y de la app, pruebas, decisiones (`07`) y una entrada en `08` si algo cambió.
- Capturas y casos de prueba para la memoria.
- Probado en el móvil físico, por red local y por iroh.
- Ramas fusionadas, ramas parciales sincronizadas y ramas y carpetas temporales borradas.

### Tres rondas fijas

| Ronda | Cuándo | Qué se revisa |
|---|---|---|
| 1 | Hito de febrero (al cerrar la fase 5) | Seguridad y código de lo hecho; coherencia de la documentación; prueba completa por iroh fuera de casa; versión 0.2 del agente en PyPI y release del APK |
| 2 | Antes del cierre funcional (14/05) | Auditoría completa (seguridad, código, interfaz); instalación desde cero; documentación entera |
| 3 | Final, antes de entregar la memoria | README, licencias e historial de git; APK firmado y versión final del agente; copia de seguridad de los informes de auditoría |

### Cajón de sueltas

| Suelta | Se hace con |
|---|---|
| Indicador de conexión real del menú lateral («Conectado» / «Desconectado»; hoy no es funcional) | Fase 6, cuando el servicio en primer plano mantiene la conexión |
| Probar de punta a punta `sesion_caducada` con el agente real | Al fusionar la rama de la caducidad a 7 días |
| Probar el cliente HTTPS tras dejar la app parada más de 5 s | Fase 4 |
| Comprobar qué camino usa iroh (directo o relé) y el cambio de Wi-Fi a datos con la app abierta | Fase 4 (con el servicio instalado) |
| Barrido de menciones al USB con `adb reverse`, obsoleto desde el 19/11/2026 | Ronda 1 |
| Comprobación legal del nombre «Sysmote» (`07` §3.8) | Antes de publicar la primera versión |
| Limpieza del historial de git (autores, etiqueta `v0.1-beta`) | Ronda 3 |
| Firma y versionado del APK | Ronda 3 |

### Pendientes de cada fase

| Fase | Qué falta |
|---|---|
| Fase 5 (Terminal) | Prototipos previos: cierre al cerrar la ventana del PC, historial sin duplicados, ventana en kitty y Konsole, versión mínima de tmux y supervivencia al reinicio del agente |
| Fase 5 (Terminal) | Decidir límite de sesiones, tamaño del historial y *keepalive*; completar la tabla «emulador → cómo lanzarlo» |
| Fase 5 (Terminal) | Medir la latencia real de crear sesión + enganche (estimada en 200 ms–1 s en LAN, sin verificar); hoy la maqueta simula 600 ms fijos |
| Fase 5 (Terminal, maqueta de UI ya hecha) | Verificar en el emulador que el teclado en pantalla no pierde pulsaciones durante el retraso de creación de la sesión |
| Fase 5 (Acciones rápidas) | Cómo saber cuándo termina el comando de una acción, cerrar su pestaña y guardar el resumen de la salida (prototipo); alcance de «Enviar notificación cuando un comando termine» (solo acciones rápidas o también la terminal); acceso a la ficha y al historial; valores por defecto de la creación rápida |
| Agente (general) | Documentar la API, el esquema, la seguridad y la instalación en `doc/agente/` |

---

## Redacción y defensa (mayo – primera o segunda semana de junio)

**Memoria final:** introducción y justificación, planificación, tecnologías, diagrama E/R, diagrama de casos de uso, capturas, pruebas (incluida la matriz de iroh), manual de instalación y uso, estado del arte y decisiones de cada fase.

**Demo recomendada:**
1. Instalar el agente.
2. Emparejar por QR.
3. Mostrar las métricas.
4. Usar la terminal.
5. Ejecutar una acción rápida y ver su salida en directo y su historial.
6. Buscar y finalizar un proceso.
7. Recibir una notificación al terminar un comando.

Si la red lo permite, hacerlo todo desde datos móviles contra el PC de casa a través de iroh.

**Respaldo:** conexión por punto de acceso del móvil y vídeo grabado de la demo. El entorno de pruebas está en `07` §6.

---

## Cobertura de los requisitos mínimos

| Requisito | Dónde se cubre |
|---|---|
| App Android | Todo el proyecto (Flutter, aceptado por el tutor) |
| Capas, Git, manual de instalación | Tareas transversales (abajo) · Fase 4 |
| Interfaz, navegación, validaciones | Interfaz definitiva (ya hecha) · fase 3 (login) · formularios de las fases 5, 6 y 8 |
| Registro / login | Registro con código y login: fase 3 (el QR lo muestra la TUI) · Escáner de QR en la app: fase 8 |
| CRUD de 2 entidades relacionadas | **Fase 5** (grupo y acción rápida) · refuerzo en la fase 6 (regla de alerta) y la fase 8 (nota) |
| Lógica de negocio | Búsqueda de procesos (fase 7), historial de acciones (fase 5), umbrales (fase 6) |
| Gestión de errores | Todas las fases · revisión en la fase 9 |
| BD de 3–4 tablas con relaciones, `schema.sql`, repositorios | Fase 3 (5 tablas) · fase 5 (8 tablas) · fase 6 (10 tablas) · fase 8 (11 tablas) |
| Documentación completa | Material por fase · redacción final |
| Elemento diferenciador | P2P con iroh (fase 2), terminal remota (fase 5), servicios en segundo plano y notificaciones (fase 6), cámara/QR (fase 8) |

---

## Tareas transversales (en todas las fases)

Se hacen de forma continua, no como una fase aparte. Son requisitos mínimos del proyecto.

- **Git y ramas:** ver `CLAUDE.md`.
- **Arquitectura en capas** (App MVVM, Agente por capas): ver `01` §4.2.
- **Base de datos:** `agent/sysmote/schema.sql`, acceso siempre a través de repositorios (ver `01` §6).
- **Pruebas:** pytest en el agente, `flutter_test` en la app (ver `02` §8.3), más una tabla de casos de prueba manuales por fase.
- **Material para la memoria:** al cerrar cada fase, capturas de pantalla, casos de prueba realizados y decisiones tomadas.

El entorno de pruebas (métodos, matriz de iroh y cuenta de pruebas) está en `07-resumen-decisiones-y-contexto.md` §6.
