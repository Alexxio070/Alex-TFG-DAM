# Linux System Companion (TFG)

TFG de DAM (Desarrollo de Aplicaciones Multiplataforma) de alex. Es una app Android + un agente Python en el PC Linux del usuario para administrar ese PC en remoto desde el móvil (LAN o WAN), sin configurar router ni VPN.

**Alcance de este repo:** aquí vive únicamente el trabajo del PROYECTO (el entregable que se presenta al tribunal). El aprendizaje personal de las tecnologías (hilos "APRENDIZAJE:") se lleva en el chat del proyecto de claude.ai, no en este repositorio — no aplican aquí las instrucciones de estilo docente de esos hilos.

## Regla de confirmación previa (sin automatismos)

Regla fundamental de alex, aplica a cualquier sesión de Claude/Claude Code que trabaje en este repo:

1. **Antes de generar o crear nada**, explicar primero cómo se ha entendido la petición del usuario.
2. Después, explicar el **plan de acción**: qué se va a hacer, cómo se va a estructurar, qué se va a usar y **por qué esa opción y no otra**.
3. **Esperar confirmación explícita del usuario antes de ejecutar ninguna acción.** Ninguna decisión es automática.
4. **No crear/generar nada** que el usuario no haya pedido explícitamente — ceñirse literalmente a lo pedido, ni más ni menos.
5. **No tocar el repositorio salvo que el usuario lo especifique.**
6. Si se crea algo sin que el usuario lo pidiera explícitamente, borrarlo en cuanto se detecte.

## Módulos previstos
- Terminal remota (PTY)
- Monitorización de sistema en vivo (psutil)
- Control de energía/sesión (dbus-fast + systemd-logind)
- Gestión de procesos
- "Acciones rápidas": comandos guardados con CRUD completo (grupo → acción_rápida → ejecución — este es el requisito obligatorio de CRUD de 2 entidades relacionadas)
- Exploración y transferencia de archivos
- Notificaciones y reglas de alerta (socket/websocket propio, sin Firebase)

## Stack

**Cliente (Android) — confirmado:**
- Flutter/Dart, arquitectura MVVM + provider
- xterm.dart para la terminal remota
- Componentes nativos del SO que lo requieran (servicio en primer plano, etc.) se envuelven con *platform channel* a Kotlin; el stack multilenguaje es normal cuando se justifica, no exclusivo de pasar todo a Kotlin

**Agente (PC Linux) — confirmado:**
- Python 3.11+, FastAPI + Uvicorn, asyncio
- Se ejecuta como servicio **systemd de usuario** (nunca root/sudo)
- SQLite con patrón repository, sin ORM (schema.sql)
- dbus-fast para integración con D-Bus/systemd-logind
- psutil para métricas del sistema
- iroh para el acceso P2P en WAN (NAT traversal, sin Firebase ni VPN)

**Seguridad:**
- TLS con certificate pinning
- Hashing de contraseñas con Argon2
- Tokens de sesión opacos y revocables
- Rate limiting en login
- Deliberadamente sin 2FA ni JWT

## Estructura del repo

- `app/`: cliente Flutter
- `agent/`: agente Python (incluye `schema.sql`)
- Ramas: `main` (estable), `develop` (integración), `feature/<nombre>` (una por tarea/fase)
- Commits con formato convencional (`feat:`, `fix:`, `docs:`, `test:`, `refactor:`)
- Una etiqueta por versión (`v0.1-beta`, `v0.2`…)

## Convenciones de commits y PRs

- Todos los commits y PRs se proponen a alex para revisión **antes** de hacerse — incluida la forma en que se divide un cambio grande en varias piezas.
- Los commits y PRs van siempre bajo la autoría de alex, nunca de Claude (salvo que alex especifique lo contrario para un commit concreto).
- Commits y PRs **cortos y descriptivos**. Evitar cambios enormes de una sola vez (tipo "+1000/-50 add feature"); dividir en piezas pequeñas y lógicas.
- Motivo: el proyecto se publicará como open source y se quiere evitar que parezca "vibecodeado".

