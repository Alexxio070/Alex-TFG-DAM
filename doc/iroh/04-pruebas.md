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
| `test_tunnel_leaves_no_background_tasks_behind` | Tras 15 peticiones (10 con el agente en marcha y 5 con él caído) no queda ninguna tarea de reenvío viva: no se acumulan |

### Agente: `agent/tests/test_iroh_secret_key.py`

| Test | Qué comprueba |
|---|---|
| `test_creates_the_key_with_private_permissions` | La clave secreta se crea con permisos `0600` |
| `test_reuses_the_stored_key_so_the_identifier_survives_restarts` | Cargarla dos veces da el mismo identificador (la base de la prueba 5) |
| `test_rejects_a_corrupt_key_file_with_a_clear_message` | Un archivo de clave corrupto da un `ValueError` con un mensaje claro en vez de un fallo interno de iroh |

### App: `App-movil/test/connection_mode_metrics_repository_test.dart`

Comprueba que `ConnectionModeMetricsRepository` elige el repositorio correcto según `settings.connectionMode`, y que lo reevalúa en cada llamada (no solo al construirse) — con repositorios de prueba (*fakes*), sin red real.

### App: `App-movil/test/iroh_metrics_repository_test.dart`

La conexión se aparta tras una interfaz mínima (`IrohLink`) que estos tests sustituyen por una falsa: prueban la lógica del repositorio, no iroh.

| Test | Qué comprueba |
|---|---|
| devuelve el JSON y reutiliza la conexión | Dos peticiones seguidas abren una sola conexión |
| identificador inválido | Avisa con «El identificador iroh no es válido…» y no intenta conectar |
| cambia el identificador de Ajustes | Cierra la conexión del agente anterior y abre otra con el identificador nuevo |
| la petición falla | Cierra la conexión muerta y la siguiente petición reconecta |
| falla al conectar | Avisa con «No se pudo conectar…» y la siguiente petición lo vuelve a intentar |
| dos peticiones a la vez | Comparten el mismo intento de conexión |
| límite de conexión (5 s) y de petición (3 s) | Con reloj simulado, ambos acaban en `AgentUnavailableException`; el segundo cierra la conexión |
| pasado el límite de 5 s | La siguiente petición espera el mismo intento y no lanza otro |
| el intento conecta cuando ya nadie espera | La conexión tardía se aprovecha y no se cierra |
| cambia el identificador con un intento en marcha | Al llegar, la conexión del identificador viejo se cierra y la nueva sigue en uso |
| 20 conexiones muertas seguidas | Cada una se cierra y solo queda abierta la última (protege contra regresiones) |

### App: otros tests relacionados

- `settings_widget_test.dart`: Ajustes rechaza un identificador iroh que no son 64 caracteres hexadecimales y no lo guarda.
- `metrics_viewmodel_test.dart`: salir y volver rápido a Métricas, o «Reintentar» con una carga en curso, no deja dos suscripciones a `watch()`.

### Pendiente de test automático

Sigue sin test automático la conexión iroh real de `IrohMetricsRepository` (el `Endpoint` y la conexión de `iroh_flutter`): los tests anteriores usan una conexión falsa. El fallo al aceptar una conexión entrante en el agente (bucle de `run()`) tampoco tiene test automático: requeriría forzar un fallo de *handshake* real.

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
| 5 | Reiniciar el agente y el PC: el identificador iroh debe ser el mismo | **Hecha (confirmada por el autor, 16/11/2026)** | Éxito: el identificador iroh es el mismo tras reiniciar el PC. El 12/11/2026 ya se había comprobado reiniciando solo el *proceso* del agente (la clave secreta se conserva en disco) |

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
| 6 | La clave secreta se escribía con los permisos por defecto y solo después se hacía `chmod`, y un archivo de clave corrupto tumbaba el agente con un fallo interno | Se crea ya con `0600` (`os.open`), y un archivo corrupto da un error con mensaje claro | **Hecho (16/11/2026)**. Cubierto por `tests/test_iroh_secret_key.py`. Ver `03-problemas-y-soluciones.md` §11 |
| 13 | Las tareas de reenvío del túnel podían acumularse con el uso *(deducido; no se vio)* | No queda ninguna tarea viva al terminar las peticiones | **Hecho (16/11/2026)**. Cubierto por `test_tunnel_leaves_no_background_tasks_behind` |

### En la app (`App-movil/lib/data/iroh/iroh_metrics_repository.dart`)

