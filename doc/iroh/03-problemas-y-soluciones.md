# Problemas encontrados y cómo se resolvieron

Fallos reales encontrados implementando y probando iroh en la fase 2, por orden cronológico. Dos de ellos (el 4 y el 5) no son de iroh en sí, pero se descubrieron probándolo y se arreglaron en la misma rama.

## 1. El agente cortaba la respuesta al medio cerrar el socket local

**Síntoma:** al reenviar una petición `GET /metrics` a través del túnel, Uvicorn no llegaba a responder.

**Causa:** `_pump_recv_to_writer` (agente) cerraba el lado de escritura del socket local (`writer.write_eof()`) en cuanto el *stream* de iroh terminaba de enviar datos, para avisar de "fin de petición". Pero el servidor ASGI de Uvicorn, al ver el lado de escritura del cliente medio cerrado, trataba la conexión como abortada y no llegaba a enviar su respuesta.

**Solución:** no propagar el `EOF` al socket local. Una petición HTTP ya es autocontenida (las cabeceras terminan en `\r\n\r\n`), así que el servidor no necesita ver el cierre para saber que la petición terminó — basta con dejar de escribir. El cierre real del socket se hace al final, cuando ambos lados del reenvío han terminado (`agent/sysmote/iroh_tunnel.py`, `_forward_stream`).

## 2. Un fallo al aceptar una conexión tumbaba el túnel entero

**Síntoma:** el proceso del túnel se cayó solo, en mitad de una prueba real, con una excepción `iroh.IrohError` sin capturar.

**Causa:** el bucle principal de `run()` llamaba a `incoming.accept()` / `accepting.connect()` sin capturar errores. Un fallo en el *handshake* de **una sola** conexión entrante (por ejemplo, un cliente que se desconecta a mitad del saludo) propagaba la excepción hasta `run()`, que entonces ejecutaba su `finally` y cerraba el `Endpoint` — matando el túnel para todo el mundo, no solo para esa conexión.

**Solución:** envolver el aceptado de cada conexión, dentro del bucle de `run()`, en un `try/except iroh.IrohError` que registra el fallo y **sigue** escuchando. Un fallo de una conexión ya no afecta a las demás.

## 3. Una conexión al agente local caído se quedaba colgada

**Síntoma (hipotético, cubierto antes de que pasara de verdad):** si el agente FastAPI no está arrancado y llega una petición por iroh, el intento de `asyncio.open_connection("127.0.0.1", local_port)` lanza `OSError`. Sin capturarlo, esa excepción se perdía dentro de una tarea en segundo plano (`asyncio.create_task`) y el *stream* de iroh se quedaba sin respuesta, obligando al cliente a esperar hasta un *timeout* largo.

**Solución:** capturar el `OSError` en `_forward_stream` y cerrar el *stream* con `stream.send().reset(1)` — el cliente ve el corte al momento, en vez de colgarse.

## 4. `shared_preferences` no guardaba nada en un dispositivo real

**No es un fallo de iroh**, pero se descubrió probando a guardar el identificador de iroh en Ajustes: tras cerrar la app del todo y reabrirla, no se recordaba nada — ni el identificador, ni la dirección del agente, ni ningún otro ajuste.

**Síntoma:** en el emulador y en los tests (que usan `SharedPreferences.setMockInitialValues`) todo funcionaba. En un móvil real, cada llamada a `shared_preferences` (leer y guardar) lanzaba `PlatformException` con `java.lang.NoSuchMethodError: no non-static method ...SharedPreferencesApiRegistrar.getAll(...)` (visto con `adb logcat`).

**Investigación:** se descartaron, por este orden: que fuera un problema de tiempos (arreglado de todas formas, ver más abajo); que fuera MIUI "congelando" la app (datos del almacenamiento del sistema mostraban que sí se escribía algo); y que fuera caché de compilación (persistía tras `flutter clean`, tras borrar `android/.gradle`, y tras subir `shared_preferences_android` a su última versión — cambiaba de método que fallaba, de `getAll` a `getInstance`, pero seguía fallando).

**Causa:** desajuste real entre el código Dart generado por `shared_preferences: 2.5.6` y la clase Kotlin de `shared_preferences_android` en las versiones 2.5.0/2.5.5 (ambas probadas). No se ha confirmado si está reportado oficialmente.

**Solución:** fijar con `dependency_overrides` en `App-movil/pubspec.yaml` una pareja de versiones anterior y estable: `shared_preferences: 2.3.3` y `shared_preferences_android: 2.3.4`. Probado en un móvil real (Xiaomi/MIUI): el ajuste sobrevive a cerrar la app del todo.

**De paso, otro refuerzo relacionado:** `SettingsViewModel._update()` guardaba sin esperar (`_repository.save(...)` sin `await`) — si la app se cerraba justo después de pulsar "Guardar", la escritura a disco podía no haber terminado. Se cambió a `await`, y `ConnectionFields` ahora muestra un "Guardado" en verde cuando termina de verdad.

