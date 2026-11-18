# Auditoría de simplificación y legibilidad del agente Python

Rama local `refactor/auditoria-backend`, cortada de `origin/main` (`c7e1d9c`). Fecha: 18-19/11/2026.

**Objetivo:** que cualquier persona que abra `agent/` entienda cómo funciona, y que Alex pueda explicar cualquier parte ante el tribunal. Es una limpieza: **no cambia el comportamiento ni el contrato de la API**.

**Alcance:** todo `agent/` salvo `sysmote/iroh_tunnel.py`, `scripts/iroh_poc.py` y los tests de iroh (son de la sesión de iroh), más `doc/agente/` (`ESTRUCTURA.md`, `tui.md`, `tests.md`, `README.md`). El contrato (`doc/agente/contrato-api-fase3.md`) no se ha tocado.

## Resumen

| | Antes | Después |
|---|---|---|
| Tests (total) | 188 | 154 |
| Tests del agente (sin iroh) | 175 | 141 |
| Tests de iroh (no tocados) | 13 | 13 |
| Módulos sin comentario inicial | 22 | 0 |
| Clases y funciones públicas sin docstring¹ | 133 de 140 | 0 de 113 |
| Funciones sin uso en el código | 3 (+2 parámetros) | 0 |

¹ Sin contar los métodos que Textual llama solo (`compose`, `on_mount`, `on_button_pressed`…), que no llevan docstring para no añadir relleno.

La suite estuvo en verde antes y después de cada bloque:

```
cd agent && .venv/bin/pytest -q      # 154 passed
```

## Commits

| Commit | Bloque | Qué hace |
|---|---|---|
| `4a3a4b9` | M | Quita código sin uso en repositorios y servicios |
| `9375f6f` | S | Simplifica la sesión activa, el dispositivo por defecto y los repositorios |
| `f985aa1` | R1 | El código de registro vigente pasa a ser un método de la app de la TUI |
| `9433b33` | R2 | La ruta `/sesion` pasa por el servicio de autenticación |
| `39cc1e8` | R3 | Reúne en `sysmote/rutas.py` las rutas donde el agente guarda sus archivos |
| `7f3a3b0` | R4 | Fixture de conexión común en `tests/conftest.py` |
| `8204201` | T | Quita los tests redundantes (con demostración por mutación) |
| `30ebc35` | C | Comentarios y docstrings en todo el código del agente |
| `72e00d5` | D | Actualiza `doc/agente/` y `agent/README.md` |

## Hallazgos y qué se hizo

### E. Entorno (fuera del repositorio, sin commit)

- **E1.** El venv se había movido desde `TFG-agent`, así que `.venv/bin/pytest` y `.venv/bin/sysmote` apuntaban a un intérprete que ya no existía.
  - *Hecho:* `pip install -e ".[dev]"` y reinstalación de `pytest`, `uvicorn` y `pip` en el venv.
  - *Pendiente:* `activate` y otras herramientas sueltas del venv (`fastapi`, `httpx2`…) siguen apuntando a la ruta vieja. Solo se arregla recreando el venv.
- **E2.** Quedaban restos del nombre antiguo del proyecto: la carpeta `agent/linux_system_companion.egg-info` y el paquete `linux-system-companion` registrado en el venv. *Hecho:* borrados.
- **Incidente durante la auditoría.** Para comprobar que el comando funcionaba ejecuté `sysmote --help`. Ese comando no tiene ayuda: abrió la TUI y los servidores de verdad.
  - Lo paré enseguida y comprobé que los puertos 8443 y 8444 quedaban libres.
  - Había creado en el `HOME` real `~/.config/sysmote/cert.pem`, `key.pem` y `~/.local/share/sysmote/iroh_secret_key.bin`. Los borré.
  - No toqué `sysmote.db` ni `iroh_secret_key_poc.bin`, que ya existían.

### M. Código muerto (comprobado con `grep`: solo lo usaban tests)

