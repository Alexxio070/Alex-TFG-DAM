# Cómo está implementado

Qué hace cada pieza de código de la integración de iroh, implementada en la fase 2 (`../documentos-generales-del-proyecto/04-plan-de-fases.md`). Conceptos de iroh usados aquí: ver `01-que-es-y-como-funciona.md`.

## 1. Resumen

```
App (ConnectionModeMetricsRepository)                    Agente
  ├─ modo Local  → HttpMetricsRepository ──── HTTP ───────► FastAPI (127.0.0.1:8443)
  └─ modo iroh   → IrohMetricsRepository ──── iroh ───────► iroh_tunnel.py ──TCP── FastAPI (127.0.0.1:8443)
```

El modo iroh no cambia nada de la API del agente: `iroh_tunnel.py` reenvía bytes sin mirarlos, y `IrohMetricsRepository` construye la misma petición HTTP que `HttpMetricsRepository`, solo que enviada por un *stream* de iroh en vez de un socket TCP.

## 2. Agente: `agent/sysmote/iroh_tunnel.py`

Patrón *dumbpipe* (ver `01-que-es-y-como-funciona.md` §5). Piezas:

- **`_load_or_create_secret_key(path)`**: lee la clave secreta de un archivo si existe, o la genera y la guarda (permisos `0o600`). Así el identificador iroh del agente sobrevive a los reinicios (prueba 5 de `04-pruebas.md`).
- **`run(local_port, secret_key_path)`**: punto de entrada. Crea el `Endpoint` con el preset `n0` (relés de producción) y el ALPN `b"sysmote/tunnel/0"`, imprime el identificador y entra en el bucle de aceptación. Si falla el *handshake* de una conexión concreta, lo registra y **sigue escuchando** — no tumba el túnel entero (ver `03-problemas-y-soluciones.md`).
- **`_handle_connection(connection, local_port)`**: por cada conexión aceptada, acepta *streams* bidireccionales en bucle y lanza una tarea (`_forward_stream`) por cada uno.
- **`_spawn(coro)`**: lanza las tareas en segundo plano guardando una referencia a cada una hasta que terminan; el bucle de eventos de `asyncio` solo guarda referencias débiles, y una tarea sin referencia puede desaparecer a medio ejecutarse.
- **`_forward_stream(stream, local_port)`**: abre una conexión TCP a `127.0.0.1:local_port` (el agente FastAPI real) y reenvía bytes en los dos sentidos con `_pump_recv_to_writer` / `_pump_reader_to_send`. Si el agente local no responde, corta el *stream* con `reset()` en vez de dejarlo colgado.

**No se propaga el medio cierre (`EOF`) al socket local**: Uvicorn corta la respuesta si ve el lado de escritura cerrado antes de contestar. Una petición HTTP ya es autocontenida (cabeceras hasta `\r\n\r\n`), así que basta con dejar de escribir sin cerrar el socket. Detalle en `03-problemas-y-soluciones.md`.

### Arranque manual (prueba de concepto)

`agent/scripts/iroh_poc.py` arranca en el mismo proceso el servidor Uvicorn real y `iroh_tunnel.run(...)`, e imprime el identificador. Es solo para probar a mano: el arranque automático del túnel (junto a `sysmote serve`) queda para la fase 5, como ya decide `04-plan-de-fases.md`.

## 3. App: `App-movil/lib/data/iroh/iroh_metrics_repository.dart`

`HttpMetricsRepository` (`App-movil/lib/data/http/`) e `IrohMetricsRepository` heredan de `AgentMetricsRepository` (`App-movil/lib/data/agent_metrics_repository.dart`), que tiene la parte común: parsear el JSON de `/metrics` (`cpu_percent`, `cpu_temp_c`, `ram_used_gb`, `ram_total_gb`, `partitions`) e implementar `loadInfo()`, `loadHistory()` y `watch()` (un `Stream.periodic` de 1 segundo). Cada uno solo implementa `fetch()`: cómo traer el JSON. Así el resto de la app (`MetricsViewModel`, `MetricsView`, las gráficas) no sabe por qué vía llegan los datos.

En `IrohMetricsRepository`:

- **`_connect()`**: si ya hay una conexión abierta, la reutiliza. Si no, crea el `Endpoint` la primera vez (`Iroh.init()` + `Endpoint.bind(alpns: [...])`) y lo reutiliza después, parsea el identificador (texto hex) con `PublicKey.fromHex` y conecta con `endpoint.connect(addr, alpn)`.
- **`_exchange(connection)`**: abre un *stream* bidireccional (`connection.openBi()`), escribe una petición `GET /metrics HTTP/1.1` cruda y lee la respuesta hasta el final (`readToEnd`).
- **`fetch()`**: junta las dos funciones anteriores, con *timeouts* (ver tabla abajo). Si la petición falla, cierra la conexión y la olvida, para que el siguiente intento abra una nueva — detalle en `03-problemas-y-soluciones.md`.

`watch()` nunca solapa peticiones: `asyncMap` pausa el `Stream.periodic` hasta que termina cada una (comprobado en el código fuente del SDK de Dart 3.13.4), así que no hace falta proteger la conexión frente a peticiones simultáneas.

| Timeout | Valor | Para qué |
|---|---|---|
| Conectar (`_connect`) | 5 s | Si el identificador no es alcanzable, no se queda esperando para siempre |
| Petición (`_exchange`) | 3 s | Mismo tiempo que usa `HttpMetricsRepository`; si el agente se cuelga a medias, no se congela la gráfica |

### Selección del modo: `App-movil/lib/data/connection_mode_metrics_repository.dart`

`ConnectionModeMetricsRepository` envuelve un `HttpMetricsRepository` y un `IrohMetricsRepository` y delega en uno u otro según `settings.connectionMode`, leído en cada llamada (igual que `HttpMetricsRepository` lee la dirección del agente en cada petición): cambiar el modo en Ajustes se nota la próxima vez que la pantalla de Métricas vuelve a pedir datos, sin reiniciar la app. Se construye una vez en `App-movil/lib/main.dart` y se expone por `Provider`.

## 4. Requisitos de compilación (Android)

`iroh_flutter` compila su núcleo Rust para Android con `cargokit` + `cargo-ndk` en el primer build, y exige **NDK 29.0.14206865** (`App-movil/android/app/build.gradle.kts`, `ndkVersion`). Sin fijarlo, Gradle usa la NDK por defecto de Flutter (más antigua) y avisa del desajuste, aunque compila igual gracias a que son compatibles hacia atrás.
