# SYSTEM CONTEXT: LINUX SYSTEM COMPANION

> Compact technical context for AI coding assistants. Source of truth: 01-memoria-tecnica.md, 02-necesidades-tecnologicas.md and 04-plan-de-fases.md. If this file conflicts with them, they win.

## 1. PROJECT IDENTITY & SCOPE
* **Project Name:** Linux System Companion (final project of a Spanish vocational degree in multiplatform app development, DAM).
* **Type:** Android app (Flutter) + host agent (Python) running on the user's Linux PC.
* **Core Objective:** Administer a Linux PC from a phone **when you are NOT in front of it**, from the home LAN or from anywhere (4G/5G), with minimal setup: install the agent, run `companion` (TUI) and start the initial setup, scan the QR with the app, create the account. No router configuration, no VPN app on the phone.
* **Design rule:** only features that make sense remotely. Features only useful in front of the PC are out of scope (see section 10).
* **Reference environment:** Android 10+, KDE Plasma 6, systemd, Python 3.11+. Most features are desktop-agnostic.
* **Developer context:** the developer is learning Flutter/Dart from scratch. Prefer simple, readable, well-commented code over clever abstractions. Explain non-obvious Flutter/Android concepts.
* **Decisions:**
  * Flutter: **accepted by the tutor (2026-09-26)**. The Kotlin + Jetpack Compose fallback is no longer needed.
  * The Python agent is a core part of the project (without it the app is useless).
  * Phase order (2026-10-02, revised 2026-10-12): definitive UI with placeholders + metrics first (phase 1), iroh in phase 2 (mid-November – Christmas). Beta has NO login (agent exposes read-only metrics only); security in January (phase 3), before the terminal (phase 4).
  * PC side (2026-10-12): `companion` opens a **TUI (Textual) with buttons**; only `companion serve` and `companion notify` remain terminal commands (Typer). See section 7.
  * Registration (2026-10-12): QR shown in the TUI → app scans it → "Paired, authentication must be created" → username/password dialog in the app. Implemented in phase 9; until then (phase 3) the TUI setup button creates the user directly.
  * Pending review: exact date of the February milestone and official thesis deadline; foreground service type (phase 8); whether the school network lets HTTPS with WebSocket out to the iroh relays.
* **Test phone:** Android 15.

## 2. MANDATORY PROJECT REQUIREMENTS (must be satisfied)
* Layered architecture; Git with branches and meaningful commits; installation manual.
* Usable GUI, smooth navigation, **form validation**.
* User authentication (login + in-app registration after scanning the TUI QR).
* **Full CRUD on at least two related entities**: `grupo` ↔ `accion_rapida` (plus `regla_alerta` and `nota`).
* Business logic (search, filtering, calculations) and proper error handling / user feedback.
* Database with ≥3–4 related tables, accessed through structured classes (repositories), with a creation script (`agent/schema.sql`).
* An extra feature not covered in class (camera/QR, background service + notifications, P2P, PTY terminal).

## 3. ARCHITECTURE
* **Client:** Flutter (Dart), Android only. **MVVM**: Views → ViewModels (`provider`) → Repositories → network services. Every repository has a real implementation and a **fake implementation** with mock data. A small Kotlin module (platform channel) handles the iroh tunnel and the foreground service.
* **Host agent:** Python 3.11+ (minimum: `websockets` requires ≥ 3.11; 3.11 is supported until 2027-10), FastAPI + Uvicorn (asyncio) + `websockets` package for WebSocket support, running as a **systemd user service** (never root, never sudo). Layers: API routes (Pydantic validation) → services (business logic) → repositories (SQLite) → models.
* **Transport:**
  * REST (HTTP/JSON) for one-off actions and CRUD.
  * WebSocket channels: `/ws/terminal` (PTY bytes), `/ws/metrics` (live metrics), `/ws/events` (notifications).
  * Beta: metrics via REST polling every 1–2 s; WebSocket later.