| # | Dónde | Hecho |
|---|---|---|
| M1 | `sesion_repository.obtener_activa_de_usuario` | Eliminada, junto con su test |
| M2 | `solicitud_login_repository.obtener_pendiente_de_usuario` | Eliminada |
| M3 | `password_service.necesita_rehash` | Eliminada (no la usaba nada) |
| M4 | `intento_login_repository.listar_recientes_de_usuario(…, desde)` | Pasa a `listar_de_usuario(connection, nombre)`: `desde` siempre llegaba vacío |
| M5 | `token_service.esta_caducada(…, ahora=None)` | Quitado el parámetro `ahora`, que nunca se pasaba |

### S. Simplificaciones

| # | Hecho |
|---|---|
| S1 | Las tres funciones encadenadas para la sesión activa (`_sesion_vigente`, `_sesion_activa_vigente`, `sesion_activa`) quedan en una sola, `auth_service.sesion_activa` |
| S2 | El dispositivo por defecto («Móvil») estaba en el servicio y en el modelo. Ahora es una constante en `models/auth.py`, usada por los dos modelos de petición. `registrar` exige `dispositivo` |
| S3 | `tls_service.asegurar_certificado` usa `certificado_existe()` en vez de repetir la condición |
| S4 | `usuario_repository` usa `_COLUMNS` y `_to_usuario`, como los demás repositorios |

### R. Estructura

| # | Hecho |
|---|---|
| R1 | `codigo_vigente(app)` estaba en `tui/widgets/formato.py` y no era formato. Ahora es el método `SysmoteApp.codigo_registro_vigente()` |
| R2 | `api/auth.py` llamaba al repositorio de usuarios saltándose la capa de servicios. Ahora `/sesion` usa `auth_service.datos_sesion()`, y la API ya no importa ningún repositorio |
| R3 | Nuevo `sysmote/rutas.py` con todas las rutas: base de datos, certificado, clave, clave iroh y `config.toml`. Los módulos las leen al usarlas, y `conftest.py` las redirige en un solo sitio |
| R4 | La fixture `connection` estaba copiada en 5 archivos. Ahora hay una sola en `conftest.py`, que abre la base de datos con `database.connect()` (igual que el agente) en una carpeta temporal |

**No se hizo, a propósito:**
- renombrar identificadores que mezclan inglés y español (mucho cambio sin ganar claridad);
- partir `auth_service.py` (tiene una sola responsabilidad; se ha ordenado en secciones «API» y «TUI»);
- mover `schema.sql` dentro del paquete. Solo afecta a instalaciones no editables, que llegan con el servicio de la fase 5.

### C. Comentarios y docstrings

- Cada módulo de `sysmote/` y cada archivo de test empieza con un comentario que dice qué hace y qué papel tiene.
- Las clases y funciones públicas llevan docstrings estilo Google (compatibles con `pdoc`): propósito y, donde aporta, `Args`, `Returns` y `Raises`.
- Comentarios falsos corregidos:
  - `schema.sql` hablaba de un `ON DELETE CASCADE` que no existe;
  - `database_section.py` decía «cuando exista la BD».
- Comentarios nuevos donde algo no se entendía:
  - por qué `tui/app.py` importa `Servidores` dentro de `main()`;
  - por qué `pairing_service.py` usa una función privada de `iroh_tunnel.py`;
  - por qué la TUI vuelve a leer SQLite cada segundo;
  - cómo `direccion_lan()` averigua la IP sin enviar paquetes.
- **Importar sin efectos:** ningún módulo arranca servidores ni abre conexiones al importarse. Solo `metrics_repository.py` hace una lectura inicial de `psutil`, inofensiva y comentada.
- `pdoc` no está instalado, así que no he generado la documentación HTML para comprobar el resultado.

### D. Documentación

