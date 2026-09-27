# SYSTEM CONTEXT: LINUX SYSTEM COMPANION

> Compact technical context for AI coding assistants. Source of truth: 01-memoria-tecnica.md, 02-necesidades-tecnologicas.md and 04-plan-de-fases.md. If this file conflicts with them, they win.

## 1. PROJECT IDENTITY & SCOPE
* **Project Name:** Linux System Companion (final project of a Spanish vocational degree in multiplatform app development, DAM).
* **Type:** Android app (Flutter) + host agent (Python) running on the user's Linux PC.
* **Core Objective:** Administer a Linux PC from a phone **when you are NOT in front of it**, from the home LAN or from anywhere (4G/5G), with minimal setup: install the agent, run `companion setup`, install the app, log in. No router configuration, no VPN app on the phone.
* **Design rule:** only features that make sense remotely. Features only useful in front of the PC are out of scope (see section 10).
* **Reference environment:** Android 10+, KDE Plasma 6, systemd, Python 3.11+. Most features are desktop-agnostic.
* **Developer context:** the developer is learning Flutter/Dart from scratch. Prefer simple, readable, well-commented code over clever abstractions. Explain non-obvious Flutter/Android concepts.
* **Pending decisions:**
  * Flutter must be confirmed by the tutor. Fallback: Kotlin + Jetpack Compose.
  * In-app user registration vs. CLI-only user creation is under review. Current design: CLI creates the user.

## 2. MANDATORY PROJECT REQUIREMENTS (must be satisfied)
* Layered architecture; Git with branches and meaningful commits; installation manual.
* Usable GUI, smooth navigation, **form validation**.
* User authentication (login; registration pending review).
* **Full CRUD on at least two related entities**: `grupo` ↔ `accion_rapida` (plus `regla_alerta`).
* Business logic (search, filtering, calculations) and proper error handling / user feedback.
* Database with ≥3–4 related tables, accessed through structured classes (repositories), with a creation script (`agent/schema.sql`).
* An extra feature not covered in class (camera/QR, background service + notifications, P2P, PTY terminal).

## 3. ARCHITECTURE
* **Client:** Flutter (Dart), Android only. **MVVM**: Views → ViewModels (`provider`) → Repositories → network services. Every repository has a real implementation and a **fake implementation** with mock data. A small Kotlin module (platform channel) handles the iroh tunnel and the foreground service.
* **Host agent:** Python 3.11+, FastAPI + Uvicorn (asyncio), running as a **systemd user service** (never root, never sudo). Layers: API routes (Pydantic validation) → services (business logic) → repositories (SQLite) → models.
* **Transport:**
  * REST (HTTP/JSON) for one-off actions and CRUD.
  * WebSocket channels: `/ws/terminal` (PTY bytes), `/ws/metrics` (live metrics), `/ws/events` (notifications).
  * Beta: metrics via REST polling every 1–2 s; WebSocket later.
* **LAN:** direct TLS connection; discovery via mDNS (`zeroconf` on the agent, `bonsoir` in Flutter); QR pairing (`mobile_scanner`).
* **WAN — "local tunnel" design (dumbpipe pattern):**
  * Agent: iroh endpoint (Python binding) that forwards incoming streams to its own local FastAPI port.
  * Phone: Kotlin module (official iroh Kotlin binding) opens a local port on `127.0.0.1` and forwards connections to the PC through iroh.
  * Flutter connects to `127.0.0.1:<port>` with **exactly the same HTTP/WebSocket code as LAN**. App-level TLS and login run inside the tunnel unchanged.
  * Platform channel surface: `openTunnel(pcId) -> localPort`, `closeTunnel()`. Nothing else.
  * Default: n0 public relays; custom relays configurable. Fallback plan: LAN-only.
  * Verify exact iroh binding APIs against their docs before coding.

## 4. MODULES
### A. Terminal
* Spawn `$SHELL -l` in a PTY using Python stdlib (`pty`/`os.openpty`, `fcntl`, `termios`) integrated with asyncio (`loop.add_reader`).
* Env: `TERM=xterm-256color`, `COLORTERM=truecolor`. Resize via `TIOCSWINSZ` ioctl on the master fd.
* Generic for any shell; **officially tested with Zsh**. No shell-specific code.
* Client: `xterm.dart` + special-keys bar (Ctrl, Alt, Tab, Esc, arrows). Bundle a Nerd Font. Handle UTF-8 sequences split across chunks.

### B. Monitoring
* `psutil`: CPU (total + per core), RAM, swap, disk usage per mount, temperatures (`/sys/class/hwmon`), load average, uptime.
* NVIDIA GPU temps optional via `nvidia-smi`.