* **LAN:** direct TLS connection; discovery via mDNS (`zeroconf` on the agent, `bonsoir` in Flutter); QR pairing (`mobile_scanner`).
* **WAN — "local tunnel" design (dumbpipe pattern):**
  * Agent: iroh endpoint (Python binding) that forwards incoming streams to its own local FastAPI port.
  * Phone (current design, pending review at the start of phase 2): Kotlin module (official iroh Kotlin binding, which must be built from source with Rust + NDK for Android) opens a local port on `127.0.0.1` and forwards connections to the PC through iroh.
  * Flutter connects to `127.0.0.1:<port>` with **exactly the same HTTP/WebSocket code as LAN**. App-level TLS and login run inside the tunnel unchanged.
  * Platform channel surface: `openTunnel(pcId) -> localPort`, `closeTunnel()`. Nothing else.
  * Alternative under review: the community `iroh_flutter` plugin on pub.dev (1.0.3, builds the Rust core via cargokit). Both options need Rust + Android NDK.
  * Identity: an endpoint gets a new random identity on every start unless its `SecretKey` is persisted; the agent must store it and load it on launch.
  * Connection flow: the connection starts through a relay (used to exchange addresses), then iroh tries to upgrade it to a direct path via NAT traversal; if that fails it stays on the relay.
  * Network needs: no inbound ports; outbound TCP 443 (HTTPS with WebSocket) to the relays is enough. Outbound UDP is optional: if blocked, all traffic stays on the relay (docs.iroh.computer, "Configuring networks").
  * Default: n0 public relays (rate-limited, no SLA, officially "development and hobby use only"; enough for the thesis); custom relays configurable. Fallback plan: LAN-only. WebRTC only as a backup if iroh causes real problems.
  * Versions (checked 2026-10-02): iroh core 1.3.0; Python and Kotlin bindings (iroh-ffi) 1.1.0. The published Kotlin artifact does not include Android: for Android (ARM only: aarch64, armv7) it must be built from source with Rust + NDK (docs.iroh.computer/languages/kotlin). Test iroh on a physical phone, not on an x86_64 emulator. The Python binding only ships glibc wheels (manylinux_2_28).
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
* Lock: call `Session.Lock()` (or `Manager.LockSession(id)`) on the user's own graphical session; the session owner needs no authorization. Do NOT use `LockSessions()`: its polkit default is `auth_admin_keep` even for active sessions.
* Always confirm destructive actions. Handle polkit denials with a clear message.

### D. Processes
* List/search/sort by CPU and memory.
* Kill in two steps: SIGTERM, wait, then offer SIGKILL.
* Only the user's own processes can be killed; show a clear message for others.

### E. Quick actions (CRUD)
* Entities: `grupo` 1:N `accion_rapida` 1:N `ejecucion`. Full CRUD on `grupo` and `accion_rapida`; `ejecucion` is history (created on run, read, filter, delete).
* Execution: `asyncio.create_subprocess_shell` in the action's working directory, with timeout (SIGTERM → SIGKILL), **one concurrent run per action**, output truncated to a max size, statuses `running | success | error | timeout | cancelled`.
* The returned PID is the shell's, not the command's: spawn with `start_new_session=True` and signal the whole process group with `os.killpg`, otherwise the shell's children survive a timeout or cancel.
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

### F. Shared space (notes)
* A space shared between phone and PC to pass **text notes and links** from one side to the other. Full CRUD from the app (create, edit, delete, search); on the PC via TUI buttons (add / view notes).
* No live sync: the app fetches notes when the shared-space screen opens and on pull-to-refresh (the app is meant for use away from the PC). Does NOT use `/ws/events`. Concurrent edits: last write wins.
* Images: **still being considered** (not in confirmed scope). File browsing/transfer is OUT of scope (future idea).

