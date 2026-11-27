# Contrato de la API: seguridad (fase 3)

**Estado: implementado en el agente y en la app** (18/11/2026). La app, con sus clientes reales por HTTPS con huella fijada y por iroh, se ha probado contra el agente real por HTTPS; falta probarla en un móvil físico y por iroh. Define lo que el agente y la app se prometen entre sí en la fase 3; el diseño de fondo (flujo de registro, Argon2, amenazas) está en `01-memoria-tecnica.md` §5, y las tablas en §6.2. Los puntos marcados como **[Decisión]** son propuestas a confirmar y los marcados como **[Abierto]** se deciden más adelante; se recogen al final.

## Emparejamiento y login son cosas distintas

- **Emparejamiento:** se hace en la TUI del PC (QR, huella del certificado, código de registro). Vincula la app con el agente.
- **Login:** se hace en la app (usuario y contraseña). Abre una sesión.
- Los 5 minutos de espera de la §«Un solo dispositivo» pertenecen **solo a la solicitud de login**, no al emparejamiento.

## 1. Transporte

- HTTP/JSON en UTF-8. El contrato (rutas, cuerpos, errores) es el mismo por USB/LAN y por iroh, pero el cifrado es distinto:
  - **USB o red local:** HTTPS con un certificado autofirmado del equipo, con la huella fijada por la app (§6).
  - **Por iroh:** sin TLS propio. La conexión de iroh ya va cifrada de extremo a extremo (QUIC con TLS 1.3) y autentica al agente por su clave pública, el identificador iroh. El túnel reenvía al puerto HTTP interno **`8444`**, que escucha **solo en `127.0.0.1`**, nunca en `0.0.0.0`.
  - El login es obligatorio en los dos casos.
- Puerto por defecto: `8443` (HTTPS, USB y red local). El puerto interno para iroh es el `8444` (HTTP, solo en `127.0.0.1`).
- Fechas en ISO 8601 con zona horaria (`2026-12-20T18:30:00+01:00`).
- Conexiones HTTPS: uvicorn cierra las conexiones paradas a los 5 s (`timeout_keep_alive=5`, su valor por defecto). El cliente de la app descarta las suyas a los 4 s (`App-movil/lib/data/http/pinned_http_client.dart`); si cambia el valor en el agente (`server.py`), hay que revisar el de la app.
- La app ignora los campos de las respuestas que no conoce.

## 2. Rutas

Públicas (sin token): `GET /estado`, `POST /registro`, `POST /login` y `GET /login/solicitud/{id}`. **Todas las demás, incluida `/metrics`, exigen sesión** y devuelven `401` sin ella.

### `GET /estado`

**Para qué sirve:** «¿en qué estado está el agente?». Es lo primero que consulta la app al conectarse, antes de tener sesión, y decide qué pantalla mostrar: registro si no hay cuenta, login si la hay.

```json
{ "api": 1, "configurado": true, "registro_abierto": false, "sesion_activa": true }
```

- `api`: versión del contrato (entero). Ver §7.
- `configurado`: ya existe una cuenta.
- `registro_abierto`: el agente acepta `POST /registro`. Solo es `true` entre que se pulsa la configuración inicial en la TUI y se crea la primera cuenta.
- `sesion_activa`: hay ahora mismo una sesión abierta (no revocada ni caducada). La app lo usa para avisar **antes del login** de que habrá que confirmar en la TUI (ver «Un solo dispositivo»). Es solo un booleano: no revela qué dispositivo ni qué usuario.

### `POST /registro`

**Para qué sirve:** crear la cuenta del agente la primera vez. Solo se usa una vez en la vida del agente, justo después de escanear el QR de configuración inicial. Solo funciona con el modo registro abierto y con el código de un solo uso.

```json
{ "codigo": "K7QX-M2PD-9WTR-4HNB", "usuario": "alex", "contrasena": "...", "dispositivo": "Pixel 8" }
```

- `dispositivo` es opcional (por defecto `"Móvil"`).
- El código se acepta sin guiones, en minúsculas y con `0`/`1` en lugar de `O`/`I`.
- La contraseña debe tener como mínimo 5 caracteres, un número y una mayúscula.

Respuesta `201`: igual que el login (devuelve ya una sesión).

```json
{ "token": "<token>", "usuario": "alex" }
```

Errores: `422 contrasena_debil` (con `"motivos": [...]`) y tres `403` distintos, para que la app pueda decir qué ha pasado. El agente los decide en este orden:

