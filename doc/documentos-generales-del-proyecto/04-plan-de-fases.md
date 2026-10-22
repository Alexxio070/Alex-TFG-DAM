# Plan de Desarrollo por Fases: Linux System Companion

## Criterios de planificación

1. **Primero lo más arriesgado.** La conexión entre el móvil y el PC con iroh es la parte más crítica y con más incertidumbre, así que va justo después de la interfaz y las métricas (fase 2). Si da problemas, se descubre en noviembre, con tiempo para aplicar el plan B.
2. **Después, lo obligatorio y lo que más pesa en la nota.** Los requisitos mínimos del proyecto se completan entre la beta y marzo; las funciones de menor impacto, al final.
3. **Fases difíciles intercaladas con fáciles.** Así no se acumula todo lo complejo al final y cada fase difícil va seguida de un respiro.
4. **Cada fase termina con algo que funciona.** Nunca se empieza una fase dejando la anterior a medias.
5. **Dos hitos intermedios:** una beta mínima en Navidad y una versión funcional en febrero (ver sus apartados más abajo).
6. **Se parte de cero en desarrollo móvil.** Las estimaciones incluyen tiempo de aprendizaje y asumen dedicación a tiempo parcial, compaginada con clases.

*Fechas orientativas desde finales de septiembre de 2026; las fases 9–10 coinciden con la redacción de la memoria en mayo y la defensa es la primera semana de junio de 2027. **Pendiente de revisión:** la fecha exacta del hito de febrero y la de entrega de la memoria; ajustar el plan cuando se conozcan, junto con el calendario de exámenes.*

**Leyenda de dificultad:** 🟢 fácil · 🟡 media · 🔴 difícil

---

## Resumen visual

| Fase | Contenido | Dificultad | Fechas orientativas |
|---|---|---|---|
| 0 | Preparación, entorno de pruebas y Flutter | 🟢 | Sep – Oct |
| 1 | Agente y métricas reales (interfaz ya hecha) | 🟢🟡 | Oct – Nov |
| 2 | Conexión remota con iroh (prueba de concepto, integración y pruebas) | 🔴 | Nov – Dic |
| **Beta v0.1** | Interfaz + métricas por iroh, sin login | | **Mediados de diciembre – Navidad** |
| 3 | Seguridad (login, dentro de la TUI ya construida en la fase 1) | 🔴 | Dic – Ene |
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
| Extra | Temas de terminal (`06-ideas-de-futuro.md`) | 🟢 | Si da tiempo |

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

**Estado (20/10/2026): fase cerrada.** Todos los objetivos cumplidos, más el comando `companion` instalable y el aviso «No se puede conectar con el agente» con reintento. Probado por USB con `adb reverse` contra el agente real y con el APK release en el móvil.

**Objetivos:**
- Crear el agente (`agent/`), en capas, con endpoint de métricas (CPU, RAM, discos, temperatura).
- Construir la TUI definitiva de `companion` (banner, cuatro secciones fijas: Emparejamiento, Historial, Base de datos, Notas), vacías o con solo lo que ya existe en la BD.
- App: repositorio real de métricas, pantalla de dirección del agente, gráficas con datos reales cada 1 s.
- Probar por USB con `adb reverse`.

Detalle técnico: `01-memoria-tecnica.md` §3 (Módulo B) y `doc/agente/tui.md`.

**Terminada cuando:** la pantalla de métricas muestra el estado real del portátil en vivo, con gráficas, el resto de pantallas siguen funcionando con datos simulados, y `companion` abre la TUI definitiva con sus cuatro secciones.

**Si vas con retraso:** cifras reales sin gráficas en vivo; las gráficas se completan para el hito de febrero.

---

### Fase 2 — Conexión remota con iroh 🔴
**Duración:** ~6 semanas (principios de noviembre – mediados de diciembre)

**Por qué va aquí:** es la parte más crítica y con más incertidumbre del proyecto. Hacerla pronto deja margen para resolver problemas o aplicar el plan B sin poner en riesgo la beta ni el hito de febrero.

