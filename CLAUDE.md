# Linux System Companion (TFG)

TFG de DAM (Desarrollo de Aplicaciones Multiplataforma) de alex. Es una app Android + un agente Python en el PC Linux del usuario para administrar ese PC en remoto desde el móvil (LAN o WAN), sin configurar router ni VPN.

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

**Cliente (Android):**
- Flutter/Dart, arquitectura MVVM + provider
- xterm.dart para la terminal remota

**Agente (PC Linux):**
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

## Plan de fases (0–10)

Fases 0–4 (objetivo beta v0.1, mediados de diciembre 2026): setup, métricas, seguridad, energía/procesos, instalación + servicio systemd.

Fases 5–10 (trabajo principal del TFG, enero–mayo 2026): CRUD de acciones rápidas, terminal, discovery/pairing/archivos, acceso remoto vía iroh, notificaciones/alertas, subida de archivos y pulido final.

> Nota: el detalle exacto de cada fase (qué entra en cada una) está pendiente de confirmar con alex — este resumen viene de las decisiones tomadas hasta ahora, no del documento completo de plan de fases. Alex: si algo aquí no coincide con tu plan de fases real, dímelo y lo corrijo.

## Decisiones abiertas
- Registro de usuario in-app vs. creación de usuario solo por CLI (pendiente de resolver antes de la fase 7).

## Documentación completa

La documentación técnica completa (memoria técnica, necesidades tecnológicas, contexto del sistema, plan de fases detallado, referencias, decisiones) vive en la carpeta local "Documentacion TFG" de alex, fuera de este repo. Pendiente de subir a un directorio `docs/` de este repositorio.
