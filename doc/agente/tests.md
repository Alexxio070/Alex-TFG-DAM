# Tests del agente

Documentación de los tests de [`agent/tests/`](../../agent/tests/): qué prueba cada archivo y para qué sirve. Hay 181 tests, todos automáticos; ninguno requiere pasos manuales.

```bash
cd agent && .venv/bin/pytest -q
```

**Aislamiento.** [`conftest.py`](../../agent/tests/conftest.py) redirige a una carpeta temporal, en todos los tests, la configuración (`config.toml`), la base de datos, el certificado TLS y la clave de iroh. Ningún test toca tu `~/.config/sysmote` ni tu `~/.local/share/sysmote`.

## Resumen

| Archivo | Tests | Qué prueba | Tipo |
|---|---|---|---|
| [`test_metrics.py`](../../agent/tests/test_metrics.py) | 1 | El endpoint `GET /metrics` completo (con el login saltado) | Integración |
| [`test_metrics_repository.py`](../../agent/tests/test_metrics_repository.py) | 6 | El repositorio de métricas, con `psutil` simulado | Unitario |
| [`test_tui.py`](../../agent/tests/test_tui.py) | 6 | La navegación de la TUI `sysmote`, sin terminal real | Interfaz (arnés de Textual) |
| [`test_iroh_tunnel.py`](../../agent/tests/test_iroh_tunnel.py) | 3 | El túnel iroh del agente (`sysmote/iroh_tunnel.py`) | Integración |
| [`test_iroh_secret_key.py`](../../agent/tests/test_iroh_secret_key.py) | 3 | La clave secreta del túnel, que fija el identificador iroh | Unitario |
| [`test_database.py`](../../agent/tests/test_database.py) | 4 | La conexión a SQLite: permisos, claves foráneas y tablas | Unitario |
| [`test_auth_repositories.py`](../../agent/tests/test_auth_repositories.py) | 15 | Repositorios de usuario, sesión, intento de login y solicitud de login | Unitario (SQLite en memoria) |
| [`test_codigo_registro_repository.py`](../../agent/tests/test_codigo_registro_repository.py) | 5 | Repositorio de códigos de registro | Unitario (SQLite en memoria) |
| [`test_password_service.py`](../../agent/tests/test_password_service.py) | 5 | Hashing de contraseñas con Argon2 | Unitario |
| [`test_token_service.py`](../../agent/tests/test_token_service.py) | 6 | Tokens de sesión y su caducidad | Unitario |
| [`test_tls_service.py`](../../agent/tests/test_tls_service.py) | 5 | Certificado TLS autofirmado y su huella | Unitario |
| [`test_limite_service.py`](../../agent/tests/test_limite_service.py) | 12 | Límite de intentos de login y su configuración | Unitario |
| [`test_pairing_service.py`](../../agent/tests/test_pairing_service.py) | 7 | URI de emparejamiento y QR en texto | Unitario + lector real |
| [`test_auth_service.py`](../../agent/tests/test_auth_service.py) | 52 | Registro, login, solicitud de login, sesiones y acciones de la TUI | Unitario (SQLite en memoria) |
| [`test_api_auth.py`](../../agent/tests/test_api_auth.py) | 19 | Las rutas de autenticación y la protección de `/metrics` | Integración |
| [`test_server.py`](../../agent/tests/test_server.py) | 10 | Los servidores reales (HTTPS, HTTP interno, iroh) y su ciclo de vida | Integración |
| [`test_tui_security.py`](../../agent/tests/test_tui_security.py) | 22 | Las subpestañas Seguridad y Dispositivo de la TUI | Interfaz (arnés de Textual) |

## `test_metrics.py`: endpoint `GET /metrics`

Usa el cliente de pruebas de FastAPI y lee datos reales de `psutil` de la máquina donde corre, sin simulaciones. Por eso depende del entorno: en un contenedor sin `/dev` reales no recorre ninguna partición, pero no falla. Desde la fase 3 `/metrics` exige sesión; este archivo sustituye la dependencia de sesión para seguir probando los datos, y la protección se prueba en `test_api_auth.py`.