**Objetivos:**
- Prueba de concepto del túnel iroh (primera semana): reenviar el puerto local del agente a través de iroh.
- Integrar iroh en el agente (punto de conexión, identificador estable) y en la app (túnel, selector local/iroh en Ajustes).
- Matriz de pruebas en casa:
  1. Móvil y PC en la misma Wi-Fi: la conexión debe pasar a directa.
  2. Móvil con datos móviles y PC en casa: empieza por el relé y debe intentar pasar a directa.
  3. Bloquear el UDP saliente en el cortafuegos del PC (red restrictiva simulada): todo el tráfico debe ir por el relé.
  4. Cambiar de Wi-Fi a datos móviles en mitad del uso: comprobar la reconexión.
  5. Reiniciar el agente y el PC: el identificador iroh debe ser el mismo.
- Después, repetir la conexión desde una red restrictiva real (centro o Wi-Fi pública).

Detalle técnico: `02-necesidades-tecnologicas.md` §3.3 y §4.2.

**⚠️ Seguridad hasta la fase 3 (incluida la beta):** hasta que exista el login, cualquiera que conozca el identificador iroh puede llegar al agente. Mientras tanto, el agente solo expone las métricas (solo lectura), el identificador no se comparte y el agente se arranca a mano solo para probar.

**Al terminar:** generar el APK y publicarlo como release `v0.1-beta`.

**Terminada cuando:** las métricas de la fase 1 se ven en el móvil desde datos móviles contra el PC de casa, y la matriz de pruebas está documentada.

**Plan B:** si iroh no funciona, documentar por qué en la memoria, seguir en modo LAN (USB, punto de acceso o misma Wi-Fi) y dejar el acceso remoto como trabajo en curso, con la prueba de concepto como evidencia.

---

### ✅ Qué es la beta v0.1 (mediados de diciembre – Navidad)
> Una app Android con la interfaz definitiva (lo que aún no está hecho muestra *placeholders*) que se conecta al PC de casa desde cualquier red a través de iroh y muestra las métricas en vivo con gráficas. Sin login: el agente solo expone métricas de solo lectura y se arranca a mano.


Solo queda pendiente la conexion por iroh

La beta **no** necesita cumplir los requisitos mínimos del proyecto (qué fase cubre cada uno: «Cobertura de los requisitos mínimos», al final).

---

## BLOQUE 2: Núcleo del TFG (mediados de diciembre – mayo)

### Fase 3 — Seguridad 🔴
**Duración:** ~3 semanas (mediados de diciembre – principios de enero, con las vacaciones de Navidad)

**Por qué va aquí:** la terminal (fase 4) da acceso a tu shell, así que no puede exponerse por iroh sin login.

**Objetivos:**
- Activar dentro de «Emparejamiento» (TUI ya construida en la fase 1): configuración inicial (certificado TLS, usuario y contraseña), cambiar contraseña, cerrar todas las sesiones.
- Base de datos: primeras tablas (`usuario`, `sesion`, `intento_login`).
- Agente: HTTPS, login con token de sesión, todas las rutas protegidas, límite de intentos.
- App: pantalla de login (se diseña en esta fase), certificate pinning, token seguro.
- Comprobar que todo funciona igual por USB y por iroh.

Detalle técnico: `01-memoria-tecnica.md` §5 (Seguridad).

**Terminada cuando:** sin login no se puede hacer nada (tampoco por iroh), un certificado distinto es rechazado y «Cerrar todas las sesiones» expulsa al móvil.

**Lo que no se recorta:** el login y el TLS.

---

### Fase 4 — Terminal (v0.2) 🔴
**Duración:** ~5 semanas (enero – mediados de febrero)

**Objetivos:**
- Prototipos previos de los puntos abiertos (ver «Pendientes»).
- Agente: sesiones de terminal sobre tmux (crear, listar, cerrar), WebSocket que engancha la sesión y recupera el historial, ventana en la terminal gráfica del PC.
- App: xterm.dart conectado al WebSocket, reenganche al volver a abrir la app; cada pestaña (maqueta ya hecha en la fase 0) engancha su propia sesión de tmux y su propia ventana en el PC.
- Pruebas con Zsh, un prompt tipo Starship y programas a pantalla completa (`htop`, `vim`), por USB y por iroh (incluido por relé).
- Pruebas de persistencia: dejar un comando largo en marcha, cerrar la app y cortar la red; comprobar que sigue y se recupera al volver.