### G. Notifications & alert rules
* Terminal command `companion notify "message"` talks to the agent through a Unix socket at `$XDG_RUNTIME_DIR/companion.sock` (mode `0600`). Usable from scripts or Claude Code hooks.
* Alert rules (`regla_alerta`), full CRUD from the app:
  * metric: cpu, ram, temp, disk;
  * operator;
  * threshold;
  * sustained duration;
  * cooldown;
  * active flag.
* Notification history (`notificacion`): search, filters, mark as read, delete. Origin: manual, rule or action.
* Delivered over `/ws/events`. On the phone, a foreground service keeps the connection alive and shows local notifications (`flutter_local_notifications`). **No Firebase, no external server.** Works in LAN too.
* Android requirements:
  * request `POST_NOTIFICATIONS` at runtime (Android 13+);
  * declare `foregroundServiceType` (mandatory since Android 14). Do NOT use `dataSync`: since Android 15 it is stopped after 6 h per 24 h. Candidate: `connectedDevice` (pending review, to be confirmed in phase 8); it requires `FOREGROUND_SERVICE_CONNECTED_DEVICE` in the manifest plus at least one of `CHANGE_NETWORK_STATE`, `CHANGE_WIFI_STATE` or `CHANGE_WIFI_MULTICAST_STATE`;
  * Android 17: apps with `targetSdk` ≥ 37 must request `ACCESS_LOCAL_NETWORK` for LAN connections and mDNS. Flutter 3.47 defaults to `targetSdk` 36, so it does not apply yet (test phone: Android 15). Pending review: whether connections to `127.0.0.1` (USB and iroh tunnel) count as local network for that permission.

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
| nota | id, usuario_id, tipo (texto/enlace), contenido, origen (móvil/PC), creado_en, actualizado_en | N:1 usuario |

