# Cómo está implementado

Qué hace cada pieza de código de la integración de iroh, implementada en la fase 2 (`../documentos-generales-del-proyecto/04-plan-de-fases.md`). Conceptos de iroh usados aquí: ver `01-que-es-y-como-funciona.md`.

## 1. Resumen

```
App                                                         Agente
  modo Local → HttpMetricsRepository, HttpAuthRepository ── HTTPS (huella fijada) ──► API (8443, red local)
  modo iroh  → IrohMetricsRepository, IrohAuthRepository
                 └─ IrohConnection (una, compartida) ── iroh ──► iroh_tunnel.py ── TCP ──► API (127.0.0.1:8444, HTTP interno)
```

El modo iroh no cambia la API: `iroh_tunnel.py` reenvía bytes sin mirarlos, y los repositorios iroh envían la misma petición HTTP que por la red local, solo que por un *stream* de iroh. Por iroh no hay TLS propio: iroh ya cifra y autentica al agente por su identificador (decisión del 17/11/2026 en `08`).

## 2. Agente: `agent/sysmote/iroh_tunnel.py`

Patrón *dumbpipe* (ver `01-que-es-y-como-funciona.md` §5). Piezas:

- **`load_or_create_secret_key(path)`**: lee la clave secreta de un archivo si existe, o la genera y la guarda, creándola ya con permisos `0o600`; un archivo corrupto da un `ValueError` con un mensaje claro. Así el identificador iroh del agente sobrevive a los reinicios (prueba 5 de `04-pruebas.md`). También la usa `pairing_service.py` para poner el identificador en el QR de emparejamiento.
- **`Limits`**: los tres límites del túnel y sus valores por defecto: 4 conexiones simultáneas, 8 *streams* por conexión y 60 s de inactividad por *stream*. Se pasan a `run(...)`; los tests usan valores pequeños.
- **`run(local_port, secret_key_path, limits)`**: punto de entrada. Crea el `Endpoint` con el preset `n0` (relés de producción) y el ALPN `b"sysmote/tunnel/0"`, imprime el identificador y entra en `_serve`.
- **`_serve(endpoint, local_port, limits)`**: el bucle de aceptación. Un fallo concreto (el *handshake* de una conexión, o cualquier excepción inesperada al esperar o al aceptar) se registra y **sigue escuchando**: no tumba el túnel entero (ver `03-problemas-y-soluciones.md` §2 y §13). Si ya hay `max_connections`, cierra la conexión **más antigua** para aceptar la nueva, en vez de rechazar la nueva: si el móvil se reconecta, su conexión muerta puede seguir contando hasta que el agente la detecte, y un límite que rechazara la nueva lo dejaría fuera.
- **`_handle_connection(connection, local_port, limits)`**: por cada conexión aceptada, acepta *streams* bidireccionales en bucle y lanza una tarea (`_forward_stream`) por cada uno. Si ya hay `max_streams` en marcha, rechaza el nuevo con `reset` (`_refuse_stream`). El límite se cuenta en el túnel porque el que ofrece iroh (`Connection.set_max_concurrent_bi_streams`) no se aplica si se llama después de aceptar la conexión (comprobado el 18/11/2026: el cliente abrió 4 *streams* con el límite en 2).
- **`_spawn(coro)`**: lanza las tareas en segundo plano guardando una referencia a cada una hasta que terminan; el bucle de eventos de `asyncio` solo guarda referencias débiles, y una tarea sin referencia puede desaparecer a medio ejecutarse.
- **`_forward_stream(stream, local_port, idle_timeout)`**: abre una conexión TCP a `127.0.0.1:local_port` (el agente FastAPI real) y reenvía bytes en los dos sentidos con `_pump_recv_to_writer` / `_pump_reader_to_send`. Si el agente local no responde, corta el *stream* con `reset()` en vez de dejarlo colgado. Además vigila la inactividad (`_wait_unless_idle`): si ninguna dirección mueve datos durante `idle_timeout`, cancela el reenvío y corta el *stream*. Cuenta las dos direcciones juntas, para no cortar un *stream* largo en el que solo uno de los lados está quieto.

**No se propaga el medio cierre (`EOF`) al socket local**: Uvicorn corta la respuesta si ve el lado de escritura cerrado antes de contestar. Una petición HTTP ya es autocontenida (cabeceras hasta `\r\n\r\n`), así que basta con dejar de escribir sin cerrar el socket. Detalle en `03-problemas-y-soluciones.md`.