Detalle técnico: `01-memoria-tecnica.md` §3 (Módulo A) y `doc/agente/terminal-sesiones-tmux.md`.

**Terminada cuando:** puedes trabajar con tu shell real desde el móvil, incluidos `htop` y `vim`, desde fuera de casa, y un comando largo sigue ejecutándose tras cerrar la app y se recupera al volver a abrirla.

**Nunca se recorta:** es la función estrella del proyecto.

---

### 🎯 Hito de febrero
> La app se conecta al agente Python del PC a través de iroh y ofrece la terminal y las gráficas de rendimiento.

Requiere las gráficas (fase 1), el login (fase 3) y la terminal por iroh (fase 4). *Pendiente de revisión: fecha exacta;* si es antes de mediados de febrero, la terminal no llega y hay que ajustar.

---

### Fase 5 — Instalación y servicio 🟡
**Duración:** ~1 semana (finales de febrero)

**Objetivos:**
- Empaquetar el agente para instalarlo con `pipx install`; comprobar las dependencias del sistema (`tmux`, terminal gráfica).
- Activar dentro de «Emparejamiento» los botones «Instalar servicio», «Quitar servicio» y «Estado»: servicio systemd de usuario con el punto de conexión iroh activo desde el arranque.
- README con instalación, uso básico y prueba por USB y por iroh.
- Probar la instalación desde cero, repetir la prueba 5 de la matriz de la fase 2 (el identificador iroh sobrevive al reinicio) y hacer capturas para la memoria.

Detalle técnico: `01-memoria-tecnica.md` §8 (Despliegue) y `02-necesidades-tecnologicas.md` §7.

**Terminada cuando:** en un equipo limpio, con `pipx install`, la TUI y el APK, todo funciona, también por iroh, y sobrevive a un reinicio.

---

### Fase 6 — Energía y procesos 🟢🟡
**Duración:** ~2 semanas (principios – mediados de marzo)

**Objetivos:**
- Agente: apagar, reiniciar, suspender, hibernar y bloquear sesión vía systemd-logind; listado de procesos; finalización con SIGTERM → SIGKILL.
- App: botones de energía con confirmación, lista de procesos con búsqueda y orden, mensajes claros cuando falta permiso.

Detalle técnico: `01-memoria-tecnica.md` §3 (Módulos C y D).

**Terminada cuando:** puedes apagar, reiniciar y bloquear el portátil y finalizar un proceso colgado desde el móvil.

**Nota:** las pruebas de apagado y reinicio se hacen mejor en una máquina virtual o al final de cada sesión de trabajo. Si se apaga el PC a través de iroh, no se puede volver a encender desde el móvil (ver Wake-on-LAN en las ideas de futuro).

---

### Fase 7 — CRUD de acciones rápidas 🟡
**Duración:** ~3 semanas (mediados de marzo – principios de abril)

**Por qué es importante:** completa los requisitos mínimos obligatorios (CRUD de dos entidades relacionadas y BD de 3–4 tablas).

**Objetivos:**
- BD: tablas `grupo`, `accion_rapida` y `ejecucion`, con repositorios.
- Agente: CRUD completo de grupos y acciones, ejecución en segundo plano con timeout e historial.
- App: cuadrícula de inicio conectada al agente (crear, editar, borrar, reordenar), ficha de acción con estadísticas, historial de ejecuciones.
- Exportaciones desde la TUI (datos y estructura de la BD).

Detalle técnico: `01-memoria-tecnica.md` §3 (Módulo E) y §6.3 (exportaciones).

**Terminada cuando:** puedes crear el grupo "Proyecto", añadirle la acción "Actualizar repo", ejecutarla desde el móvil, ver su salida, consultar su historial y estadísticas, editarla y borrarla, y los dos botones de exportación dejan sus archivos en el escritorio.

**Nunca se recorta:** es requisito mínimo.

---

### Fase 8 — Notificaciones, reglas de alerta y servicio en primer plano 🟡🔴
**Duración:** ~3 semanas (abril)

**Objetivos:**
- Agente: WebSocket de eventos, comando `companion notify`, BD de reglas de alerta y notificaciones.
- Reglas de alerta con CRUD completo desde la app; historial de notificaciones con filtros.
- App: servicio en primer plano (mantiene el túnel iroh y la conexión de eventos) y notificaciones locales. *Cubre el elemento diferenciador "notificaciones / servicios en segundo plano".*
- Opción "notificar al terminar" en las acciones rápidas de la fase 7.