* Enable `PRAGMA foreign_keys = ON` **on every connection** (SQLite disables it by default, and without it `ON DELETE CASCADE` / `SET NULL` are ignored). Parameterized SQL only. One repository class per table. No ORM.
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
GET    /notas?q=                    POST   /notas        PUT /notas/{id}    DELETE /notas/{id}
GET    /reglas  POST /reglas  PUT /reglas/{id}  DELETE /reglas/{id}
GET    /notificaciones?origen=&leida=&q=&desde=&hasta=   PATCH /notificaciones/{id}   DELETE /notificaciones/{id}
WS     /ws/terminal                 WS     /ws/events
```
Route names are a starting proposal; keep them consistent once implemented and update this file.

## 5c. APP SCREENS
QR scan (registration / pairing) → create account dialog · Login · Connection setup (QR; manual address as fallback; later mDNS list) · Dashboard/metrics · Power · Processes · Quick actions list → group form → action form → action detail (stats, Run, history) → execution detail · Terminal · Shared space (notes list/form) · Alert rules list/form · Notification history · Settings (logout, server data).

## 6. SECURITY
* Initial setup (TUI button):
  * generates a self-signed TLS certificate (`cryptography`);
  * opens **registration mode** and shows a terminal QR (`qrcode`) with address, cert fingerprint, iroh id (when available) and a **one-time registration code with short expiry**.
* App scans the QR (`mobile_scanner`), pins the fingerprint, shows "Emparejado, se necesita crear autenticación", then a username/password dialog (confirmation + strength validation). Agent checks the code, stores the password with Argon2 (`argon2-cffi`) and **closes registration mode after the first account**. Expired/used codes are rejected.
* Re-pairing (new phone / reinstall): TUI button shows the pairing QR without a registration code; the app then asks for login.
* Planning: QR registration in phase 9. Phase 3: TUI setup creates the user directly; fingerprint compared visually on first connection.
* **Certificate pinning:** the fingerprint comes from the QR; the app trusts only that certificate.
* **Sessions:** random opaque tokens, stored hashed; the phone stores its token in `flutter_secure_storage`. TUI buttons "log out all sessions" and "change password" revoke all sessions.
* **Rate limiting:** increasing delays after consecutive failed logins (`intento_login`).
* **No 2FA** (deliberate). **No JWT** (opaque tokens are revocable).

## 7. PC INTERFACE (TUI + commands)
* `companion` (no arguments) opens a **Textual** TUI with buttons: initial setup + registration QR · show pairing QR · install / remove service · status · change password · log out all sessions · add / view shared-space notes · export data · export structure.
* Terminal commands (Typer), only: `companion serve` (started by systemd) · `companion notify "<msg>"` (scripts, hooks).
* Exports (phase 7), saved to `XDG_DESKTOP_DIR` (read from `~/.config/user-dirs.dirs`, e.g. `~/Escritorio`), falling back to `$HOME`; timestamp in the name avoids overwriting:
  * data: one JSON file `companion-datos-YYYYMMDD-HHMM.json`, one section per table; excludes `sesion`, `intento_login` and the password hash;
  * structure: folder `companion-estructura-YYYYMMDD-HHMM/` with `tablas.sql`, `indices.sql`, `vistas.sql`, `triggers.sql`, read from `sqlite_schema` (auto-indexes have no SQL and are skipped). Joins are not stored (relations = foreign keys in `tablas.sql`). Empty files get an explanatory comment (no views/triggers in the current design).

## 8. DEPLOYMENT
* Install: `pipx install ...` (not PyInstaller, not plain pip, not Flatpak). Compiled dependencies (iroh, cryptography, argon2) require glibc ≥ 2.28; musl distros (Alpine) are not supported.
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
  * shared clipboard (the shared notes space IS in scope, module F).
* File browsing, download and upload (future idea).
* Images in the shared space: still being considered, do not implement unless the docs change.
* KDE ricing (themes, wallpapers, color schemes) and support for other desktops/WMs.
* iOS and multiple devices.
* 2FA/TOTP and Wake-on-LAN.
* Firebase/FCM, Tailscale/WireGuard, PyInstaller.
* WebRTC/STUN/TURN: not planned; kept only as a backup if iroh causes real problems (decision 2026-09-27).
* Terminal themes (custom palettes) are optional ("if time allows").

See 06-ideas-de-futuro.md.

## 11. PHASES (summary)
* Phase 0: setup (test environment, Git repo) + learn Flutter.
* **Beta v0.1 (Christmas): definitive UI with placeholders + metrics over iroh, no login.**
  * Phase 1: definitive UI (all screens, navigation, placeholders / fake repositories) + real metrics with graphs (mid-October – mid-November);
  * Phase 2: iroh remote access (mid-November – Christmas): proof of concept, integration (no foreground service yet), home test matrix (same Wi-Fi, mobile data, outbound UDP blocked, network switch, restart keeps the same id), then a restrictive network. Until phase 3 the agent exposes only read-only metrics and is started by hand.
* Post-beta (tight schedule: block 2 starts ~4 weeks later than the previous plan):
  * Phase 3: security (minimal TUI that creates the user, login, TLS pinning, sessions), also checked through the tunnel (first half of January);
  * Phase 4: terminal (v0.2) (mid-January – end of February);
* **February milestone** (exact date pending review): app connected through iroh + terminal + performance graphs. If it is early February, the terminal will not be ready.
  * Phase 5: pipx install + systemd service, installed from the TUI (early March);
  * Phase 6: power + processes (March);
  * Phase 7: quick actions CRUD (mandatory requirement) + TUI export buttons (late March – mid-April);
  * Phase 8: notifications + alert rules CRUD + foreground service (late April – mid-May);
  * Phase 9: mDNS + QR pairing + QR registration + shared space for notes and links (May);
  * Phase 10: polish (end of May).
* Thesis report: May (official deadline pending review). Defense: first week of June 2027.
* If time allows: terminal themes.