## 5. El punto de montaje largo se salía de la tarjeta de disco

**No es un fallo de iroh**, mismo motivo que el anterior: se vio al probar la app en un móvil real con la pantalla de Métricas a través de iroh.

**Síntoma:** con un punto de montaje largo (por ejemplo `/home/juegos-y-apss`), el texto se salía de la tarjeta y de la pantalla en vez de recortarse.

**Causa:** en `App-movil/lib/features/metrics/widgets/partition_menu.dart` y `disk_card.dart`, las filas que muestran el punto de montaje no limitaban su ancho (`Row` con hijos sin `Expanded`/`Flexible`): el texto se dibujaba a su tamaño natural, sin importar si cabía.

**Solución:** envolver el texto en `Flexible`/`Expanded` con `overflow: TextOverflow.ellipsis` en los tres sitios afectados: el chip de la cabecera, la lista del menú de particiones y la fila "Usado/Libre". De paso se encontró y arregló el mismo problema en las tarjetas de CPU, Temperatura y RAM (`metric_card.dart`), con la misma solución.

Reproducido con un test de Flutter en una pantalla de 360 px de ancho (la del móvil real) antes y después del arreglo — ver `04-pruebas.md`.

## 6. Reconectar se quedaba colgado para siempre tras un fallo

**Encontrado el 13/11/2026** intentando escribir un test automático para la reconexión (punto 5 del blindaje), reproduciéndola con direcciones directas en vez de descubrimiento por DNS, para aislarla del problema del punto 0 de `04-pruebas.md`.

**Síntoma:** tras un fallo (conexión muerta, agente reiniciado), `IrohMetricsRepository` reintentaba conectar al mismo agente y se quedaba esperando para siempre — ni éxito ni el error que se esperaba (`AgentUnavailableException`).

**Causa:** dos cosas, ambas en el código de conexión de `IrohMetricsRepository`:
1. Cada reconexión creaba un `Endpoint` **nuevo** (`Endpoint.bind(...)`) sin cerrar el anterior — una fuga de recursos nativos que se acumulaba con cada fallo.
2. Al descartar la conexión muerta, solo se ponía `_connection = null`, sin llamar a `connection.close()`. Sin ese cierre explícito, el `Endpoint` del cliente seguía considerando esa conexión activa por su lado, y una conexión nueva al mismo agente no llegaba nunca a completarse — se quedaba esperando indefinidamente.

**Solución:** un único `Endpoint` se crea una vez y se reutiliza para todas las conexiones (`_connect()`); y `fetch()` cierra la conexión muerta (`connection.close()`) antes de olvidarla.

**Simplificado después (13/11/2026):** en el primer arreglo se añadió también un guardia para peticiones simultáneas, pensando que `watch()` podía solaparlas si una tardaba más de 1 s. No es así: `asyncMap` pausa el `Stream.periodic` hasta que termina cada petición (comprobado en el código fuente del SDK de Dart 3.13.4), así que el guardia sobraba y se quitó.

**Por qué no se vio en las pruebas manuales:** la prueba 4 de la matriz (cambio de red en caliente) sí reconectó bien en el móvil real — probablemente porque, al cambiar de red, iroh detecta el cambio y cierra la conexión vieja por su cuenta en algún punto del proceso, sin que la app tuviera que descartarla explícitamente del mismo modo que en el experimento aislado. No se ha confirmado el motivo exacto.

## 7. Con datos ya cargados, perder la conexión no se avisaba

**Encontrado el 13/11/2026** en la auditoría del código, leyéndolo; no se llegó a ver en el móvil.

**Síntoma:** si el agente dejaba de responder con la pantalla de Métricas ya cargada, las gráficas se quedaban congeladas con los últimos valores y sin ningún aviso. La prueba 4 de la matriz no lo destapó porque la reconexión fue casi inmediata.

**Causa:** `MetricsViewModel` sí guardaba el error, pero `metrics_view.dart` solo lo mostraba si todavía no había datos (`!metrics.ready`). Además, la pantalla se quedaba en blanco mientras cargaba (sin indicador) y para siempre si el agente no devolvía ninguna partición (desaparecían también CPU, temperatura y RAM).

**Solución:** la pantalla muestra:
- un indicador «Conectando con el agente…» mientras carga;
- un aviso «Conexión perdida. Reintentando…» encima de los últimos datos mientras haya error, que desaparece solo cuando vuelve a llegar una muestra (el repositorio sigue pidiendo una cada segundo);
- una tarjeta «El agente no ha encontrado ninguna partición» en lugar de la de disco, sin ocultar el resto.

Cubierto por tests en `App-movil/test/metrics_widget_test.dart`.