## Uso de IA, librerías y código de terceros

- **Usar librerías/paquetes como infraestructura normal está permitido**, incluso para una funcionalidad diferenciadora/core (p. ej. `xterm.dart` desde pub.dev para la terminal). No hay que reimplementar nada desde cero solo por evitar "usar código ajeno".
- **Lo que sí hay que evitar:** copiar y pegar un fragmento de código concreto encontrado online para resolver el problema exacto de turno, sin entenderlo ni adaptarlo al resto del proyecto.
- El proyecto puede estar generado o asistido por IA, siempre que **alex entienda lo que hace cada parte**. El criterio real no es "cuánto código escribió alex a mano", sino que el resultado sea un proyecto limpio, organizado, legible, escalable, con commits/PRs pequeños y coherentes, que parezca escrito por una persona real y que alex pueda defender.
- Ese entendimiento tiene que aguantar bajo presión en la defensa del TFG: alex debe poder explicar cualquier parte del código, o hacer un cambio pequeño en directo, no solo tener una comprensión superficial.

## Plan de fases

Ver el detalle completo en [`docs/04-plan-de-fases.md`](docs/04-plan-de-fases.md). Resumen (reordenado tras la auditoría de octubre 2026 — iroh se adelanta por ser lo más arriesgado):

**Bloque 1 — Beta v0.1 (objetivo: Navidad 2026):**
- Fase 0 🟢 Preparación y aprender Flutter (sep–oct)
- Fase 1 🟢 Métricas del sistema (oct)
- Fase 2 🔴 Conexión remota con iroh — PoC + integración + matriz de pruebas (nov)
- Fase 3 🔴 Seguridad: login, TLS, Argon2, tokens de sesión (nov)
- Fase 4 🟡 Instalación y servicio systemd (dic)

**Bloque 2 — Núcleo del TFG (enero–mayo 2027):**
- Fase 5 🔴 Terminal remota vía WebSocket + PTY (v0.2) — función estrella del proyecto (ene)
- Fase 6 🟢🟡 Energía y procesos (feb)
- Fase 7 🟡 CRUD de acciones rápidas — cubre el requisito mínimo de CRUD de 2 entidades relacionadas (mar)
- Fase 8 🟡🔴 Notificaciones, reglas de alerta y servicio en primer plano (abr)
- Fase 9 🟢🟡 Descubrimiento (mDNS), emparejamiento por QR y archivos (abr–may)
- Fase 10 🟢 Subida de archivos y pulido final (may)

**Defensa:** primera semana de junio de 2027 (fecha oficial pendiente de confirmar).

**Nunca se recortan:** conexión iroh (fase 2, plan B = modo LAN si falla), login/TLS (fase 3), instalación del servicio (fase 4), terminal (fase 5) y CRUD de acciones rápidas (fase 7).

## Decisiones abiertas
- **Binding de iroh en Android:** el publicado en Maven no incluye Android (hay que compilarlo con Rust + NDK); alternativa, el plugin `iroh_flutter` de pub.dev. Se decide al empezar la fase 2.
- Registro de usuario in-app (código de un solo uso + formulario) vs. creación de usuario solo por CLI — pendiente de resolver antes de la fase 9.

**Ya resueltas:** Flutter como framework del cliente (el tutor lo aceptó 26/09; alex evaluó pasar a Kotlin nativo y decidió quedarse en Flutter, 03/10); el agente en Python es parte fundamental del proyecto (no hace falta preguntarlo).

## Documentación completa

La documentación técnica completa vive en [`docs/`](docs/):
- `01-memoria-tecnica.md`
- `02-necesidades-tecnologicas.md`
- `03-system-context.md`
- `04-plan-de-fases.md`
- `05-referencias-y-proyectos.md`
- `06-ideas-de-futuro.md`
- `07-resumen-decisiones-y-contexto.md`
