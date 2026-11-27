# Documentación del agente (Python)

El **agente** es el programa que corre en el PC Linux del usuario y hace todo el trabajo: abre las terminales, mide el sistema, ejecuta acciones y guarda los datos. La app del móvil es solo el cliente que lo muestra y le manda órdenes.

**Estado:** ver `04-plan-de-fases.md` (fases 1 y 2 cerradas; la fase 3, seguridad, implementada en el agente).

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
| [`tui.md`](tui.md) | Especificación de la TUI del agente (`sysmote`): estructura, las cuatro secciones (Emparejamiento con sus subpestañas, Historial, Base de datos, Notas), comportamiento y colores |
| [`estructura.md`](estructura.md) | Organización de `agent/sysmote/` (`api/`, `services/`, `repositories/`, `models/`, `tui/`) y qué entra en cada carpeta, fase a fase |
| [`tests.md`](tests.md) | Los tests del agente (`agent/tests/`): qué prueba cada archivo y para qué sirve |

## Dónde está el resto sobre el agente

Para no duplicar, el resto del diseño del agente sigue en los documentos generales:

| Tema | Dónde |
|---|---|
| Módulos funcionales (terminal, métricas, energía, acciones, notas…) | `01-memoria-tecnica.md`, §3 |
| Base de datos y esquema | `01-memoria-tecnica.md`, §6 |
| API REST y WebSocket | `01-memoria-tecnica.md`, §3 (rutas de cada módulo) |
| Seguridad | `01-memoria-tecnica.md`, §5 |
| Acceso remoto con iroh (túnel del agente, `iroh_tunnel.py`) | [`../iroh/`](../iroh/README.md) |
| Instalación y servicio systemd | `01-memoria-tecnica.md`, §8 · `02-necesidades-tecnologicas.md`, §7 |
| Fases de implementación | `04-plan-de-fases.md` |

## Implementación actual

- **API:** las rutas de seguridad están en el contrato de la fase 3 ([`contrato-api-fase3.md`](contrato-api-fase3.md)), y `GET /metrics` exige sesión. `/docs` está desactivado. El resto de rutas son diseño en `01-memoria-tecnica.md` §3, sin implementar.
- **Seguridad:** descrita en [`estructura.md`](estructura.md) y [`tui.md`](tui.md); las tablas, en `agent/sysmote/schema.sql`. Cada archivo del código empieza con un comentario que explica su papel.

## Por crear en esta carpeta

- Instalación, servicio y comprobación de dependencias del sistema (sin implementar, fase 4).
