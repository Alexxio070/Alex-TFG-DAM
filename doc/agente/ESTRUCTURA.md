# Estructura del agente Python

Organización de `agent/sysmote/` y qué entra en cada carpeta, fase a fase.

```
agent/schema.sql  esquema de SQLite (se aplica al abrir la base de datos)
agent/sysmote/
  api/            rutas de FastAPI, formato de errores y dependencia de sesión
  services/       lógica de negocio
  repositories/   acceso a datos (psutil, SQLite)
  models/         modelos Pydantic
  tui/            interfaz de terminal `sysmote` (Textual)
  database.py     conexión a SQLite (permisos 0700/0600, claves foráneas activas)
  server.py       servidores del agente: HTTPS (USB/LAN), HTTP interno y túnel iroh, en un hilo
  iroh_tunnel.py  túnel iroh (fase 2): fuera de las capas, reenvía las conexiones iroh al puerto local del agente
```

## Qué entra en cada carpeta, por fase

| Fase | `api/` | `services/` | `repositories/` | `models/` | `tui/` |
|---|---|---|---|---|---|
| 1 | `GET /metrics` | métricas (llama a `psutil`) | — (datos en vivo, no se guardan) | `Metrics`, `Partition` | TUI completa: banner, cuatro secciones fijas (Emparejamiento, Historial, Base de datos, Notas), la mayoría vacías o deshabilitadas hasta sus fases |
| 3 | `/estado`, `/registro`, `/login`, `/login/solicitud/{id}`, `/logout`, `/desemparejar`, `/sesion`, `/capacidades`; protege `/metrics` | autenticación (`auth_service`), contraseñas con Argon2 (`password_service`), tokens (`token_service`), límite de intentos (`limite_service`), configuración (`config_service`), certificado TLS (`tls_service`), emparejamiento y QR (`pairing_service`) | `usuario`, `sesion`, `intento_login`, `solicitud_login`, `codigo_registro` | `Usuario`, `Sesion`, `IntentoLogin`, `SolicitudLogin`, `CodigoRegistro`, `RegistroRequest`, `LoginRequest` | activa las subpestañas Seguridad (configuración inicial, cambiar contraseña, cerrar sesiones, reiniciar intentos, solicitud de login) y Dispositivo (QR de emparejamiento, sesión activa, desemparejar) |
| 4 | `WS /ws/terminal` | terminal (PTY sobre tmux con `$SHELL -l`, asyncio) | — | — | — (la terminal es de la app; la TUI no tiene botón propio para ella) |
| 5 | — | — | — | — | activa la subpestaña Servicio de Emparejamiento (instalar/quitar servicio, estado) |
| 6 | listar, buscar, finalizar y congelar procesos; apagar/reiniciar/suspender/bloquear | procesos (`psutil`, señales); energía/sesión (dbus-fast, systemd-logind) | — | — | — |
| 7 | CRUD de grupos y acciones rápidas, `PUT /orden` | ejecución de acciones (timeout, `os.killpg`) | `grupo`, `accion_rapida`, `ejecucion` | `Grupo`, `AccionRapida` | activa Historial (acciones rápidas + log de terminal) y los botones de exportación en Base de datos |
| 8 | notificaciones/reglas de alerta | notificaciones | reglas de notificación | `NotificationRule` | — |
| 9 | espacio de notas | notas | `nota` | `Nota` | activa Notas (el QR de Dispositivo ya está desde la fase 3; en la fase 9 llega el escáner en la app) |

Cada fase solo añade un archivo en la capa que le toca; las carpetas vacías de la fase 1 (`repositories/` sobre todo) se van llenando a partir de la fase 3, cuando aparece la primera tabla. La estructura y el comportamiento completos de la TUI están en [`tui.md`](tui.md).

**Fase 3 (seguridad).** `server.py` y `database.py` también quedan fuera de las capas: arrancan y paran los servidores, y abren la conexión a SQLite. El comando `sysmote` abre la TUI y arranca por debajo los servidores (HTTPS en el 8443, HTTP interno en `127.0.0.1:8444` y el túnel iroh que reenvía a ese puerto); al salir de la TUI se paran. Los servicios no importan nada de `tui/` ni de `api/`: la TUI y la API los llaman, y se comunican entre sí solo a través de SQLite. `iroh_tunnel.py` no se modifica: `server.py` lo invoca igual que la prueba de concepto.

**Fase 2 (iroh).** `iroh_tunnel.py` vive directamente en `agent/sysmote/`, fuera de las capas, porque no es parte de la API ni toca datos: acepta conexiones iroh y copia los bytes de cada flujo al puerto local donde escucha FastAPI, sin mirarlos. Lo arranca `sysmote.server.Servidores` al abrir la TUI, junto a los servidores HTTPS e interno; el servicio systemd que lo mantenga sin la TUI llega en la fase 5. Detalle en `doc/iroh/`.