### C. Power & session
* `dbus-fast` → `org.freedesktop.login1`: PowerOff, Reboot, Suspend, Hibernate (only if `CanHibernate` says yes), lock session.
* Always confirm destructive actions. Handle polkit denials with a clear message.

### D. Processes
* List/search/sort by CPU and memory.
* Kill in two steps: SIGTERM, wait, then offer SIGKILL.
* Only the user's own processes can be killed; show a clear message for others.

### E. Quick actions (CRUD)
* Entities: `grupo` 1:N `accion_rapida` 1:N `ejecucion`. Full CRUD on `grupo` and `accion_rapida`; `ejecucion` is history (created on run, read, filter, delete).
* Execution: `asyncio.create_subprocess_shell` in the action's working directory, with timeout (SIGTERM → SIGKILL), **one concurrent run per action**, output truncated to a max size, statuses `running | success | error | timeout | cancelled`.
* Business rules:
  * action name unique within its group;
  * deleting a group asks to move its actions to "no group" (`grupo_id = NULL`) or delete them;
  * deleting an action deletes its executions (cascade).
* Validation, both in app and agent:
  * name required, 1–50 characters;
  * command required;
  * timeout 1–3600 s;
  * working directory must exist and be accessible (agent-side).
* Stats per action: run count, success rate, average duration, last run.
* Search/sort: by name, group, most used, last run.
* Optional per action: "confirm before running", "notify when finished".