| Test | Qué comprueba | Qué fallo detecta |
|---|---|---|
| `test_get_metrics_returns_real_data` | `cpu_percent` entre 0 y 100; `cpu_temp_c` es `None` o positivo; `ram_used_gb` mayor que 0 y `ram_total_gb` no menor que la usada; cada partición tiene `device` que empieza por `/dev/` y `total_gb` ≥ `used_gb` ≥ 0 | Que el endpoint deje de responder, devuelva campos mal formados o valores sin sentido (RAM negativa, usado mayor que total) |

## `test_metrics_repository.py`: repositorio de métricas

Pruebas unitarias con `psutil` sustituido mediante `monkeypatch`.

| Test | Qué comprueba | Qué fallo detecta |
|---|---|---|
| `test_read_cpu_temp_c_sin_sensores_devuelve_none` | Sin sensores de temperatura devuelve `None` | Un error o un valor inventado cuando el hardware no da temperatura |
| `test_read_cpu_temp_c_usa_el_primer_sensor_conocido` | Con un sensor `k10temp` simulado, devuelve su valor | Que deje de leer los sensores de CPU reales |
| `test_read_partitions_salta_montajes_sin_permiso` | Si `disk_usage` lanza `PermissionError`, descarta esa partición | Que el endpoint falle por un punto de montaje sin permisos |
| `test_read_partitions_descarta_snaps_y_montajes_loop` | Una partición squashfs de snap y un `/dev/loop` quedan fuera; solo pasa `/` | Que los paquetes snap reaparezcan como discos (bug ya corregido) |
| `test_read_partitions_descarta_duplicados_por_dispositivo` | El mismo dispositivo montado en dos puntos se queda solo con la ruta más corta | Que reaparezcan particiones duplicadas (típico de btrfs con subvolúmenes) |
| `test_read_partitions_usa_gb_decimales` | 1000³ bytes dan `total_gb=1.0` | Una regresión a 1024³ (bug de unidades ya corregido: la app espera GB decimales) |

## `test_tui.py`: TUI `sysmote`

Usa el arnés de pruebas sin terminal de Textual.

| Test | Qué comprueba | Qué fallo detecta |
|---|---|---|
| `test_mounts_with_empty_data_area` | Al arrancar, el área de datos está vacía y ningún botón principal aparece marcado | Que una sección se muestre sola al arrancar |
| `test_main_buttons_switch_section` | Cada uno de los 4 botones (Emparejamiento, Historial, Base de datos, Notas) cambia la sección | Botones que no navegan a su sección |
| `test_active_button_is_highlighted` | El botón de la sección activa tiene `variant="primary"` y el resto `default` | Que se pierda el resaltado del botón activo |
| `test_pairing_subtabs_switch` | Las 3 subpestañas de Emparejamiento (Dispositivo, Seguridad, Servicio) cambian el contenido y se resaltan | El mismo fallo en el segundo nivel de navegación |
| `test_banner_falls_back_to_plain_text_when_narrow` | Con terminal ancha se ve el banner ASCII; por debajo de `BANNER_MIN_WIDTH` pasa a texto plano (`BANNER_FALLBACK`) | Que el banner vuelva a romperse en terminales estrechas (bug ya corregido) |
| `test_buttons_stay_clickable_when_narrow` | En terminal estrecha se siguen pudiendo pulsar Emparejamiento y su subpestaña Seguridad | Que la barra de botones se desborde y quede inalcanzable (bug ya corregido) |

## `test_iroh_tunnel.py`: túnel iroh

Prueba de concepto del túnel: cliente y servidor iroh viven en el mismo proceso y se conectan por sus direcciones directas en loopback, sin red ni relés. Los tests dependen del paquete `iroh` instalado en el entorno. La fixture `open_stream` monta los dos `Endpoint` y devuelve un flujo hacia el túnel, de modo que cada test solo escribe lo que envía y lo que espera recibir.

| Test | Qué comprueba | Qué fallo detecta |
|---|---|---|
| `test_tunnel_resets_the_stream_when_the_local_agent_is_down` | Si nada escucha en el puerto local, el flujo se cierra enseguida con un reset, sin quedarse colgado hasta un timeout | Que el cliente espere sin fin cuando el agente real está caído |
| `test_tunnel_forwards_a_real_request` | Una petición HTTP real a `/estado` (ruta pública) a través del túnel contra el agente en marcha responde `HTTP/1.1 200 OK` con `"api"` | Que el túnel deje de reenviar datos entre el flujo QUIC y el puerto local (en los dos sentidos). Desde la fase 3 se usa `/estado` porque `/metrics` exige sesión |
| `test_tunnel_leaves_no_background_tasks_behind` | Tras 15 peticiones (10 con el agente en marcha y 5 con él caído) no queda ninguna tarea de reenvío viva | Que las tareas del túnel se acumulen con el uso |