1. Si ya existe una cuenta: `registro_cerrado`.
2. Si el código enviado coincide con uno guardado: ya usado, `codigo_invalido`; caducado, `codigo_caducado`; vigente, el registro sigue.
3. Si no coincide con ninguno: si nunca se abrió el registro (no hay ningún código guardado), `registro_cerrado`; si hay códigos guardados (aunque sea uno solo, caducado), `codigo_invalido`.

| `error` | `mensaje` |
|---|---|
| `registro_cerrado` | El registro no está abierto |
| `codigo_caducado` | El código de registro ha caducado |
| `codigo_invalido` | El código de registro no es válido |

Un código caducado se conserva (solo su hash) hasta la siguiente «Configuración inicial» de la TUI, que borra los anteriores. Por eso el código de un registro ya reemplazado da `codigo_invalido`. La contraseña débil se comprueba después del código: un código caducado se detecta antes y no consume nada.

El agente guarda la contraseña con Argon2 y cierra el modo registro al crear la cuenta.

### `POST /login`

**Para qué sirve:** iniciar sesión con usuario y contraseña y obtener el token. Se usa cada vez que la app no tiene sesión válida: tras emparejar, al reinstalar la app o cuando la sesión caduca o se revoca.

```json
{ "usuario": "alex", "contrasena": "...", "dispositivo": "Pixel 8" }
```

Respuesta `200` (no hay otra sesión activa): se crea la sesión.

```json
{ "token": "<token>", "usuario": "alex" }
```

Respuesta `202` (las credenciales son correctas pero **ya hay una sesión activa** en otro dispositivo): no se crea ninguna sesión. El agente espera a que el usuario decida en la TUI del PC.

```json
{ "estado": "pendiente", "solicitud": "<id>", "sesion_activa_en": "Pixel 8", "caduca_en_s": 300 }
```

Las credenciales se comprueban **antes** de crear la solicitud: una contraseña incorrecta sigue dando `401` y cuenta como fallo. Una solicitud pendiente no cuenta como fallo. Solo hay una solicitud pendiente a la vez: un nuevo login correcto sustituye a la anterior.

Errores: `401 credenciales_invalidas`; `429 demasiados_intentos` con la cabecera `Retry-After` (segundos) y el cuerpo `{"error": "demasiados_intentos", "espera_s": 40}`.

### `GET /login/solicitud/{id}`

**Para qué sirve:** tras un `202` del login, la app pregunta con esta ruta (cada pocos segundos) qué ha decidido el usuario en la TUI. Es pública, pero el `id` es un valor aleatorio de 32 bytes que solo conoce quien hizo el login.

```json
{ "estado": "pendiente" }
{ "estado": "aprobada", "token": "<token>", "usuario": "alex" }
{ "estado": "rechazada" }
{ "estado": "caducada" }
```

- `aprobada`: el token se entrega **una sola vez**; después la solicitud se borra. Lo genera el agente cuando la app consulta, no la TUI al aprobar, para no guardarlo en SQLite.
- `caducada`: nadie decidió en 5 minutos. Hay que volver a iniciar sesión.
- Un `id` desconocido devuelve `404 solicitud_desconocida`.

### `POST /desemparejar`

**Para qué sirve:** que el usuario desempareje el móvil desde la app («Desemparejar» en Ajustes). El agente revoca la sesión y deja el equipo sin dispositivo emparejado (la TUI pasa a mostrar «Sin dispositivo emparejado»), y la app **olvida el equipo**: borra dirección, huella, identificador iroh y token, y vuelve a la pantalla inicial. Respuesta `204`. Es la forma fiable de desemparejar antes de desinstalar la app.

Diferencia con `POST /logout`: el logout cierra la sesión pero **mantiene el emparejamiento** (la app sigue sabiendo dónde está el agente y vuelve al login).

### `POST /logout`

**Para qué sirve:** cerrar sesión desde la app. Invalida el token de esa petición. Respuesta `204`.

### `GET /sesion`

**Para qué sirve:** al abrir la app, comprobar que el token guardado sigue siendo válido sin tener que pedir la contraseña. Si responde `401`, la app vuelve al login.

```json
{ "usuario": "alex", "dispositivo": "Pixel 8", "creada": "2026-12-20T18:30:00+01:00" }
```

### Lo que NO tiene ruta HTTP

Cambiar la contraseña y «Cerrar todas las sesiones» se hacen **solo desde la TUI del PC** (`01` §5.2). Desde el móvil no se puede ni cambiar la contraseña ni expulsar a otros dispositivos.

## 3. Sesión y token