| # | Dónde | Hecho |
|---|---|---|
| D1 | `tui.md` | El banner decía «LINUX SYSTEM» y que cambiaba por debajo de ~97 columnas. Ahora dice «SYSMOTE» y 66 columnas (`BANNER_MIN_WIDTH`) |
| D2 | `tui.md` | La sección Base de datos se describía como si funcionara. Ahora está marcada como diseño pendiente; la base de datos ya existe |
| D3 | `ESTRUCTURA.md` | Árbol con `tui/` por dentro, `main.py` y `rutas.py`; el recorrido de una petición por las capas; el arranque con `sysmote` (antes decía que llegaría en la fase 5) |
| D4 | `agent/README.md` | Faltaba `/login/solicitud/{id}` entre las rutas sin sesión |
| D5 | `doc/agente/README.md` | «Por crear» listaba cosas ya hechas; ahora hay una sección «Implementación actual» |
| D6 | `tests.md` | Cifras y tablas actualizadas, con el criterio de por qué los repositorios no tienen tests propios |

## T. Revisión de tests

### Criterio

Los repositorios son SQL directo, y los tests de servicios, API y TUI los ejercitan sobre SQLite real, no sobre simulaciones. Por eso los tests propios de cada repositorio eran repetidos. También se quitaron tests cuyo comportamiento ya cubría otro test más completo.

Siempre se conservan los tests de seguridad (login, tokens, límite de intentos, sesión única, registro) y los del contrato. **Ningún test se borró sin demostrar antes que otro cubre lo mismo:** se rompió a propósito el código que protegía y se comprobó que algún test de los que quedan fallaba.

### Tests quitados (34) y recuperados (2)

| Archivo | Antes | Después | Qué se quitó |
|---|---|---|---|
| `test_auth_repositories.py` | 15 | — | Todo el archivo (2 tests ya habían caído con el código muerto). Se recupera 1 test en `test_sesion_repository.py` |
| `test_codigo_registro_repository.py` | 5 | — | Todo el archivo |
| `test_database.py` | 4 | 2 | «Crea las cinco tablas» y «es idempotente» |
| `test_password_service.py` | 5 | 3 | «Acepta la correcta» y «rechaza la incorrecta» |
| `test_token_service.py` | 6 | 5 | «Mismo token, mismo hash» |
| `test_tls_service.py` | 5 | 3 | «Huella hexadecimal de 64» y «par válido» |
| `test_limite_service.py` | 12 | 10 | «Comprobar lanza demasiados_intentos» y «reiniciar levanta el bloqueo» |
| `test_pairing_service.py` | 7 | 6 | «Solo usa caracteres de bloque» |
| `test_auth_service.py` | 52 | 51 | `estado_con_registro_abierto`; `desemparejar_sin_sesion…` se rehízo con un `assert` real (no tenía ninguno) |
| `test_server.py` | 10 | 7 | «Arrancan», «puerto interno responde» y «`/metrics` exige login»; sus `assert` pasan al test de extremo a extremo |
| `test_tui_security.py` | 22 | 21 | «Arranca y detiene los servidores» con servidores falsos (lo cubre el test real de la tecla `q`) |
| `test_sesion_repository.py` | — | 1 | Nuevo: el único caso que ningún otro test cubría |

Además, `test_api_auth.py::test_el_origen_del_intento_se_guarda` se reforzó: antes solo comprobaba que el origen no estuviera vacío, y ahora que es la dirección del cliente.

### Demostración por mutación

Cada fila es una rotura deliberada del código, aplicada y deshecha al momento, y el primer test que la detectó con la suite reducida (`pytest -x`).