## `test_iroh_secret_key.py`: clave secreta del túnel

La clave secreta determina el identificador iroh del agente. Los tests usan una carpeta temporal.

| Test | Qué comprueba | Qué fallo detecta |
|---|---|---|
| `test_creates_the_key_with_private_permissions` | La clave se crea con permisos `0600` | Que la clave quede legible por otros usuarios del PC |
| `test_reuses_the_stored_key_so_the_identifier_survives_restarts` | Cargarla dos veces da el mismo identificador | Que el identificador cambie al reiniciar el agente |
| `test_rejects_a_corrupt_key_file_with_a_clear_message` | Un archivo corrupto da un `ValueError` con «no es válida» | Que el agente caiga con un fallo interno de iroh sin decir qué archivo es el problema |

## Fase 3: seguridad

Los tests de esta fase se agrupan por comportamiento: una fila por cada grupo de casos relacionados.

### `test_database.py`: conexión a SQLite

| Grupo | Qué comprueba | Qué fallo detecta |
|---|---|---|
| Permisos | El archivo de la base de datos queda en `0600` y su carpeta en `0700` | Que los datos (hashes, sesiones) queden legibles por otros usuarios del PC |
| Claves foráneas | `PRAGMA foreign_keys` vale 1 en cada conexión | Que SQLite ignore las claves foráneas sin avisar |
| Esquema | Se crean las cinco tablas (`usuario`, `sesion`, `intento_login`, `solicitud_login`, `codigo_registro`) y abrir dos veces no falla | Un `schema.sql` roto o que no se pueda reabrir |

### `test_auth_repositories.py` y `test_codigo_registro_repository.py`: repositorios

Usan SQLite en memoria con el `schema.sql` real.

| Grupo | Qué comprueba | Qué fallo detecta |
|---|---|---|
| Usuarios | Crear, buscar por nombre, saber si existe alguno, cambiar el hash | Consultas SQL mal escritas |
| Sesiones | Crear activa, buscar por hash de token, ignorar las revocadas, guardar el motivo, revocar todas las de un usuario sin tocar las de otro, renovar el último acceso | Que una revocación afecte a otra cuenta o no se registre el motivo (necesario para `401 desemparejado`) |
| Intentos de login | Registrar, listar desde una fecha y borrar los de una cuenta | Que el límite de intentos cuente intentos antiguos o de otra cuenta |
| Solicitudes de login | Crear pendiente, obtener, cambiar de estado, borrar | Que una solicitud resuelta siga apareciendo como pendiente |
| Códigos de registro | Crear, buscar por hash, saber si hay uno vigente (no usado ni caducado), saber si hay alguno guardado (también caducados y usados), borrar todos | Que un código usado o caducado siga abriendo el registro, o que no se pueda reconocer uno caducado |

### `test_password_service.py` y `test_token_service.py`

| Grupo | Qué comprueba | Qué fallo detecta |
|---|---|---|
| Argon2 | El hash empieza por `$argon2` y no contiene la contraseña; dos hashes de la misma contraseña difieren; verificar acepta la correcta, rechaza la incorrecta y un hash corrupto devuelve `False` sin lanzar | Guardar contraseñas en claro o con una sal fija, o un 500 ante un hash dañado |
| Tokens | 43 caracteres en base64url, siempre distintos; el hash es SHA-256 en hexadecimal y no contiene el token | Tokens predecibles o guardados en claro |
| Caducidad | Una sesión usada hace 29 días vale; a los 31 días sin uso caduca | Que la caducidad de 30 días por inactividad se aplique mal |

### `test_tls_service.py`: certificado TLS

Usa una carpeta temporal.

| Grupo | Qué comprueba | Qué fallo detecta |
|---|---|---|
| Permisos | Clave y certificado en `0600`, carpeta en `0700` | Una clave privada legible por otros usuarios |
| Idempotencia | Si ya existen, no se regeneran | Que el certificado cambie en cada arranque y la app rechace la conexión por `huella_distinta` |
| Huella | Es SHA-256 en hexadecimal de 64 caracteres y coincide con la calculada de forma independiente sobre el DER | Una huella con otro formato que la app no sabría comparar |
| Par válido | La clave pública del certificado es la de la clave privada | Servir un certificado que no corresponde a su clave |

