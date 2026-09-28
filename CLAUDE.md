# Linux System Companion (TFG)

TFG de DAM (Desarrollo de Aplicaciones Multiplataforma) de alex. Es una app Android + un agente Python en el PC Linux del usuario para administrar ese PC en remoto desde el móvil (LAN o WAN), sin configurar router ni VPN.

> ⚠️ **Stack cliente en revisión (2026-09-27):** el cliente está planteado en Flutter/Dart, pero alex encontró una serie de contras y está evaluando pasar todo el proyecto a Kotlin nativo. Todas las referencias a Flutter/Dart/MVVM+provider/xterm.dart en este documento son **provisionales**, no una decisión cerrada. No asumas Flutter al generar código del cliente sin confirmar primero.

**Alcance de este repo:** aquí vive únicamente el trabajo del PROYECTO (el entregable que se presenta al tribunal). El aprendizaje personal de las tecnologías (hilos "APRENDIZAJE:") se lleva en el chat del proyecto de claude.ai, no en este repositorio — no aplican aquí las instrucciones de estilo docente de esos hilos.

## Módulos previstos
- Terminal remota (PTY)
- Monitorización de sistema en vivo (psutil)
- Control de energía/sesión (dbus-fast + systemd-logind)
- Gestión de procesos
- "Acciones rápidas": comandos guardados con CRUD completo (grupo → acción_rápida → ejecución — este es el requisito obligatorio de CRUD de 2 entidades relacionadas)
- Exploración y transferencia de archivos
- Notificaciones y reglas de alerta (socket/websocket propio, sin Firebase)

## Stack

**Cliente (Android) — 🔶 en revisión, ver nota al principio:**
- Planteado en Flutter/Dart, arquitectura MVVM + provider
- xterm.dart para la terminal remota
- Alternativa que se está evaluando: Kotlin nativo (Jetpack Compose) para todo el proyecto

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

- `app/`: cliente Android (lenguaje pendiente de confirmar — ver nota sobre Flutter/Kotlin)
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

Ver el detalle completo en [`docs/04-plan-de-fases.md`](docs/04-plan-de-fases.md). Resumen:

**Bloque 1 — Beta v0.1 (objetivo: mediados de diciembre 2026):**
- Fase 0 🟢 Preparación y aprender el framework del cliente (sep–oct)
- Fase 1 🟢 Métricas del sistema (oct)
- Fase 2 🔴 Seguridad: login, TLS, Argon2, tokens de sesión (nov)
- Fase 3 🟢🟡 Energía y procesos (nov–dic)
- Fase 4 🟡 Instalación y servicio systemd (dic)

**Bloque 2 — Núcleo del TFG (enero–mayo 2026):**
- PoC de iroh 🔴 (2–3 días, principios de enero)
- Fase 5 🟡 CRUD de acciones rápidas — cubre el requisito mínimo de CRUD de 2 entidades relacionadas (ene)
- Fase 6 🔴 Terminal remota vía WebSocket + PTY — función estrella del proyecto (feb)
- Fase 7 🟢🟡 Descubrimiento (mDNS), emparejamiento por QR y archivos (mar)
- Fase 8 🔴 Acceso remoto vía iroh (mar–abr)
- Fase 9 🟡 Notificaciones y reglas de alerta (abr–may)
- Fase 10 🟢 Subida de archivos y pulido final (may)

**Nunca se recortan:** login/TLS (fase 2), instalación del servicio (fase 4), CRUD de acciones rápidas (fase 5) y la terminal (fase 6).

## Decisiones abiertas
- **Lenguaje/framework del cliente Android:** Flutter (planteado originalmente, aceptado por el tutor) vs. Kotlin nativo — **en revisión activa por alex**, ver nota al principio del documento.
- ¿El agente en Python cuenta como parte del proyecto? — preguntar al tutor.
- Registro de usuario in-app (código de un solo uso + formulario) vs. creación de usuario solo por CLI — pendiente de resolver antes de la fase 7.

## Documentación completa

La documentación técnica completa vive en [`docs/`](docs/):
- `01-memoria-tecnica.md`
- `02-necesidades-tecnologicas.md`
- `03-system-context.md`
- `04-plan-de-fases.md`
- `05-referencias-y-proyectos.md`
- `06-ideas-de-futuro.md`
- `07-resumen-decisiones-y-contexto.md`
