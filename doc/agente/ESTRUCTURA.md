# Estructura del agente Python

Organización de `agent/sysmote/` y qué entra en cada carpeta, fase a fase.

```
agent/sysmote/
  api/            rutas de FastAPI
  services/       lógica de negocio
  repositories/   acceso a datos (psutil, SQLite cuando exista)
  models/         modelos Pydantic
  tui/            interfaz de terminal `sysmote` (Textual)
```

## Qué entra en cada carpeta, por fase

| Fase | `api/` | `services/` | `repositories/` | `models/` | `tui/` |
|---|---|---|---|---|---|
| 1 | `GET /metrics` | métricas (llama a `psutil`) | — (datos en vivo, no se guardan) | `MetricsResponse` | TUI completa: banner, cuatro secciones fijas (Emparejamiento, Historial, Base de datos, Notas), la mayoría vacías o deshabilitadas hasta sus fases |
| 3 | login/sesión | autenticación (Argon2, token de sesión) | usuarios/sesiones | `LoginRequest`, `SessionToken` | activa la subpestaña Seguridad de Emparejamiento (configuración inicial, cambiar contraseña, cerrar sesiones) |
| 4 | `WS /ws/terminal` | terminal (PTY sobre tmux con `$SHELL -l`, asyncio) | — | — | — (la terminal es de la app; la TUI no tiene botón propio para ella) |
| 5 | — | — | — | — | activa la subpestaña Servicio de Emparejamiento (instalar/quitar servicio, estado) |
| 6 | listar, buscar, finalizar y congelar procesos; apagar/reiniciar/suspender/bloquear | procesos (`psutil`, señales); energía/sesión (dbus-fast, systemd-logind) | — | — | — |
| 7 | CRUD de grupos y acciones rápidas, `PUT /orden` | ejecución de acciones (timeout, `os.killpg`) | `grupo`, `accion_rapida`, `ejecucion` | `Grupo`, `AccionRapida` | activa Historial (acciones rápidas + log de terminal) y los botones de exportación en Base de datos |
| 8 | notificaciones/reglas de alerta | notificaciones | reglas de notificación | `NotificationRule` | — |
| 9 | espacio de notas, registro QR | notas | `nota` | `Nota` | activa Notas y la subpestaña Dispositivo (QR real, datos del dispositivo emparejado) |

Cada fase solo añade un archivo en la capa que le toca; las carpetas vacías de la fase 1 (`repositories/` sobre todo) se van llenando a partir de la fase 3, cuando aparece la primera tabla. La estructura y el comportamiento completos de la TUI están en [`tui.md`](tui.md).