Detalle técnico: `01-memoria-tecnica.md` §3 (Módulo G) y `02-necesidades-tecnologicas.md` §4.1 (tipo del servicio en primer plano, *pendiente de revisión, se confirma en esta fase*).

**Terminada cuando:** con el móvil bloqueado y fuera de casa recibes un aviso al terminar un comando en el PC y cuando salta una regla de alerta.

---

### Fase 9 — Descubrimiento, emparejamiento y espacio compartido 🟡
**Duración:** ~3 semanas (finales de abril – mediados de mayo)

**Objetivos:**
- mDNS: el agente se anuncia y la app lo encuentra sin escribir la dirección.
- QR de emparejamiento y registro (sustituye a la creación del usuario desde la TUI de la fase 3): la TUI muestra el QR, la app lo escanea y crea la cuenta. *Cubre el elemento diferenciador "uso de sensores/cámara".*
- Espacio compartido: BD y CRUD de notas, sección «Notas» de la TUI, pantalla de notas en la app (lista, búsqueda, enlaces pulsables).

Detalle técnico: `01-memoria-tecnica.md` §3 (Módulo F) y §5.1 (registro por QR).

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

## Redacción y defensa (mayo – primera semana de junio)

**Memoria final** (*pendiente de revisión: fecha oficial de entrega*): introducción y justificación, planificación, tecnologías, diagrama E/R, diagrama de casos de uso, capturas, pruebas (incluida la matriz de iroh), manual de instalación y uso, estado del arte y decisiones de cada fase.

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

## Pendientes

Huecos de la interfaz o decisiones de plan que quedan abiertas, agrupados por fase:

| Fase | Qué falta |
|---|---|
| Fase 4 (Terminal) | Prototipos previos: cierre al cerrar la ventana del PC, historial sin duplicados, ventana en kitty y Konsole, versión mínima de tmux y supervivencia al reinicio del agente |
| Fase 4 (Terminal) | Decidir límite de sesiones, tamaño del historial y *keepalive*; completar la tabla «emulador → cómo lanzarlo» |
| Fase 4 (Terminal) | Medir la latencia real de crear sesión + ventana del PC + enganche (estimada en 200 ms–1 s LAN, sin verificar); hoy la maqueta simula 600 ms fijos |
| Fase 4 (Terminal, maqueta de UI ya hecha en la fase 0) | Verificar en el emulador que el teclado en pantalla no pierde pulsaciones durante el retraso de creación de la sesión |
| Fase 7 | Definir el acceso a la ficha de acción y a su historial, y los valores por defecto de la creación rápida |
| Agente (general) | Documentar la API, el esquema, la seguridad y la instalación en `doc/agente/` |

---

## Cobertura de los requisitos mínimos

| Requisito | Dónde se cubre |
|---|---|
| App Android | Todo el proyecto (Flutter, aceptado por el tutor) |
| Capas, Git, manual de instalación | Tareas transversales (apéndice) · Fase 5 |
| Interfaz, navegación, validaciones | Interfaz definitiva (ya hecha) · fase 3 (login) · formularios de las fases 7, 8 y 9 |
| Registro / login | Login: fase 3 (usuario creado desde la TUI) · Registro por QR: fase 9 |
| CRUD de 2 entidades relacionadas | **Fase 7** (grupo y acción rápida) · refuerzo en la fase 8 (regla de alerta) y la fase 9 (nota) |
| Lógica de negocio | Filtros de procesos (fase 6), estadísticas y reglas (fase 7), umbrales (fase 8) |
| Gestión de errores | Todas las fases · revisión en la fase 10 |
| BD de 3–4 tablas con relaciones, `schema.sql`, repositorios | Fase 3 (3 tablas) · fase 7 (6 tablas) · fase 8 (8 tablas) · fase 9 (9 tablas) |
| Documentación completa | Material por fase (apéndice) · redacción final |
| Elemento diferenciador | P2P con iroh (fase 2), terminal remota (fase 4), servicios en segundo plano y notificaciones (fase 8), cámara/QR (fase 9) |

---

## Apéndice: referencia transversal

Material que se consulta desde varias fases, no narrativa del plan en sí.

