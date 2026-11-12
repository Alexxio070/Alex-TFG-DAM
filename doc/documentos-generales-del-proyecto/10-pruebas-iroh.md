# Pruebas de la fase 2: conexión remota con iroh

Matriz de pruebas de la prueba de concepto (`04` fase 2) y plan de pruebas de
blindaje frente a errores. Se completa a medida que se hacen las pruebas.

Abreviaturas: `04` [plan de fases](04-plan-de-fases.md), `02` [necesidades tecnológicas](02-necesidades-tecnologicas.md).

---

## 1. Matriz de pruebas de la PoC (`04` fase 2)

Mismos cinco casos que define `04`. El túnel iroh del agente
(`agent/sysmote/iroh_tunnel.py`, patrón dumbpipe) ya está integrado en la
app real: el selector Local/iroh de Ajustes elige entre `HttpMetricsRepository`
e `IrohMetricsRepository` (`App-movil/lib/data/connection_mode_metrics_repository.dart`).
La pantalla aislada (`lib/debug/iroh_poc_main.dart`) se mantiene solo para
probar el túnel sin pasar por Ajustes.

| # | Caso | Estado | Resultado |
|---|---|---|---|
| 1 | Móvil y PC en la misma Wi-Fi: la conexión debe pasar a directa | **Hecha (12/11/2026)** | Éxito: empieza por el relé (RTT ~100-120 ms) y varias peticiones sí pasaron a directa hacia la IP del móvil en la Wi-Fi (RTT 4-8 ms); otras se quedaron en el relé, esperable porque cada petición abre un *stream* nuevo y la vía directa tarda unos segundos en confirmarse |
| 2 | Móvil con datos móviles y PC en casa: empieza por el relé y debe intentar pasar a directa | **Hecha (12/11/2026)** | Éxito: las métricas reales del PC llegaron al móvil con datos móviles, con el widget real de la app (gráficas en vivo, actualización cada 1 s) |
| 3 | Bloquear el UDP saliente en el cortafuegos del PC (red restrictiva simulada): todo el tráfico debe ir por el relé | **Hecha (12/11/2026)** | Éxito: con `sudo iptables -I OUTPUT -p udp -j REJECT` en el PC, las métricas siguieron llegando por iroh (modo Ajustes → iroh), confirmando que cae al relé (TCP/HTTPS) cuando no hay UDP saliente |
| 4 | Cambiar de Wi-Fi a datos móviles en mitad del uso: comprobar la reconexión | **Hecha (12/11/2026)** | Éxito: con la app ya conectada por Wi-Fi, se apagó el Wi-Fi del móvil (pasa a datos móviles) sin cerrar la app; el repositorio reconectó solo (blindaje del punto 5) y la conexión incluso pasó a directa hacia la IP pública nueva del móvil (RTT ~93-103 ms), sin que la pantalla se quedara congelada |
| 5 | Reiniciar el agente y el PC: el identificador iroh debe ser el mismo | Pendiente | — |

**Cómo se hizo la prueba 2:** agente real (FastAPI + túnel iroh) arrancado a
mano en el PC con `agent/scripts/iroh_poc.py`; identificador iroh copiado a
mano en la pantalla de prueba de la app (antes de integrarla en Ajustes),
instalada desde un APK de *debug*.

**Cómo se hizo la prueba 3:** mismo agente ya arrancado; regla de `iptables`
añadida a mano en el PC y retirada al terminar la prueba
(`sudo iptables -D OUTPUT -p udp -j REJECT`).

**Cómo se hizo la prueba 1:** se añadió un diagnóstico temporal a
`iroh_tunnel.py` (`_watch_path`, usa `connection.paths()`) que imprime por
consola cada vez que la ruta seleccionada cambia entre relé y directa, con
el RTT y la dirección remota.

**Pendiente antes de repetir las pruebas 4 y 5:** confirmar si la red
usada tiene las mismas restricciones que la del centro (`02` §3.3, decisión
abierta en `07` §3.8).

---

## 2. Blindaje frente a errores

Fallos reales detectados al usar la PoC. El punto 2 llegó a darse de verdad:
el proceso del túnel se cayó en mitad de una prueba real por un
`iroh.IrohError` sin capturar al aceptar una conexión, justo el fallo que
describe esta fila (12/11/2026).

### En el agente (`agent/sysmote/iroh_tunnel.py`)

| # | Fallo | Qué debería pasar | Estado |
|---|---|---|---|
| 1 | Si el agente FastAPI no está arrancado (o se cae) y llega una conexión iroh, el reenvío de esa conexión lanzaba una excepción sin capturar dentro de una tarea en segundo plano: se perdía en silencio y el móvil se quedaba colgado sin aviso | La conexión iroh de esa petición se cierra con `reset` en cuanto falla la conexión al puerto local; el resto del túnel sigue funcionando | **Hecho.** Cubierto por `tests/test_iroh_tunnel.py::test_tunnel_resets_the_stream_when_the_local_agent_is_down` |
| 2 | Un fallo al aceptar una conexión entrante (`accept`/`connect`) tumbaba el túnel entero | El túnel sigue aceptando conexiones nuevas aunque una falle al aceptarse (`_accept_one` captura `iroh.IrohError` y sigue el bucle) | **Hecho**, revisado por lógica. Sin test automático (requeriría forzar un fallo de *handshake* real); se confirmó en la práctica el 12/11/2026 al caerse el túnel por este motivo antes del arreglo |

### En la app (`App-movil/lib/data/iroh/iroh_metrics_repository.dart`)

| # | Fallo | Qué debería pasar | Estado |
|---|---|---|---|
| 3 | Conectar no tenía límite de tiempo: si el identificador no era alcanzable, se quedaba esperando para siempre | A los 5 s, `AgentUnavailableException` en vez de quedarse colgado | **Hecho** (`_connectTimeout` en `_ensureConnection`). Sin test automático: requeriría una conexión iroh real en el entorno de test de Flutter |
| 4 | Cada petición de métricas tampoco tenía límite de tiempo: si el agente se colgaba a medias, la gráfica se quedaba congelada sin avisar | A los 3 s (mismo tiempo que `HttpMetricsRepository`) se muestra el error en vez de quedarse congelada | **Hecho** (`_fetchTimeout` en `_fetch`). Mismo motivo: sin test automático |
| 5 | Reintentar reintentaba sobre la misma conexión QUIC; si esa conexión ya había muerto (agente reiniciado, cambio de red), reintentaba para siempre sin poder recuperarse | Reintentar abre una conexión nueva desde cero si la anterior falló, y recupera las métricas si el agente vuelve a estar disponible | **Hecho** (`_connection` se pone a `null` en cualquier fallo de `_ensureConnection` o `_exchange`, así el siguiente intento reconecta). Sin test automático |

**Pendiente:** los puntos 3, 4 y 5 solo están revisados por lógica y probados
a mano, no con un test automático — habría que levantar un `Endpoint` iroh
real dentro del entorno de test de Flutter (viable en Linux con
`iroh_quic`, no intentado todavía por tiempo).