### F. Files
* Browse the filesystem, download PC → phone, upload phone → PC (default: user's XDG download dir).
* OS permissions are the security boundary. On `PermissionError`, the app shows: "root operations must be done from the terminal". The agent never elevates privileges. Normalize and validate every path.

### G. Notifications & alert rules
* CLI `companion notify "message"` talks to the agent through a Unix socket at `$XDG_RUNTIME_DIR/companion.sock` (mode `0600`). Usable from scripts or Claude Code hooks.
* Alert rules (`regla_alerta`), full CRUD from the app:
  * metric: cpu, ram, temp, disk;
  * operator;
  * threshold;
  * sustained duration;
  * cooldown;
  * active flag.
* Notification history (`notificacion`): search, filters, mark as read, delete. Origin: manual, rule or action.
* Delivered over `/ws/events`. On the phone, a foreground service keeps the connection alive and shows local notifications (`flutter_local_notifications`). **No Firebase, no external server.** Works in LAN too.

## 5. DATABASE (SQLite, `~/.local/share/companion/companion.db`, created by `agent/schema.sql`)
| Table | Main columns | Relations |
|---|---|---|
| usuario | id, nombre_usuario (unique), hash_contrasena, creado_en | — |
| sesion | id, usuario_id, hash_token, dispositivo, creado_en, ultimo_acceso, revocada | N:1 usuario |
| intento_login | id, usuario_id (nullable), nombre_usuario, origen, fecha, exito | N:1 usuario |
| grupo | id, usuario_id, nombre, icono, orden, creado_en; unique(usuario_id, nombre) | N:1 usuario |
| accion_rapida | id, usuario_id, grupo_id (nullable), nombre, comando, directorio, timeout_seg, confirmar, notificar_al_terminar, creado_en, actualizado_en | N:1 usuario, N:1 grupo |
| ejecucion | id, accion_id, inicio, fin, estado, codigo_salida, salida | N:1 accion_rapida (ON DELETE CASCADE) |
| regla_alerta | id, usuario_id, nombre, metrica, operador, umbral, duracion_seg, cooldown_seg, activa, creado_en | N:1 usuario |
| notificacion | id, usuario_id, origen, regla_id (nullable, ON DELETE SET NULL), ejecucion_id (nullable, ON DELETE SET NULL), titulo, mensaje, fecha, leida | N:1 usuario, regla_alerta, ejecucion |

* Enable `PRAGMA foreign_keys = ON`. Parameterized SQL only. One repository class per table. No ORM.
* SQLite treats NULLs as distinct in UNIQUE constraints: enforce name uniqueness for "no group" actions in the service layer.
* Editable config in TOML: `~/.config/companion/config.toml` (read with `tomllib`).

## 5b. API OVERVIEW (all routes require a valid session token except `/auth/login`)
```
POST   /auth/login                  POST   /auth/logout
GET    /metrics                     (beta: polling)      WS /ws/metrics (later)
POST   /power/{poweroff|reboot|suspend|hibernate|lock}   GET /power/capabilities
GET    /processes?q=&sort=          POST   /processes/{pid}/terminate   POST /processes/{pid}/kill
GET    /grupos                      POST   /grupos       PUT /grupos/{id}   DELETE /grupos/{id}?modo=mover|borrar
GET    /acciones?grupo=&q=&orden=   POST   /acciones     GET /acciones/{id} (with stats)
PUT    /acciones/{id}               DELETE /acciones/{id}
POST   /acciones/{id}/ejecutar      POST   /ejecuciones/{id}/cancelar
GET    /ejecuciones?accion=&estado=&desde=&hasta=   GET /ejecuciones/{id}
DELETE /ejecuciones/{id}            DELETE /ejecuciones?accion=
GET    /files?path=                 GET    /files/download?path=      POST /files/upload
GET    /reglas  POST /reglas  PUT /reglas/{id}  DELETE /reglas/{id}
GET    /notificaciones?origen=&leida=&q=&desde=&hasta=   PATCH /notificaciones/{id}   DELETE /notificaciones/{id}
WS     /ws/terminal                 WS     /ws/events
```
Route names are a starting proposal; keep them consistent once implemented and update this file.

## 5c. APP SCREENS
Login (+ first-connection fingerprint check) · Connection setup (manual address; later mDNS list + QR scan) · Dashboard/metrics · Power · Processes · Quick actions list → group form → action form → action detail (stats, Run, history) → execution detail · Terminal · File browser · Alert rules list/form · Notification history · Settings (logout, server data).

## 6. SECURITY
* `companion setup`:
  * creates user + strong password (Argon2 via `argon2-cffi`);
  * generates a self-signed TLS certificate (`cryptography`);
  * prints connection data (address, cert fingerprint, iroh id when available) as text and terminal QR.
* *(Under review: setup generates a one-time pairing code instead, and the app shows a registration form.)*
* **Certificate pinning:** the app stores the fingerprint on first connection (beta: visual comparison like SSH; later: QR scan) and trusts only that certificate.
* **Sessions:** random opaque tokens, stored hashed; the phone stores its token in `flutter_secure_storage`. `companion logout-all` and `companion passwd` revoke all sessions.
* **Rate limiting:** increasing delays after consecutive failed logins (`intento_login`).
* **No 2FA** (deliberate). **No JWT** (opaque tokens are revocable).

## 7. CLI (Typer)
`companion setup` · `serve` · `install-service` · `uninstall-service` · `status` · `passwd` · `logout-all` · `show-pairing` · `notify "<msg>"`

## 8. DEPLOYMENT
* Install: `pipx install ...` (not PyInstaller, not plain pip, not Flatpak).
* systemd unit `~/.config/systemd/user/companion.service`: `ExecStart=%h/.local/bin/companion serve`, `Restart=on-failure`, `WantedBy=default.target`.
* Remote reboot requires `loginctl enable-linger $USER` (documented in README). Without an active session, power actions may need a polkit rule.
* App: APK published in GitHub releases.

## 9. DEV WORKFLOW & TESTING
* Git monorepo: `app/` + `agent/`. Branches: `main`, `develop`, `feature/*`. Conventional commits. Tags per version (`v0.1-beta`…).
* Tests:
  * `pytest` for the agent (repositories, business rules, auth, alert rules);
  * `flutter_test` for form validation widgets.
* The school network blocks device-to-device traffic, so testing uses:
  * **`adb reverse tcp:8443 tcp:8443`** over USB (primary; the app connects to `127.0.0.1:8443`);
  * Android emulator (`10.0.2.2` = host);
  * phone hotspot for real-LAN/mDNS tests;
  * fake repositories for UI work.
* The default agent address in the app is `127.0.0.1:8443`.

## 10. OUT OF SCOPE — DO NOT IMPLEMENT
* Near-PC features:
  * media control (MPRIS);
  * per-app volume mixer and audio output switching;
  * peripheral battery (UPower);
  * opening URLs on the PC (xdg-open);
  * phone → desktop notifications;
  * shared clipboard / shared notes.
* KDE ricing (themes, wallpapers, color schemes) and support for other desktops/WMs.
* iOS and multiple devices.
* 2FA/TOTP and Wake-on-LAN.
* Firebase/FCM, WebRTC/STUN/TURN, Tailscale/WireGuard, PyInstaller.
* Terminal themes (custom palettes) are optional ("if time allows").

See 06-ideas-de-futuro.md.

## 11. PHASES (summary)
* Phase 0: setup (tutor questions, test environment, Git repo) + learn Flutter.
* **Beta v0.1 (mid-December):**
  * Phase 1: metrics;
  * Phase 2: security (CLI setup, login, TLS pinning, sessions);
  * Phase 3: power + processes;
  * Phase 4: pipx install + systemd service.
* Early January: iroh proof of concept (from 4G and from the school network).
* Post-beta:
  * Phase 5: quick actions CRUD (mandatory requirement);
  * Phase 6: terminal (v0.2);
  * Phase 7: mDNS + QR pairing + registration (pending) + file browsing/download;
  * Phase 8: iroh remote access;
  * Phase 9: notifications + alert rules CRUD;
  * Phase 10: file upload + polish.
* If time allows: terminal themes.
