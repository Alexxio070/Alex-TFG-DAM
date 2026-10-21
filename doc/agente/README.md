# Documentación del agente (Python)

El **agente** es el programa que corre en el PC Linux del usuario y hace todo el trabajo: abre las terminales, mide el sistema, ejecuta acciones y guarda los datos. La app del móvil es solo el cliente que lo muestra y le manda órdenes.

**Estado:** ver `04-plan-de-fases.md` (fase 1).

## Stack (resumen)

| Pieza | Tecnología |
|---|---|
| Lenguaje y servidor | Python 3.11+, FastAPI + Uvicorn, asyncio |
| Ejecución | Servicio de usuario de systemd (nunca root ni sudo) |
| Datos | SQLite con patrón repository, sin ORM (`schema.sql`) |
| Sistema | `psutil` (métricas), `dbus-fast` (systemd-logind) |
| Terminal | **tmux** para las sesiones y PTY de la biblioteca estándar para el cliente interno |
| Acceso desde fuera | iroh (P2P, sin VPN ni abrir puertos) |

Fuente de verdad del stack: `CLAUDE.md` y `../documentos-generales-del-proyecto/02-necesidades-tecnologicas.md`.

## Documentos de esta carpeta

| Documento | Contenido |
|---|---|
| [`terminal-sesiones-tmux.md`](terminal-sesiones-tmux.md) | Diseño de la terminal: sesiones persistentes con tmux, ventana en el PC, ciclo de vida, requisitos y pendientes |
| [`tui.md`](tui.md) | Especificación de la TUI del agente (`companion`): estructura, las cuatro secciones (Emparejamiento con sus subpestañas, Historial, Base de datos, Notas), comportamiento y colores |

## Dónde está el resto sobre el agente

Para no duplicar, el resto del diseño del agente sigue en los documentos generales:

| Tema | Dónde |
|---|---|
| Módulos funcionales (terminal, métricas, energía, procesos, acciones, notas…) | `01-memoria-tecnica.md`, §3 |
| Base de datos y esquema | `01-memoria-tecnica.md`, §6 |
| API REST y WebSocket | `01-memoria-tecnica.md`, §3 (rutas de cada módulo) |
| Seguridad | `01-memoria-tecnica.md`, §5 |
| Instalación y servicio systemd | `01-memoria-tecnica.md`, §8 · `02-necesidades-tecnologicas.md`, §7 |
| Fases de implementación | `04-plan-de-fases.md` |

## Por crear en esta carpeta

Cuando haya implementación o decisiones que no quepan en los documentos generales:

- Referencia de la API del agente (de momento solo existe `GET /metrics`, documentada por FastAPI en `/docs`; el resto de rutas son diseño en `01-memoria-tecnica.md` §3, sin implementar).
- Esquema de la base de datos y repositorios (no existe `schema.sql`: las primeras tablas llegan en la fase 3).
- Seguridad: certificados, sesiones y límite de intentos (sin implementar, fase 3).
- Instalación, servicio y comprobación de dependencias del sistema (sin implementar, fase 5).