### Quién lo arranca

`sysmote.server.Servidores` (`agent/sysmote/server.py`), al abrir la TUI: levanta el servidor HTTPS de la red local, el HTTP interno en `127.0.0.1:8444` y el túnel, que reenvía a ese puerto interno con la clave de `pairing_service.IROH_KEY_PATH`. El servicio systemd que lo mantenga en marcha sin la TUI llega en la fase 5.

## 3. App: `App-movil/lib/data/iroh/`

- **`IrohConnection`** (`iroh_connection.dart`): la única conexión iroh con el agente, compartida por métricas y autenticación (`main.dart` la crea una vez): crear una por repositorio duplicaría el `Endpoint` y las conexiones abiertas. También tiene `buildRawHttpRequest` y `parseRawHttpResponse`, que montan y separan las peticiones HTTP crudas que viajan por el *stream*.
  - Comprueba que el identificador sean 64 caracteres hexadecimales; si no, avisa con su propio mensaje y no conecta.
  - Un solo `Endpoint` para todas las conexiones y un solo intento de conexión a la vez: el intento nativo no se puede cancelar, así que si pasa de 5 s sigue vivo y las peticiones siguientes lo esperan en vez de lanzar otro. Si conecta tarde, se aprovecha; si mientras tanto cambió el identificador, se cierra al llegar.
  - Si el identificador de Ajustes cambia con una conexión abierta, la cierra y abre otra. Si una petición falla, cierra la conexión y la siguiente reconecta (ver `03-problemas-y-soluciones.md` §6).
  - La conexión real va tras una interfaz mínima (`IrohLink`: `exchange` y `close`) que los tests sustituyen por una falsa.
- **`IrohMetricsRepository`** (`iroh_metrics_repository.dart`): pide `/metrics` con el token de sesión por la conexión compartida y traduce la respuesta: un 401 de sesión lanza su excepción, y cualquier otro código o un cuerpo que no es JSON, `AgentUnavailableException`. Hereda de `AgentMetricsRepository` (`App-movil/lib/data/agent_metrics_repository.dart`) la parte común con `HttpMetricsRepository`: parsear el JSON e implementar `loadInfo()`, `loadHistory()` y `watch()` (un `Stream.periodic` de 1 s).
- **`IrohAuthRepository`** (`iroh_auth_repository.dart`): el login, el registro y la sesión por iroh sobre la misma conexión; se documenta con el resto de la autenticación en `doc/ui/`.

`watch()` nunca solapa peticiones: `asyncMap` pausa el `Stream.periodic` hasta que termina cada una (comprobado en el código fuente del SDK de Dart 3.13.4). Lo que sí podía solaparse eran los refrescos de `MetricsViewModel` (salir y volver rápido, «Reintentar»): ahora descarta los anteriores con un contador de generación, y el intento de conexión compartido cubre que dos de ellos coincidan al conectar.

| Timeout | Valor | Para qué |
|---|---|---|
| Conectar | 5 s | Si el identificador no es alcanzable, no se queda esperando para siempre |
| Petición | 3 s | Mismo tiempo que usa `HttpMetricsRepository`; si el agente se cuelga a medias, no se congela la gráfica |

### Selección del modo: `App-movil/lib/data/connection_mode_metrics_repository.dart`

`ConnectionModeMetricsRepository` envuelve un `HttpMetricsRepository` y un `IrohMetricsRepository` y delega en uno u otro según `settings.connectionMode`, leído en cada llamada (igual que `HttpMetricsRepository` lee la dirección del agente en cada petición): cambiar el modo en Ajustes se nota la próxima vez que la pantalla de Métricas vuelve a pedir datos, sin reiniciar la app. Se construye una vez en `App-movil/lib/main.dart` y se expone por `Provider`.

## 4. Requisitos de compilación (Android)

`iroh_flutter` compila su núcleo Rust para Android con `cargokit` + `cargo-ndk` en el primer build, y exige **NDK 29.0.14206865** (`App-movil/android/app/build.gradle.kts`, `ndkVersion`). Sin fijarlo, Gradle usa la NDK por defecto de Flutter (más antigua) y avisa del desajuste, aunque compila igual gracias a que son compatibles hacia atrás.