### `test_limite_service.py`: límite de intentos

| Grupo | Qué comprueba | Qué fallo detecta |
|---|---|---|
| Bloqueo | 4 fallos no bloquean; 5 seguidos sí, con el tiempo restante | Un umbral mal contado |
| Reinicio del contador | Un acierto, o el fin del bloqueo, ponen el contador a 0; tras un bloqueo hacen falta 5 fallos nuevos | Bloqueos eternos o que no se levanten |
| Duración | Cambiar la duración cambia la espera; `config.toml` la fija (`[seguridad] bloqueo_minutos`) y por defecto son 10 minutos | Ignorar la configuración del modo testeo |
| Cuentas y reinicio manual | El bloqueo de una cuenta no afecta a otra; reiniciar levanta el bloqueo y borra los intentos | Un reinicio de la TUI que no funcione |

### `test_pairing_service.py`: URI y QR

| Grupo | Qué comprueba | Qué fallo detecta |
|---|---|---|
| Dirección | La IP de la LAN con el puerto 8443 | Una dirección mal formada en el QR |
| URI | Sigue el formato del contrato; sin `codigo` es el de volver a emparejar; con `iroh` va antes del `codigo` | Que la app no pueda interpretar el QR |
| QR en texto | Solo usa `█ ▀ ▄` y espacio; reproduce exactamente la matriz de la librería `qrcode` | Un QR mal dibujado |
| Lector real | `zbarimg` (un lector de QR instalado en el sistema) decodifica el QR renderizado y obtiene el URI. Se omite si no está instalado | Un QR que parece correcto pero no se puede leer |

### `test_auth_service.py`: lógica de autenticación

Usa SQLite en memoria.

| Grupo | Qué comprueba | Qué fallo detecta |
|---|---|---|
| Estado | `configurado`, `registro_abierto` y `sesion_activa` en cada situación | Que la app muestre la pantalla equivocada |
| Contraseña débil | Mínimo 5 caracteres, un número y una mayúscula, con un motivo por cada regla incumplida | Aceptar contraseñas que no cumplen |
| Registro | Crea la cuenta con Argon2 y devuelve una sesión; `registro_cerrado` con cuenta o si nunca se abrió el registro; `codigo_caducado` si el código enviado es el que caducó; `codigo_invalido` si no coincide con ninguno guardado (también cuando solo hay uno caducado), si ya se usó o si pertenece a un registro anterior; una contraseña débil no gasta el código | Registrar sin código, gastar el código sin crear cuenta o confundir al usuario con el error equivocado |
| Login | Abre sesión; credenciales incorrectas o usuario inexistente dan `credenciales_invalidas` | Mensajes que revelen qué cuentas existen |
| Solicitud de login | Con sesión activa no se abre sesión y se crea una solicitud pendiente (5 minutos); una nueva solicitud sustituye a la anterior; aprobar entrega el token una sola vez y revoca la sesión anterior; rechazar la mantiene; sin respuesta caduca | Que un login correcto eche a otro dispositivo sin confirmar en la TUI |
| Sesión | Una sesión sin uso 30 días caduca y deja de contar como activa; autenticar renueva el último acceso; logout revoca; desemparejar da `401 desemparejado` | Errores de sesión equivocados en la app |
| Límite de intentos | Cinco fallos bloquean incluso con la contraseña correcta; el quinto aún da `credenciales_invalidas`; un acierto reinicia; un usuario inexistente también se bloquea; cada intento queda registrado con su origen; reiniciar permite entrar | Un bloqueo mal aplicado o sin registro |
| Acciones de la TUI | Abrir el registro genera un código de 16 caracteres base32 con 10 minutos, solo se guarda su hash e invalida el anterior; el código se acepta sin guiones, en minúsculas y con `0`/`1` por `O`/`I`; cambiar la contraseña actualiza el hash y cierra las sesiones; cerrar todas las sesiones; consultar la solicitud pendiente ignora las caducadas; desemparejar desde la TUI | Que la TUI y la API no se entiendan a través de SQLite |

### `test_api_auth.py`: rutas de autenticación