- El cliente envía `Authorization: Bearer <token>` en cada petición protegida.
- Token opaco de 32 bytes aleatorios en base64url (43 caracteres). No es un JWT.
- El agente guarda solo su hash (SHA-256) en `sesion.hash_token`; el token en claro no se conserva.
- Revocable: se invalida con `POST /logout`, cerrando todas las sesiones desde la TUI o cambiando la contraseña.
- Caducidad: la sesión caduca **7 días después de iniciarla** (`sesion.caduca_en`), se use o no; el uso no la renueva. Pasado ese plazo el agente responde `401 sesion_caducada` y la app vuelve a la bienvenida. Un token desconocido o mal formado sigue dando `401 no_autenticado`.
- Historial: las filas de `sesion` no se borran. Cada sesión conserva su `id`, el hash de su token, el dispositivo, `creado_en`, `caduca_en`, `ultimo_acceso` y, si se cerró antes de tiempo, `revocada` y `motivo_revocacion`. Esa tabla es el historial de inicios de sesión; no se guarda el token en claro.
- Migración: al actualizar el agente, las sesiones que ya existían reciben `caduca_en = creado_en + 7 días`; las que lleven más de 7 días caducan en su siguiente uso y hay que iniciar sesión de nuevo.
- La app guarda el token en el almacenamiento cifrado de Android (Keystore) y lo borra al recibir un `401`.

## 4. Errores

Todo error lleva el mismo cuerpo:

```json
{ "error": "codigo_en_minusculas", "mensaje": "Texto legible", "...": "campos extra según el error" }
```

| Código HTTP | `error` | Cuándo | Qué hace la app |
|---|---|---|---|
| 401 | `no_autenticado` | Falta el token, es inválido o fue revocado | Borra el token y vuelve al login |
| 401 | `sesion_caducada` | La sesión superó sus 7 días (`caduca_en`) | Borra el token y vuelve a la bienvenida con «Tu sesión ha caducado. Inicia sesión de nuevo.» |
| 401 | `desemparejado` | El usuario pulsó «Desemparejar» en la TUI | Borra dirección, huella, identificador iroh y token, y vuelve a la pantalla inicial de emparejamiento |
| 401 | `credenciales_invalidas` | Usuario o contraseña incorrectos | Muestra el error en el login |
| 403 | `codigo_invalido`, `codigo_caducado`, `registro_cerrado` | Registro | Mensaje específico en el diálogo de registro |
| 404 | `solicitud_desconocida` | El `id` de la solicitud de login no existe | Muestra el mensaje del agente |
| 404, 405 | `no_encontrado`, `metodo_no_permitido` | Ruta o método que el agente no tiene | Muestra el mensaje del agente |
| 422 | `peticion_invalida`, `contrasena_debil` | Cuerpo mal formado o contraseña floja | Muestra los motivos |
| 429 | `demasiados_intentos` | Límite de intentos del login | Muestra la cuenta atrás con `espera_s` |
| 5xx | `error_interno` | Fallo del agente | Aviso genérico con reintento |

El agente reconvierte los `422` por defecto de FastAPI a este formato. Cualquier otro error HTTP que no esté en la tabla llega con `"error": "error_http"`.

## 5. Límite de intentos

- **Por cuenta, no por IP:** a través de iroh todas las conexiones llegan desde `127.0.0.1`, así que limitar por IP no serviría.
- Se permiten **5 intentos fallidos** seguidos: el 5.º todavía devuelve `401 credenciales_invalidas` y el **6.º ya está bloqueado**. Durante el bloqueo, cualquier `POST /login`, incluso con la contraseña correcta, devuelve `429` con el tiempo restante. Al terminar el bloqueo el contador vuelve a 0, y un login correcto también lo pone a 0.
- **Duración del bloqueo** (en `~/.config/sysmote/config.toml`, `01` §6.2):
  - **Producción:** 10 minutos (valor por defecto).
  - **Testeo:** 2 minutos.
- **Reinicio manual para pruebas:** botón en la TUI (Emparejamiento → Seguridad) que pone el contador a 0 y levanta el bloqueo. No hay ruta HTTP para esto.
- Cada intento se registra en `intento_login`.
- **[Abierto]** Si estos límites se mantienen después de la defensa del TFG.

## Un solo dispositivo

