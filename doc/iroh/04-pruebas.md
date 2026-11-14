# Pruebas de iroh

Qué cubre cada test automático de la integración de iroh, y la matriz de pruebas manuales de la fase 2 (`../documentos-generales-del-proyecto/04-plan-de-fases.md`). Se completa a medida que se hacen las pruebas.

Abreviaturas: `04` plan de fases, `02` necesidades tecnológicas, `07` decisiones.

---

## 0. Tests automáticos

### Agente: `agent/tests/test_iroh_tunnel.py`

Usan el binding de Python real de iroh (sin mocks): un `Endpoint` servidor y uno cliente conectados por loopback, sin relés ni red externa. La fixture `open_stream` monta los dos `Endpoint`s y devuelve un *stream* hacia el túnel.

| Test | Qué comprueba |
|---|---|
| `test_tunnel_forwards_a_real_metrics_request` | Con un servidor Uvicorn real sirviendo `sysmote.main:app`, una petición `GET /metrics` completa llega y vuelve bien a través del túnel (los dos sentidos del reenvío) |
| `test_tunnel_resets_the_stream_when_the_local_agent_is_down` | Si no hay nada escuchando en el puerto local, el *stream* se cierra (`reset`) enseguida en vez de colgarse hasta un *timeout* |

### App: `App-movil/test/connection_mode_metrics_repository_test.dart`

Comprueba que `ConnectionModeMetricsRepository` elige el repositorio correcto según `settings.connectionMode`, y que lo reevalúa en cada llamada (no solo al construirse) — con repositorios de prueba (*fakes*), sin red real.

### Pendiente de test automático

Las partes de `IrohMetricsRepository` que dependen de una conexión iroh real (*timeouts* de conexión y de petición, reconexión tras un fallo) solo están probadas a mano, no con un test automático. El fallo al aceptar una conexión entrante en el agente (bucle de `run()`) tampoco tiene test automático: requeriría forzar un fallo de *handshake* real.

**Intentado el 13/11/2026 y descartado por ahora:** sí es viable levantar un `Endpoint` iroh real dentro de `flutter test` en Linux (`dart run iroh_quic:setup` instala la librería nativa de escritorio; `Iroh.init()` y `Endpoint.bind()` funcionan). Pero `IrohMetricsRepository` construye la dirección del agente solo a partir del identificador (hex), igual que en producción, confiando en el descubrimiento de iroh (DNS/pkarr) para resolver direcciones — y esa resolución **falla dentro del proceso `flutter_tester`** en esta máquina, aunque la propia máquina sí tiene DNS e internet (confirmado con `curl`/`nslookup` desde la terminal). No se ha investigado la causa exacta; podría ser una limitación de cómo ese proceso resuelve DNS, no del código. Sin eso, un test así no es fiable: cualquier `connect()` falla por este motivo antes de probar nada del *timeout* o la reconexión que se quería cubrir.

**Lo que sí se encontró y arregló durante el intento** (sin relación con el problema de DNS, visto reproduciendo la reconexión con direcciones directas en vez de descubrimiento): `IrohMetricsRepository` creaba un `Endpoint` nuevo en cada reconexión sin cerrar el anterior (fuga de recursos nativos), y descartaba la conexión muerta sin cerrarla (`connection.close()`) — sin cerrarla, el `Endpoint` del cliente la seguía viendo como activa y una reconexión al mismo agente se quedaba colgada para siempre. Arreglado: un solo `Endpoint` se reutiliza para todas las conexiones, y `fetch()` cierra la conexión muerta antes de olvidarla. Ver `03-problemas-y-soluciones.md`.

---

## 1. Matriz de pruebas manuales de la PoC (`04` fase 2)

Mismos cinco casos que define `04`. El túnel iroh del agente
(`agent/sysmote/iroh_tunnel.py`, patrón dumbpipe) ya está integrado en la
app real: el selector Local/iroh de Ajustes elige entre `HttpMetricsRepository`
e `IrohMetricsRepository` (`App-movil/lib/data/connection_mode_metrics_repository.dart`).

| # | Caso | Estado | Resultado |
|---|---|---|---|
| 1 | Móvil y PC en la misma Wi-Fi: la conexión debe pasar a directa | **Hecha (12/11/2026)** | Éxito: empieza por el relé (RTT ~100-120 ms) y varias peticiones sí pasaron a directa hacia la IP del móvil en la Wi-Fi (RTT 4-8 ms); otras se quedaron en el relé, esperable porque cada petición abre un *stream* nuevo y la vía directa tarda unos segundos en confirmarse |
| 2 | Móvil con datos móviles y PC en casa: empieza por el relé y debe intentar pasar a directa | **Hecha (12/11/2026)** | Éxito: las métricas reales del PC llegaron al móvil con datos móviles, con el widget real de la app (gráficas en vivo, actualización cada 1 s) |
| 3 | Bloquear el UDP saliente en el cortafuegos del PC (red restrictiva simulada): todo el tráfico debe ir por el relé | **Hecha (12/11/2026)** | Éxito: con `sudo iptables -I OUTPUT -p udp -j REJECT` en el PC, las métricas siguieron llegando por iroh (modo Ajustes → iroh), confirmando que cae al relé (TCP/HTTPS) cuando no hay UDP saliente |
| 4 | Cambiar de Wi-Fi a datos móviles en mitad del uso: comprobar la reconexión | **Hecha (12/11/2026)** | Éxito: con la app ya conectada por Wi-Fi, se apagó el Wi-Fi del móvil (pasa a datos móviles) sin cerrar la app; el repositorio reconectó solo (blindaje del punto 5) y la conexión incluso pasó a directa hacia la IP pública nueva del móvil (RTT ~93-103 ms), sin que la pantalla se quedara congelada |
| 5 | Reiniciar el agente y el PC: el identificador iroh debe ser el mismo | **Parcial (12/11/2026)** | Éxito reiniciando solo el *proceso* del agente (mismo identificador, la clave secreta se conserva en disco); falta reiniciar el PC entero para dar la prueba por completa |