| # | Fallo | Qué debería pasar | Estado |
|---|---|---|---|
| 3 | Conectar no tenía límite de tiempo: si el identificador no era alcanzable, se quedaba esperando para siempre | A los 5 s, `AgentUnavailableException` en vez de quedarse colgado | **Hecho** (`_connectTimeout` en `_open`). Cubierto por `iroh_metrics_repository_test.dart`, con una conexión falsa |
| 4 | Cada petición de métricas tampoco tenía límite de tiempo: si el agente se colgaba a medias, la gráfica se quedaba congelada sin avisar | A los 3 s (mismo tiempo que `HttpMetricsRepository`) se muestra el error en vez de quedarse congelada | **Hecho** (`_fetchTimeout` en `fetch`). Hasta el 13/11/2026 el error solo se veía si la pantalla aún no tenía datos; con datos ya cargados la gráfica se congelaba sin avisar (ver `03-problemas-y-soluciones.md` §7). El *timeout* y el aviso en pantalla están cubiertos por tests (`iroh_metrics_repository_test.dart` y `metrics_widget_test.dart`) |
| 5 | Reintentar reintentaba sobre la misma conexión QUIC; si esa conexión ya había muerto (agente reiniciado, cambio de red), reintentaba para siempre sin poder recuperarse | Reintentar abre una conexión nueva desde cero si la anterior falló, y recupera las métricas si el agente vuelve a estar disponible | **Hecho** (si falla la petición, `fetch` cierra la conexión y pone `_connection` a `null`, así el siguiente intento reconecta). Confirmado a mano en la prueba 4 de la matriz (cambio de red en caliente) y cubierto por test con una conexión falsa |
| 7 | Cambiar el identificador en Ajustes con una conexión ya abierta: el repositorio seguía hablando con el agente anterior | Cierra la conexión vieja y abre otra con el identificador nuevo | **Hecho (16/11/2026)** (`_connect`). Cubierto por test. Detalle en `03-problemas-y-soluciones.md` §8 |
| 8 | Un identificador mal pegado solo daba el aviso genérico «No se pudo conectar» | Ajustes lo rechaza al guardar si no son 64 caracteres hexadecimales, y el repositorio avisa con un mensaje propio sin intentar conectar | **Hecho (16/11/2026)**. Cubierto por tests de Ajustes y del repositorio. Ver `03-problemas-y-soluciones.md` §9 |
| 9 | Salir y volver rápido a Métricas, o «Reintentar» con una carga en curso, podía dejar dos suscripciones a `watch()` y dos conexiones a la vez *(deducido leyendo el código; no se vio en el móvil)* | Solo cuenta el último refresco: un contador de generación descarta los anteriores | **Hecho (16/11/2026)** (`MetricsViewModel`). Cubierto por tests. Ver `03-problemas-y-soluciones.md` §10 |
| 12 | Un intento de conexión que pasa de 5 s no se cancela (la API de `iroh_flutter` no lo permite) y se lanzaba otro en cada petición; si el viejo conectaba tarde, la conexión quedaba sin cerrar *(deducido; no se vio)* | Un solo intento nativo a la vez: las peticiones lo esperan y, si conecta tarde, se aprovecha o se cierra | **Hecho (16/11/2026)**. Cubierto por tests con la conexión falsa. Ver `03-problemas-y-soluciones.md` §12 |

### Aplazado a la fase 3 (cuando exista el login)

Detectados el 16/11/2026. Sin login, cualquiera que conozca el identificador llega al agente, así que endurecerlo ahora no cambia quién puede llegar; se hace junto con el resto de la seguridad (`04-plan-de-fases.md`, fase 3).

| # | Fallo | Qué debería pasar | Estado |
|---|---|---|---|
| 10 | El túnel no limita las conexiones ni los *streams* simultáneos, y no corta un *stream* que no envía nada *(deducido leyendo el código)* | Un límite de conexiones y de *streams*, y un *timeout* de inactividad | **Aplazado a la fase 3** |
| 11 | Cualquier excepción que no sea `iroh.IrohError` en el bucle de `run()` tumba el túnel, y nada lo reinicia hasta el servicio de la fase 5 | Capturar cualquier excepción del bucle, registrarla y seguir escuchando | **Aplazado a la fase 3** |

### Limitaciones conocidas y medición pendiente

- **IPv6 y relé caído:** no comprobados. El autor no puede reproducirlos (ni su red ni el relé público se pueden manipular), así que se dejan como limitaciones conocidas: con el relé caído, la app agotaría el límite de 5 s y mostraría el aviso de conexión perdida (deducido).
- **Fugas de memoria o de recursos nativos de iroh en el móvil:** no se pueden medir con un test automático. Procedimiento manual propuesto, **sin ejecutar todavía**: con la app en Métricas por iroh, anotar el uso de memoria con `adb shell dumpsys meminfo io.github.alexxio070.sysmote` (fila *Native Heap*); cortar y recuperar la conexión unas 20 veces (por ejemplo, parando y arrancando el agente); volver a medir tras unos minutos. Un crecimiento que no se estabiliza indicaría una fuga.