- **Una app se conecta a un solo agente** (la app guarda una única dirección, como en Ajustes hoy) y **un agente tiene una sola sesión activa a la vez**.
- **Una sesión activa no se sobrescribe sin que el usuario lo confirme en la TUI del PC.** Quien sabe la contraseña pero no está delante del PC no puede echar al dispositivo que ya está conectado.
- **Aviso en la app, antes del login:** si `GET /estado` devuelve `sesion_activa: true`, la app avisa antes de pedir usuario y contraseña: «Hay una sesión activa en otro dispositivo. Para iniciar una nueva tendrás que confirmarlo en la TUI del PC».
- **Flujo:**
  1. La app hace `POST /login` con credenciales correctas y recibe `202` con una solicitud pendiente.
  2. La app muestra «Hay una sesión activa en Pixel 8. Confirma en la TUI del PC que quieres cerrarla», con una cuenta atrás y un botón para cancelar, y consulta `GET /login/solicitud/{id}`.
  3. La TUI muestra el mensaje siguiente, como diálogo si está abierta o al abrirla si hay una solicitud pendiente:

     ```
     Hay una sesión activa en Pixel 8.
     ¿Quieres cerrarla e iniciar una nueva?

     [Sí, sobrescribir la sesión]   [No, mantener la sesión anterior]
     ```

     La TUI muestra también el nombre del dispositivo que lo solicita, para que el usuario vea quién intenta entrar.
  4. **Sí:** el agente revoca la sesión anterior (su siguiente petición recibe `401`), crea la nueva y la solicitud pasa a `aprobada`. **No:** la solicitud pasa a `rechazada` y la sesión anterior sigue.
  5. Si nadie decide en **5 minutos**, la solicitud pasa a `caducada`.
- **Móvil perdido:** «Cerrar todas las sesiones» en la TUI (§5.2 de `01`) elimina la sesión, y desde ese momento el login funciona sin confirmación.
- El nombre del dispositivo lo envía la app en el login y es solo informativo: no es de fiar para decidir permisos.
- La TUI y el agente se comunican solo por SQLite, no por HTTP: la TUI lee y escribe la tabla `solicitud_login` (`01` §6.2) y la consulta cada segundo mientras la subpestaña Seguridad está abierta.
- **[Abierto]** Si sobra tiempo, se revisará cómo adaptarlo a varios ordenadores en una misma app.

## Desemparejar

El emparejamiento se deshace de cinco maneras. Las dos primeras son inmediatas; las demás cubren los casos en que la app o el agente desaparecen sin avisar.

| # | Cuándo | Qué ocurre |
|---|---|---|
| 1 | El usuario pulsa **Desemparejar en la TUI** | El agente revoca la sesión y la marca como `desemparejado`. La siguiente petición de la app recibe `401 desemparejado` y la app olvida el equipo (dirección, huella, identificador iroh y token) y vuelve a la pantalla inicial. Si la app estaba sin conexión, se entera al volver a conectar. La sesión revocada se conserva en `sesion` y da ese aviso mientras no haya llegado su `caduca_en`; pasado ese plazo la app recibiría `sesion_caducada` y volvería a la bienvenida. |
| 2 | El usuario pulsa **Desemparejar en la app** (Ajustes) | `POST /desemparejar`: el agente revoca la sesión y la app olvida el equipo. Hacerlo **antes de desinstalar** la app es la forma fiable. |
| 3 | **Caducidad** | La sesión caduca 7 días después de iniciarla. La TUI deja de mostrar el dispositivo como emparejado. |
| 4 | **Última conexión** en la TUI | La TUI muestra cuándo se vio por última vez al dispositivo (`sesion.ultimo_acceso`), para que el usuario decida si desemparejarlo. |
| 5 | **Quitar el servicio** en la TUI (fase 4) | Si la app está conectada por WebSocket en ese momento, el agente le envía un evento de aviso. Solo funciona con la app conectada. |

Al **reinstalar el móvil** no hace falta nada de lo anterior: el login con una sesión activa exige confirmar en la TUI (§«Un solo dispositivo»).

**Limitación (no se puede resolver):** desinstalar la app o el agente **no desempareja automáticamente**. Android no avisa a una app cuando se desinstala ni le deja ejecutar código en ese momento, y la app no puede distinguir un agente desinstalado de un PC apagado o sin red. Por eso existen los cinco mecanismos anteriores.

La cuenta no se borra al desemparejar. Para volver a emparejar: QR sin código de registro (§6) y login.

## 6. Certificado y emparejamiento

### Huella

La **huella** es el SHA-256 del certificado en formato DER, en hexadecimal minúscula (64 caracteres). La TUI la muestra en ese formato.

### La app fija la huella (solo en red local)