| # | Rotura | Sustituye al test eliminado | Detectada por |
|---|---|---|---|
| U1 | Buscar usuario por nombre con `!=` | repos: obtener usuario por nombre | `test_api_auth::test_login_con_sesion_activa_da_202…` |
| U2 | `crear` devuelve un id equivocado | repos: crear usuario | `test_api_auth::test_registro_devuelve_201…` |
| U3 | `existe_alguno` invertido | repos: existe alguno | `test_api_auth::test_estado_es_publico` |
| U4 | Cambiar contraseña no guarda nada | repos: actualizar contraseña | `test_auth_service::test_cambiar_contrasena_actualiza…` |
| S1 | Buscar sesión por token con `!=` | repos: sesión por token | `test_api_auth::test_registro_devuelve_201…` |
| S2 | Las sesiones nacen revocadas | repos: sesión se crea activa | `test_api_auth::test_registro_devuelve_201…` |
| S3 | `revocar` guarda mal el motivo | repos: revocar guarda el motivo | `test_api_auth::test_desemparejar_da_204…` |
| **S4** | **Revocar todas también revoca las de otro usuario** | **repos: no toca las de otro** | **Ninguno → test recuperado en `test_sesion_repository.py`** |
| S5 | Tocar el último acceso no hace nada | repos: tocar último acceso | `test_auth_service::test_autenticar_renueva_el_ultimo_acceso` |
| I1 | Listar intentos de otro usuario | repos: intentos se listan | `test_api_auth::test_cinco_fallos_dan_429…` |
| I2 | Se guarda el éxito al revés | repos: intento guarda el éxito | `test_api_auth::test_cinco_fallos_dan_429…` |
| I3 | Borrar intentos no borra | repos: borrar intentos | `test_auth_service::test_reiniciar_intentos_permite_volver_a_entrar` |
| L1 | Buscar solicitud por id con `!=` | repos: obtener solicitud | `test_api_auth::test_login_con_sesion_activa_da_202…` |
| L2 | Las solicitudes nacen aprobadas | repos: solicitud pendiente | `test_api_auth::test_login_con_sesion_activa_da_202…` |
| L3 | Cambiar estado no hace nada | repos: actualizar estado | `test_api_auth::test_login_con_sesion_activa_da_202…` |
| L4 | Borrar solicitud no borra | repos: borrar solicitud | `test_api_auth::test_login_con_sesion_activa_da_202…` |
| C1 | Buscar código por hash con `!=` | repos: código por hash | `test_api_auth::test_registro_devuelve_201…` |
| C2 | Vigente con la caducidad al revés | repos: existe vigente (caducidad) | `test_auth_service::test_abrir_registro_genera_un_codigo…` |
| C3 | Vigente solo si está usado | repos: existe vigente (usados) | `test_auth_service::test_abrir_registro_genera_un_codigo…` |
| C4 | `existe_alguno` de códigos invertido | repos: existe alguno (códigos) | `test_api_auth::test_registro_con_codigo_equivocado_da_403…` |
| C5 | Marcar usado no marca | repos: marcar usado | `test_auth_service::test_registrar_con_un_codigo_ya_usado…` |
| C6 | Borrar códigos no borra | repos: borrar todos | `test_auth_service::test_el_codigo_caducado_deja_de_reconocerse…` |
| D1 | Falta la tabla `codigo_registro` | database: crea las tablas | `test_api_auth::test_estado_es_publico` |
| D2 | El esquema falla al reabrir | database: idempotente | `test_api_auth::test_rutas_protegidas_sin_token…` |
| P1 | Verificar siempre falso | password: acepta la correcta | `test_api_auth::test_login_con_sesion_activa_da_202…` |
| P2 | Verificar siempre cierto | password: rechaza la incorrecta | `test_api_auth::test_login_con_credenciales_malas_da_401` |
| T1 | Hash del token no determinista | token: mismo hash | `test_api_auth::test_registro_devuelve_201…` |
| X1 | Huella en mayúsculas | tls: huella hexadecimal | `test_server::test_https_responde_y_el_certificado…` |
| X2 | Certificado con otra clave | tls: par válido | `test_server::test_https_responde_y_el_certificado…` |
| M1 | El límite nunca bloquea | límite: comprobar lanza | `test_api_auth::test_cinco_fallos_dan_429…` |
| M2 | Reiniciar intentos no hace nada | límite: reiniciar | `test_auth_service::test_reiniciar_intentos_permite_volver_a_entrar` |
| Q1 | El QR usa otro carácter para el blanco | pairing: solo bloques | `test_tui_security::test_dispositivo_muestra_el_qr…` |
| **A1** | **Desemparejar sin sesión falla** | **auth: desemparejar sin sesión** | **Ninguno → test recuperado con un `assert` real** |
| A2 | `registro_abierto` siempre falso | auth: estado con registro abierto | `test_auth_service::test_abrir_registro_genera_un_codigo…` |
| V1 | Los servidores nunca constan como activos | server: arrancan | `test_server::test_https_responde_y_el_certificado…` |
| V2 | El puerto interno escucha en otro puerto | server: puerto interno responde | `test_server::test_registro_login_y_metricas_de_extremo_a_extremo…` |
| V3 | `/metrics` sin login | server: `/metrics` exige login | `test_api_auth::test_rutas_protegidas_sin_token…` |
| F1 | La TUI no arranca los servidores | tui: arranca los servidores | `test_server::test_salir_de_la_tui_con_q…` |
| F2 | La TUI no para los servidores | tui: detiene los servidores | `test_server::test_salir_de_la_tui_con_q…` |
| O1 | El origen del intento es fijo («local») | (refuerzo) | `test_api_auth::test_el_origen_del_intento_se_guarda` |

