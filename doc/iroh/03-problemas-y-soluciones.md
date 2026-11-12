# Problemas encontrados y cómo se resolvieron

Fallos reales encontrados implementando y probando iroh en la fase 2, por orden cronológico. Dos de ellos (los dos últimos) no son de iroh en sí, pero se descubrieron probándolo y se arreglaron en la misma rama.

## 1. El agente cortaba la respuesta al medio cerrar el socket local

**Síntoma:** al reenviar una petición `GET /metrics` a través del túnel, Uvicorn no llegaba a responder.

**Causa:** `_pump_recv_to_writer` (agente) cerraba el lado de escritura del socket local (`writer.write_eof()`) en cuanto el *stream* de iroh terminaba de enviar datos, para avisar de "fin de petición". Pero el servidor ASGI de Uvicorn, al ver el lado de escritura del cliente medio cerrado, trataba la conexión como abortada y no llegaba a enviar su respuesta.

**Solución:** no propagar el `EOF` al socket local. Una petición HTTP ya es autocontenida (las cabeceras terminan en `\r\n\r\n`), así que el servidor no necesita ver el cierre para saber que la petición terminó — basta con dejar de escribir. El cierre real del socket se hace al final, cuando ambos lados del reenvío han terminado (`agent/sysmote/iroh_tunnel.py`, `_forward_stream`).

## 2. Un fallo al aceptar una conexión tumbaba el túnel entero

**Síntoma:** el proceso del túnel se cayó solo, en mitad de una prueba real, con una excepción `iroh.IrohError` sin capturar.

**Causa:** el bucle principal de `run()` llamaba a `incoming.accept()` / `accepting.connect()` sin capturar errores. Un fallo en el *handshake* de **una sola** conexión entrante (por ejemplo, un cliente que se desconecta a mitad del saludo) propagaba la excepción hasta `run()`, que entonces ejecutaba su `finally` y cerraba el `Endpoint` — matando el túnel para todo el mundo, no solo para esa conexión.

**Solución:** aislar el aceptado de cada conexión en su propia función (`_accept_one`), con un `try/except iroh.IrohError` que registra el fallo y **sigue** en el bucle de aceptación. Un fallo de una conexión ya no afecta a las demás.

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