Esto se aplica a la conexión por USB o red local. Por iroh, el identificador iroh cumple el papel de la huella: la app solo habla con el agente cuyo identificador tiene guardado.

- En el primer emparejamiento la app guarda la huella y a partir de entonces **solo confía en ese certificado**.
- En cada conexión compara la huella del certificado recibido con la guardada. Si no coincide, **rechaza la conexión**, no hay alternativa de «continuar de todos modos», y muestra el error `huella_distinta`: es un error de la app, no lo devuelve el agente, y el texto que se ve es «El certificado del agente no coincide con la huella guardada. Compárala con la de la TUI». Es el mismo error si cambia el certificado del agente (por ejemplo, tras regenerarlo).

### Contenido del QR

Un URI, para que quepa en un QR legible desde la terminal: **[Decisión 5]**

```
sysmote://emparejar?v=1&dir=192.168.1.20:8443&huella=<64 hex>&iroh=<id>&codigo=K7QX-M2PD-9WTR-4HNB
```

- `v`: versión del formato. `dir`: dirección del agente en la red local. `iroh`: identificador iroh; es lo que identifica al agente en la conexión remota. Va **siempre** en el QR, porque el agente arranca el túnel iroh junto con el resto.
- `codigo`: código de registro de **un solo uso**, 16 caracteres en base32 (unos 80 bits), con **caducidad de 10 minutos**. Solo aparece en el QR de configuración inicial.
- El QR para volver a emparejar un móvil (reinstalación) no lleva `codigo`: tras escanearlo, la app fija la huella y pide el login.

### Hasta que haya escáner de QR (fase 8)

El mismo contenido se introduce a mano: dirección, huella y, si procede, código. La huella se compara a ojo con la de la TUI (`01` §5.1).

## 7. Versiones y capacidades

- `GET /estado` devuelve `api`. La app admite una versión (la `1`). Si el agente devuelve una mayor, muestra «Actualiza la app»; si es menor, «Actualiza el agente».
- Añadir campos o rutas no cambia `api`. Cambiarlos o quitarlos, sí. **[Decisión 6]**
- `GET /capacidades` (protegida). **Para qué sirve:** que la app sepa qué funciones tiene realmente el agente. Lista los módulos implementados:

```json
{ "modulos": ["metricas"] }
```

La app usa la lista para elegir entre el repositorio real y el *placeholder* de cada función.

## 8. Fuera de esta fase

- WebSocket (terminal, eventos): el token viaja en la cabecera `Authorization` del *handshake*. Se detalla en la fase 5.
- Todo el CRUD (acciones, notas, reglas, notificaciones): sus rutas están en `01` §3 y se protegen con este mismo mecanismo.

## Decisiones y puntos abiertos

| # | Tipo | Qué | Estado |
|---|---|---|---|
| 1 | Cerrado | HTTPS con huella fijada en red local; por iroh, sin TLS propio (cifrado y autenticación de iroh). Ver `08`, entrada del 17/11/2026. | Confirmado. |
| 2 | Cerrado | Caducidad de la sesión: 7 días desde el inicio de sesión, sin renovarse con el uso. Antes eran 30 días sin uso; cambio del 19/11/2026 (ver `08`). | Confirmado. |
| 3 | Cerrado | `POST /registro` devuelve ya el token. | Confirmado. |
| 4 | Cerrado | Límite de intentos: 5 fallos y bloqueo de 10 min (2 min en testeo), con reinicio manual desde la TUI. «Se resetea a los 2 min» se entiende como un bloqueo de 2 min tras el 5.º fallo. | Confirmado. |
| 5 | Decisión | Formato del QR: URI `sysmote://emparejar?...`. | Propuesta. |
| 6 | Decisión | Versionado: entero `api` en `/estado`, sin prefijo `/v1`. | Propuesta. |
| 7 | Cerrado | Una sesión activa solo se sobrescribe si el usuario lo confirma en la TUI del PC; la app avisa antes del login. | Confirmado. |
| 11 | Cerrado | Desemparejamiento: TUI, botón en la app, caducidad de la sesión a los 7 días, última conexión en la TUI y aviso al quitar el servicio. Sin desemparejamiento automático al desinstalar (limitación de Android). | Confirmado. |
| 10 | Decisión | La solicitud de login pendiente caduca a los 5 minutos. | Propuesta. |
| 8 | **Abierto** | Si los límites de intentos sobreviven a la defensa del TFG. | Se decide después. |
| 9 | **Abierto** | Varios ordenadores desde una misma app. | Si sobra tiempo. |