Usa el cliente de pruebas de FastAPI con una base de datos en memoria.

| Grupo | Qué comprueba | Qué fallo detecta |
|---|---|---|
| Protección | `/metrics`, `/sesion`, `/capacidades`, `/logout` y `/desemparejar` sin token dan `401 no_autenticado`; un esquema distinto de `Bearer` también | Una ruta que quede abierta |
| Rutas públicas | `/estado` responde sin token | Que la app no pueda ni consultar el estado |
| Registro y login | `201` con token; `422 contrasena_debil` con motivos; `403 codigo_invalido`, `codigo_caducado` y `registro_cerrado`; `401 credenciales_invalidas`; `200` o `202` en el login según haya sesión activa | Códigos HTTP que la app no espera |
| Solicitud de login | Flujo completo: `202`, consulta pendiente, aprobación desde la TUI, token entregado una vez y `404` después | Cualquier paso roto del flujo de una sola sesión |
| Sesión | `/sesion` devuelve usuario, dispositivo y fecha con zona horaria; logout da `204` y el token deja de valer; desemparejar da `204` y luego `401 desemparejado` | Que la app no se entere de que fue desemparejada |
| Errores | Los `422` de FastAPI y los `404` usan el formato `{"error","mensaje"}`; `/docs` y `/openapi.json` están desactivados | Errores sin el formato del contrato o documentación abierta sin login |
| Límite de intentos | Cinco fallos dan `429` con `Retry-After` y `espera_s`; el origen del intento se guarda | Un `429` sin el tiempo de espera |

### `test_server.py`: servidores reales

Arranca los servidores de `sysmote/server.py` en puertos libres, sin mocks. El de iroh se prueba solo hasta donde se puede sin una segunda máquina.

| Grupo | Qué comprueba | Qué fallo detecta |
|---|---|---|
| Arranque | Los dos puertos arrancan y el estado los da por activos | Un servidor que no llega a escuchar |
| HTTPS | Responde, y el certificado que sirve tiene la huella de `tls_service`; no habla HTTP plano | Que la app compare una huella distinta de la mostrada en la TUI |
| Puerto interno | Responde en HTTP plano | Que el túnel iroh no tenga a dónde reenviar |
| Login | `/metrics` da `401` en los dos puertos | Un puerto sin login |
| Extremo a extremo | Registro con el código, `/metrics` con el token por los dos puertos, login con solicitud pendiente y `429` al sexto intento fallido | Que el conjunto no funcione aunque cada pieza pase sola |
| Ciclo de vida | Detener libera los puertos; salir de la TUI con `q` los para; un puerto ocupado se notifica sin tumbar el otro; con iroh el estado lo incluye y detener no se cuelga | Un agente que quede vivo tras cerrar la TUI |

### `test_tui_security.py`: subpestañas Seguridad y Dispositivo

Usa el arnés de Textual con una base de datos real en memoria.

| Grupo | Qué comprueba | Qué fallo detecta |
|---|---|---|
| Botones | Sin cuenta solo está activa «Configuración inicial»; con cuenta ocurre lo contrario | Acciones disponibles en el momento equivocado |
| Configuración inicial | Genera el certificado, muestra la huella y el código de registro, y abre el registro | Que el emparejamiento no pueda empezar |
| QR | Se muestra el QR con el código y el mismo URI debajo; con cuenta es el de volver a emparejar, sin código; incluye el identificador iroh | Un QR sin los datos del contrato |
| Dispositivo | Muestra la sesión activa y se actualiza solo al hacer login la app; Desemparejar la cierra | Datos de dispositivo obsoletos |
| Acciones | Cerrar todas las sesiones; reiniciar intentos levanta el bloqueo | Botones que no hacen su efecto |
| Cambiar contraseña | Contraseña débil muestra los motivos; confirmación distinta da error; correcto cierra las sesiones; cancelar no cambia nada | Cambios de contraseña sin validar |
| Solicitud de login | Abre un diálogo con los dos dispositivos, no se repite mientras está abierto y no aparece con la pestaña cerrada; Sí cierra la sesión anterior y No la mantiene | Echar a un dispositivo sin confirmación |
| Servidores | La TUI los arranca y los detiene; Seguridad muestra el identificador iroh y el estado de cada uno; un error se avisa con una notificación | Un servidor caído sin que se vea |