**Cómo se hizo la prueba 2:** agente real (FastAPI + túnel iroh) arrancado a
mano en el PC con `agent/scripts/iroh_poc.py`; identificador iroh copiado a
mano en una pantalla de prueba aislada de la app (antes de integrar iroh en
Ajustes; esa pantalla se borró el 13/11/2026 por redundante), instalada desde
un APK de *debug*.

**Cómo se hizo la prueba 3:** mismo agente ya arrancado; regla de `iptables`
añadida a mano en el PC y retirada al terminar la prueba
(`sudo iptables -D OUTPUT -p udp -j REJECT`).

**Cómo se hizo la prueba 1:** se añadió un diagnóstico temporal a
`iroh_tunnel.py` (`_watch_path`, usa `connection.paths()`) que imprime por
consola cada vez que la ruta seleccionada cambia entre relé y directa, con
el RTT y la dirección remota. Se quitó el 13/11/2026: era solo para esta
prueba y lanzaba un bucle por cada conexión. Para repetirla, basta con
volver a añadir un bucle que lea `connection.paths()` y mire `is_relay`
del camino con `is_selected`.

**Pendiente antes de dar por cerrada la prueba 5:** reiniciar también el PC,
no solo el proceso del agente.

**Red restrictiva real:** repetida la conexión desde una red restrictiva real;
probada y funciona (confirmado por el autor, 12/11/2026). No era la red del
centro: si esa red deja salir el tráfico hacia los relés sigue pendiente, y la
forma prevista de probarlo está en `07` §3.8.

---

## 2. Blindaje frente a errores

Fallos reales detectados al usar la PoC (detalle de causa y arreglo en
`03-problemas-y-soluciones.md`). El punto 2 llegó a darse de verdad: el
proceso del túnel se cayó en mitad de una prueba real por un
`iroh.IrohError` sin capturar al aceptar una conexión, justo el fallo que
describe esta fila (12/11/2026).

### En el agente (`agent/sysmote/iroh_tunnel.py`)

| # | Fallo | Qué debería pasar | Estado |
|---|---|---|---|
| 1 | Si el agente FastAPI no está arrancado (o se cae) y llega una conexión iroh, el reenvío de esa conexión lanzaba una excepción sin capturar dentro de una tarea en segundo plano: se perdía en silencio y el móvil se quedaba colgado sin aviso | La conexión iroh de esa petición se cierra con `reset` en cuanto falla la conexión al puerto local; el resto del túnel sigue funcionando | **Hecho.** Cubierto por `tests/test_iroh_tunnel.py::test_tunnel_resets_the_stream_when_the_local_agent_is_down` |
| 2 | Un fallo al aceptar una conexión entrante (`accept`/`connect`) tumbaba el túnel entero | El túnel sigue aceptando conexiones nuevas aunque una falle al aceptarse (el bucle de `run()` captura `iroh.IrohError` y sigue) | **Hecho**, revisado por lógica. Sin test automático (requeriría forzar un fallo de *handshake* real); se confirmó en la práctica el 12/11/2026 al caerse el túnel por este motivo antes del arreglo |

### En la app (`App-movil/lib/data/iroh/iroh_metrics_repository.dart`)

| # | Fallo | Qué debería pasar | Estado |
|---|---|---|---|
| 3 | Conectar no tenía límite de tiempo: si el identificador no era alcanzable, se quedaba esperando para siempre | A los 5 s, `AgentUnavailableException` en vez de quedarse colgado | **Hecho** (`_connectTimeout` en `_connect`). Sin test automático: requeriría una conexión iroh real en el entorno de test de Flutter |
| 4 | Cada petición de métricas tampoco tenía límite de tiempo: si el agente se colgaba a medias, la gráfica se quedaba congelada sin avisar | A los 3 s (mismo tiempo que `HttpMetricsRepository`) se muestra el error en vez de quedarse congelada | **Hecho** (`_fetchTimeout` en `fetch`). Hasta el 13/11/2026 el error solo se veía si la pantalla aún no tenía datos; con datos ya cargados la gráfica se congelaba sin avisar (ver `03-problemas-y-soluciones.md` §7). El *timeout* sigue sin test automático; el aviso en pantalla sí lo tiene (`metrics_widget_test.dart`) |
| 5 | Reintentar reintentaba sobre la misma conexión QUIC; si esa conexión ya había muerto (agente reiniciado, cambio de red), reintentaba para siempre sin poder recuperarse | Reintentar abre una conexión nueva desde cero si la anterior falló, y recupera las métricas si el agente vuelve a estar disponible | **Hecho** (si falla la petición, `fetch` cierra la conexión y pone `_connection` a `null`, así el siguiente intento reconecta). Confirmado a mano en la prueba 4 de la matriz (cambio de red en caliente). Sin test automático |