Tras recuperar los dos tests, S4 y A1 también quedan detectadas. El script de mutaciones fue una herramienta temporal y no forma parte del repositorio.

### Tests frágiles (conservados)

- **TUI con pausas** (`test_tui_security.py`): dependen de esperas de tiempo (`pilot.pause`, sondeo de 0,05 s). En una máquina muy cargada podrían fallar.
- **iroh en `test_server.py`**: necesita red para que el túnel arranque.
- **`direccion_lan`**: depende de la red del equipo, aunque sin red devuelve `127.0.0.1`.
- **Lector real del QR**: se omite si `zbarimg` no está instalado.

### Clasificación de los tests que quedan (141 del agente)

| Archivo | Tests | Tipo | Qué protege |
|---|---|---|---|
| `test_auth_service.py` | 51 | Unitario sobre SQLite real | Reglas de registro, login, solicitudes, sesiones, límite y acciones de la TUI |
| `test_tui_security.py` | 21 | Interfaz (arnés de Textual) | Botones, QR, diálogos y efectos de la TUI de seguridad |
| `test_api_auth.py` | 19 | Integración HTTP | El contrato: códigos de estado, cuerpos y errores |
| `test_limite_service.py` | 10 | Unitario (función pura y configuración) | Recuento de fallos, fin del bloqueo y duración configurable |
| `test_server.py` | 7 | Integración (servidores reales) | TLS real, extremo a extremo y ciclo de vida de los servidores |
| `test_tui.py` | 6 | Interfaz | Navegación y banner de la TUI |
| `test_metrics_repository.py` | 6 | Unitario (`psutil` simulado) | Filtrado de particiones y temperatura |
| `test_pairing_service.py` | 6 | Unitario y lector real | URI del contrato y QR legible |
| `test_token_service.py` | 5 | Unitario | Formato y aleatoriedad del token, hash y caducidad |
| `test_password_service.py` | 3 | Unitario | Argon2 con sal y hash dañado |
| `test_tls_service.py` | 3 | Unitario | Permisos, no regenerar y huella |
| `test_database.py` | 2 | Unitario | Permisos 0600/0700 y claves foráneas |
| `test_sesion_repository.py` | 1 | Unitario | Revocar sesiones solo del usuario indicado |
| `test_metrics.py` | 1 | Integración | `GET /metrics` con datos reales |

No he medido la cobertura de código: necesitaría una herramienta nueva (`coverage`) que no se instaló sin permiso. La demostración por mutación la sustituye para los tests eliminados.

## Pendiente y fuera de alcance

- **Venv:** `activate` y algunos scripts siguen apuntando a la ruta antigua; recrear el venv lo arregla.
- **Aviso de `pytest-asyncio`:** pide fijar `asyncio_default_fixture_loop_scope` en `pyproject.toml`. Es una línea de configuración, pero no la he añadido porque no se pidió.
- **`CLAUDE.md` del repositorio:** dice «sin `schema.sql` todavía», y eso ya no es cierto. No es de mi alcance.
- **Vista de Base de datos de la TUI:** sigue sin implementar, como estaba.
- **PR:** no se ha abierto, como se pidió.