### Decisiones

Decisiones ya resueltas: registro vigente en `07-resumen-decisiones-y-contexto.md` §3.

Abiertas, con fecha límite:

| Decisión | Estado | Cuándo resolverla |
|---|---|---|
| Cómo usar iroh desde Flutter: binding de Kotlin compilado desde el código fuente + *platform channel*, o el plugin `iroh_flutter` de pub.dev | **Pendiente de revisión:** el binding de Kotlin publicado no incluye Android; las dos opciones necesitan Rust y el NDK | Al empezar la fase 2, con la prueba de concepto |
| Imágenes en el espacio compartido | **Aún pensándolo** (fuera del alcance confirmado) | Antes de la fase 9 |
| Tipo del servicio en primer plano de Android | **Pendiente de revisión:** no `dataSync`; candidato `connectedDevice` | En la fase 8 |
| ¿La red del centro deja salir HTTPS con WebSocket hacia los relés de iroh? | **Pendiente de revisión:** preguntar en el centro cómo está montada la red | Antes de la prueba en red restrictiva (fase 2) |
| Fecha exacta del hito de febrero y fecha oficial de entrega de la memoria | **Pendiente de revisión** | Cuando se conozcan |
| Energía sin sesión activa: apagar/reiniciar/suspender/hibernar vía logind puede necesitar una regla de polkit (instalación manual con sudo, el agente no puede escribirla) para funcionar sin una sesión gráfica activa | **Pendiente de investigar:** confirmar si falla de verdad en KDE Plasma 6 y valorar los riesgos de seguridad de esa regla antes de decidir si se añade | Antes de la fase 6 |

### Tareas transversales (en todas las fases)

Se hacen de forma continua, no como una fase aparte. Son requisitos mínimos del proyecto.

- **Git y ramas:** ver `CLAUDE.md`.
- **Arquitectura en capas** (App MVVM, Agente por capas): ver `01-memoria-tecnica.md` §4.2.
- **Base de datos:** `agent/schema.sql`, acceso siempre a través de repositorios (ver `01-memoria-tecnica.md` §6).
- **Pruebas:** pytest en el agente, `flutter_test` en la app (ver `02-necesidades-tecnologicas.md` §8.3), más una tabla de casos de prueba manuales por fase.
- **Material para la memoria:** al cerrar cada fase, capturas de pantalla, casos de prueba realizados y decisiones tomadas.

### Entorno de pruebas

La red del centro puede bloquear la comunicación entre el móvil y el PC, así que el desarrollo diario **no depende de ninguna red externa**:

| Método | Cómo funciona | Cuándo usarlo |
|---|---|---|
| **USB + `adb reverse`** (principal) | `adb reverse tcp:8443 tcp:8443`: la app se conecta a `127.0.0.1:8443` en el móvil y llega al agente del portátil por el cable | Desarrollo diario, en cualquier sitio |
| **Emulador de Android** | Emulador de Android Studio en el mismo portátil; `10.0.2.2` apunta al portátil | Desarrollo sin móvil físico. Requiere virtualización activada. No se usa para iroh: oficialmente solo ARM (aarch64, armv7); x86_64 se puede compilar pero no está soportado, así que iroh se prueba en el móvil físico |
| **Punto de acceso del móvil** | El portátil se conecta al punto de acceso del móvil; ambos quedan en una red privada propia | Probar como LAN real (incluido mDNS). Puede requerir abrir el puerto en el cortafuegos del portátil |
| **Repositorio simulado** | Versión falsa del repositorio de la app que devuelve datos inventados | Trabajar en pantallas sin el agente arrancado |
| **iroh (desde la fase 2)** | Túnel P2P que empieza por un relé y luego intenta pasar a conexión directa (detalle y versiones: `02-necesidades-tecnologicas.md` §3.3) | Acceder al PC desde fuera de casa, siempre con un móvil físico. Primero en casa con la matriz de pruebas de la fase 2 y después en una red restrictiva (centro o Wi-Fi pública). *Pendiente de revisión: confirmar con el centro que deja salir HTTPS con WebSocket y que no hay un proxy que inspeccione el tráfico* |

**Para la defensa:** USB o punto de acceso como opción principal y un vídeo grabado como respaldo. No depender de la red del tribunal.
