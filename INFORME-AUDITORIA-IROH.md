# Informe de la auditoría de simplificación y legibilidad: parte de iroh

- **Fecha:** 18/11/2026
- **Rama:** `refactor/auditoria-iroh`, cortada de `origin/main` en `c7e1d9c`
- **Commits:** `a8e44d4`, `0750fe4` y `db7d50a` (ver §6)
- **Objetivo:** que cualquier persona que abra el proyecto, sin ser un agente de IA, entienda cómo funciona la parte de iroh, y que alex pueda explicar cualquier parte en directo ante el tribunal. Es una limpieza: no cambia el comportamiento ni el contrato de la API.

---

## 1. Resumen

| | Antes | Después |
|---|---|---|
| Tests del agente (suite completa) | 188 | **187** |
| Tests de iroh del agente | 13 | **12** |
| Tests de la app (suite completa) | 223 | **222** |
| Tests del repositorio y de la conexión iroh de la app | 15 | **14** (9 de la conexión + 5 del repositorio) |
| `flutter analyze` | sin avisos | sin avisos |
| Líneas de código y tests del alcance (diff de los dos commits de código) | | +356 / −367 |

Qué se ha hecho:

- **Código muerto fuera:** el script `agent/scripts/iroh_poc.py` y la constante `INTERNAL_HTTP_PORT`.
- **Estructura:**
  - la función de la clave secreta pasa a ser pública, porque la usa otro módulo;
  - el repositorio de métricas iroh recibe solo lo que usa.
- **Comentarios y docstrings** en el túnel y en el repositorio.
- **Tests:**
  - se quitan o fusionan los redundantes, después de demostrar, rompiendo el código a propósito, que otro test cubre lo mismo;
  - los tests de la conexión se separan de los del repositorio;
  - se añade un test que cubría un hueco.
- **Documentación** al día con el código.

---

## 2. Alcance y método

### Alcance

| Archivo | Responsable |
|---|---|
| `agent/sysmote/iroh_tunnel.py` | iroh |
| `agent/scripts/iroh_poc.py` | iroh |
| `agent/tests/test_iroh_tunnel.py`, `agent/tests/test_iroh_secret_key.py` | iroh |
| `App-movil/lib/data/iroh/iroh_metrics_repository.dart` y su test | iroh |
| `doc/iroh/` | iroh |

Durante la auditoría se vio que parte de lo encontrado afectaba a archivos de otras sesiones. Alex autorizó a esta sesión a cambiarlos:

| Archivo | Responsable | Cambio |
|---|---|---|
| `App-movil/lib/main.dart` | Interfaz | 1 línea |
| `agent/sysmote/services/pairing_service.py` | Backend | 2 líneas |
| `doc/agente/ESTRUCTURA.md`, `doc/agente/tests.md` | Backend | menciones y cifras |
| `doc/ui/tests.md` | Interfaz | cifras y filas |

`App-movil/lib/data/iroh/iroh_connection.dart` (de Interfaz) no se ha modificado: solo se rompió temporalmente para las comprobaciones de §5 y se restauró desde git.

### Método

1. **Paso 1, solo lectura:** se auditó el código de `origin/main` y se entregó un informe con hallazgos y recomendaciones.
2. **Paso 2, tras la aprobación:** se aplicaron los cambios en cinco bloques, con los tests y el análisis en verde antes y después de cada uno:
   1. código muerto y estructura;
   2. comentarios;
   3. tests del agente;
   4. tests de la app;
   5. documentación.
3. **Antes de borrar algo**, se demostró que no se usaba (`git grep` en todo `main`). **Antes de quitar un test**, se rompió a propósito el código que protegía y se comprobó que fallaba otro (§5).

---

## 3. Hallazgos de la auditoría

Líneas referidas a `origin/main` en `c7e1d9c`, antes de los cambios.

### A. Código muerto

| # | Dónde | Hallazgo | Prueba de que no se usa | Resultado |
|---|---|---|---|---|
| A1 | `agent/sysmote/iroh_tunnel.py:18-19` | Constante `INTERNAL_HTTP_PORT = 8444` | `git grep`: nadie la importa. `agent/sysmote/server.py:12` define su propio `PUERTO_INTERNO = 8444` | Borrada |
| A2 | `agent/scripts/iroh_poc.py` (entero) | Script de arranque manual de la fase 2. Desde la fase 3, el túnel lo arranca `sysmote.server.Servidores` (`server.py:83-86`) al abrir la TUI, con la clave real | Solo lo mencionaban la documentación y su propio docstring. Usaba otra clave (`iroh_secret_key_poc.bin`), así que daba **otro identificador iroh** que el agente real, y su puerto 8444 chocaba con el de la TUI | Borrado |
| A3 | `App-movil/lib/data/iroh/iroh_metrics_repository.dart:8` | `export 'iroh_connection.dart' show IrohConnector, IrohLink;` | Solo lo aprovechaba su propio test | Borrado; el test importa `iroh_connection.dart` |
| A4 | `iroh_metrics_repository.dart:13-18` | El constructor recibía un identificador y un `connector` que solo se usaban si no se pasaba una conexión. `main.dart` pasaba la conexión **y** un identificador que se ignoraba | `main.dart:61-65` y el test eran los únicos usos | Constructor `IrohMetricsRepository(conexión, token)`, igual que `IrohAuthRepository` |
| A5 | `iroh_tunnel.py:141` | Valor por defecto `limits: Limits = Limits()` en `_handle_connection` | Solo lo usaba la *fixture* `open_stream` de los tests, que se elimina (B1) | Quitado |

### B. Simplificaciones

| # | Dónde | Hallazgo | Resultado |
|---|---|---|---|
| B1 | `agent/tests/test_iroh_tunnel.py` | Dos «bancos de pruebas» para lo mismo: la *fixture* `open_stream` (que llamaba a `_handle_connection` directamente) y la clase `_Lab` (que usa el bucle real `_serve`) | Queda solo `_Lab` |
| — | `iroh_tunnel.py:63-108` | Se valoró sustituir la vigilancia de inactividad (`_Activity`, `_IdleTimeout` y `_wait_unless_idle`) por `asyncio.timeout()` con `reschedule()` | **Descartado:** ocuparía lo mismo y volvería la ambigüedad entre `TimeoutError` y `OSError` (`TimeoutError` es subclase de `OSError`), que ya se resolvió al endurecer el túnel |

### C. Estructura

| # | Dónde | Hallazgo | Resultado |
|---|---|---|---|
| C1 | `iroh_tunnel.py:48` y `pairing_service.py:7` | `_load_or_create_secret_key` llevaba guion bajo (privada), pero la importaba otro módulo (`pairing_service.py`, para poner el identificador iroh en el QR) | Pasa a ser pública: `load_or_create_secret_key` |
| — | `App-movil/lib/data/iroh/` | Una conexión compartida (`IrohConnection`) y dos repositorios finos (métricas y autenticación) | Correcto; sin cambios |

### D. Comentarios y documentación en el código

| # | Dónde | Hallazgo | Resultado |
|---|---|---|---|
| D1 | `iroh_tunnel.py` | El docstring del módulo no decía su papel ni quién lo arranca. `ALPN` y `Limits` no tenían docstring, y `run` no documentaba sus argumentos | Docstrings estilo Google en lo público y una línea en cada función privada. Importar el módulo sigue sin efectos secundarios (comprobado: no imprime nada ni crea tareas), compatible con `pdoc` |
| D2 | `iroh_metrics_repository.dart` | Sin comentario de archivo ni del constructor | Comentario de archivo (`///` antes de `library;`, compatible con `dart doc`) y del constructor |
| D3 | `agent/tests/test_iroh_secret_key.py` | Sin docstring de módulo | Añadido |

Los comentarios que ya había explican el porqué, no repiten el código (el EOF que no se propaga, las referencias débiles de `asyncio`, el `0600` desde la creación), y se conservan.

### E. Documentación de `doc/iroh/`

| # | Dónde | Hallazgo |
|---|---|---|
| E1 | `02-implementacion.md` §1 | El diagrama ponía `8443` en el camino de iroh. Hoy el modo local va por HTTPS en el 8443 con huella fijada y el modo iroh va al HTTP interno 8444. Faltaba la autenticación por iroh |
| E2 | `02-implementacion.md` §2 | «Destino del túnel» (la constante muerta) y «Arranque manual» (el script) estaban desactualizados |
| E3 | `02-implementacion.md` §3 | Describía partes internas que ya no están en `IrohMetricsRepository` sino en `IrohConnection`; la tabla de tiempos nombraba `_connect` y `_exchange` |
| E4 | `01-que-es-y-como-funciona.md:41` | Decía `127.0.0.1:8443` como destino del túnel |
| E5 | `README.md` | «Por hacer» daba el arranque automático como pendiente (ya existe con la TUI; solo el servicio systemd es de la fase 5) y hablaba de «la lógica del repositorio» |
| E6 | `04-pruebas.md` §0 | Un test con nombre antiguo y descripción con `GET /metrics`, la *fixture* `open_stream` y la sección de tests de la app desactualizada |

`03-problemas-y-soluciones.md` no se ha tocado: es un historial y describe lo que pasó en su fecha.

---

## 4. Revisión de tests

### Agente: antes, 13 tests

| Test | Tipo | Qué protege | Decisión |
|---|---|---|---|
| `test_tunnel_forwards_a_real_request` | Integración (iroh real por loopback) | Reenvío en los dos sentidos | **Eliminado:** lo cubren los tests que hacen peticiones reales (§5) |
| `test_tunnel_resets_the_stream_when_the_local_agent_is_down` | Integración | `reset` si no hay servidor local | Conservado (único) |
| `test_tunnel_leaves_no_background_tasks_behind` | Integración | Que las tareas de reenvío no se acumulen | Conservado. Mira el detalle interno `_tasks`, pero es la única protección contra esa fuga |
| `test_tunnel_closes_the_oldest_connection_beyond_the_limit` | Integración | Límite de conexiones | Conservado (límite del túnel) |
| `test_tunnel_refuses_streams_beyond_the_limit` | Integración | Límite de *streams* | Conservado. Usa esperas cortas: vigilar por si fuera frágil |
| `test_tunnel_frees_a_stream_slot_when_the_stream_ends` | Integración | Que el hueco se libere | Conservado |
| `test_tunnel_resets_a_stream_that_stays_idle` | Integración | Inactividad | Conservado |
| `test_tunnel_keeps_a_stream_that_keeps_moving_data` | Integración | Que no se corte un *stream* activo | Conservado |
| `test_tunnel_keeps_serving_after_an_unexpected_error` (2 casos) | Integración con un *endpoint* falso | Captura de excepciones del bucle | Conservados |
| `test_creates_the_key_with_private_permissions` | Unitario | Permisos `0600` de la clave | Conservado (seguridad) |
| `test_reuses_the_stored_key_so_the_identifier_survives_restarts` | Unitario | Identificador estable tras reiniciar | Conservado |
| `test_rejects_a_corrupt_key_file_with_a_clear_message` | Unitario | Archivo de clave corrupto | Conservado |

**Después, 12.** Los dos tests que usaban `open_stream` pasan a usar `_Lab`. El de tareas cuenta solo las tareas de su propio test (`_pending_tasks`), porque ahora pasa por el bucle `_serve`, que deja vivas las tareas de cada conexión hasta que esta se cierra.

### App: antes, 15 tests en `iroh_metrics_repository_test.dart`

Solo 4 probaban el repositorio: el JSON, el token `Bearer`, la petición sin token y el 401 de sesión. Los otros 11 probaban la lógica de conexión, que ahora vive en `IrohConnection`.

| Test | Decisión |
|---|---|
| reutiliza la conexión | Movido a `iroh_connection_test.dart` |
| identificador inválido | Movido |
| cambia el identificador de Ajustes | Movido |
| la petición falla, cierra y reconecta | Movido |
| falla al conectar y reintenta | Movido |
| dos peticiones a la vez comparten el intento | **Eliminado:** la misma regla la protege «pasado el límite de 5 s, la siguiente petición espera el mismo intento» (§5) |
| límite de 5 s al conectar | **Fusionado** en «pasado el límite de 5 s», que ahora comprueba además que no avisa a los 4 s |
| límite de 3 s en la petición | Movido |
| pasado el límite de 5 s, mismo intento | Movido (con la fusión anterior) |
| el intento tardío se aprovecha | Movido |
| cambia el identificador con un intento en marcha | Movido |
| 20 conexiones muertas seguidas | **Eliminado:** en cada vuelta es idéntico a «la petición falla, cierra y reconecta» (§5) |
| token como `Bearer`, sin token, 401 de sesión | Conservados en el test del repositorio |

**Después, 14:**
- `iroh_connection_test.dart`: 9 tests.
- `iroh_metrics_repository_test.dart`: 5 tests (pide `/metrics` y devuelve su JSON, `Bearer`, sin token, 401 de sesión, y el nuevo: otro código o un cuerpo que no es JSON avisan de formato inesperado).

**Hueco cubierto:** antes ningún test comprobaba que un código distinto de 200 y 401, o un cuerpo que no es JSON, dieran el aviso de formato inesperado. Se añade un test, y se comprobó que falla si se quita la comprobación del código 200.

### Cobertura

No se ha medido: exigiría una dependencia nueva (`pytest-cov`). En su lugar se han usado las mutaciones de §5, que demuestran directamente que lo que protegía cada test eliminado sigue protegido.

---

## 5. Pruebas de que no se pierde cobertura (mutaciones)

En cada caso se rompió a propósito el código y se ejecutaron los tests, **sin el test que se iba a eliminar**. Después se restauró el código (desde git o desde una copia) y se volvieron a pasar los tests en verde.

| Código roto a propósito | Resultado |
|---|---|
| El túnel no reenvía la respuesta (`await send.write_all(data)` → nada) | Fallan 5 de los tests que se quedan: `closes_the_oldest…`, `frees_a_stream_slot…`, `keeps_a_stream_that_keeps_moving_data` y `keeps_serving_after_an_unexpected_error` (2 casos) |
| El túnel no reenvía la petición (`writer.write(data)` → nada) | Fallan 6: los 5 anteriores y `leaves_no_background_tasks_behind` |
| Las tareas terminadas no salen del conjunto (`_tasks.discard`) | Falla `leaves_no_background_tasks_behind` |
| Sin `reset` cuando el agente local está caído | Falla `resets_the_stream_when_the_local_agent_is_down` |
| `IrohConnection` lanza siempre un intento nuevo en vez de reutilizar el que está en marcha | Fallan «pasado el límite de 5 s…» (se queda) y «dos peticiones a la vez» (se elimina) |
| `IrohConnection` olvida la conexión muerta sin cerrarla | Fallan «si la petición falla, cierra la conexión…» (se queda) y «20 conexiones muertas» (se elimina) |
| `IrohMetricsRepository` sin la comprobación del código 200 | Falla el test nuevo «otro código o un cuerpo que no es JSON…» |

**Un error propio detectado así:** al reescribir el test de tareas para `_Lab`, un primer filtro (`not task.done()`) le habría impedido detectar la fuga de tareas terminadas que no salen del conjunto. La mutación de `_tasks.discard` lo destapó y se corrigió antes del commit.

El archivo de tests del túnel se ejecutó **tres veces seguidas** tras los cambios, con los 9 tests en verde cada vez, para descartar que hubiera quedado frágil.

---

## 6. Commits

Son tres y no más pequeños porque cada uno debe dejar los tests en verde: el cambio de nombre de la función y el valor por defecto que se quita romperían los tests si fueran en commits separados de los tests que los usan.

| Commit | Contenido | Comprobado en ese commit |
|---|---|---|
| `a8e44d4` `refactor: limpiar el túnel iroh del agente y simplificar sus tests` | `iroh_tunnel.py`, `pairing_service.py`, borrado de `iroh_poc.py`, `test_iroh_tunnel.py` y `test_iroh_secret_key.py` | 187 tests del agente pasan |
| `0750fe4` `refactor: dar la conexión compartida al repositorio de métricas iroh y separar sus tests` | `iroh_metrics_repository.dart`, `main.dart`, `iroh_metrics_repository_test.dart` e `iroh_connection_test.dart` (nuevo) | `flutter analyze` sin avisos y 222 tests de la app pasan |
| `db7d50a` `docs: actualizar la documentación de iroh tras la auditoría` | `doc/iroh/` (01, 02, 04 y README), `doc/agente/ESTRUCTURA.md`, `doc/agente/tests.md`, `doc/ui/tests.md` y una entrada en `08-historial-de-cambios.md` | Sin enlaces relativos rotos ni espacios sobrantes |

Autoría de alex, sin `Co-Authored-By`.

---

## 7. Cómo reproducir las comprobaciones

```bash
# Agente (necesita un entorno con iroh, cryptography y argon2; el de backend-agente los tiene)
cd agent && PYTHONPATH=$PWD ../../backend-agente/agent/.venv/bin/python -m pytest -q -p no:cacheprovider

# App
cd App-movil && flutter analyze && flutter test
```

---

## 8. Lo que queda pendiente o sin verificar

- **La rama solo está en local:** falta subirla (`git push -u origin refactor/auditoria-iroh`) y que alex proponga la PR.
- **Ramas `feature/*` sin sincronizar:** `feature/iroh`, `feature/agent` y `feature/interfaz` no tienen estos cambios. Llegarán por el camino habitual tras fusionar en `main`.
- **Test duplicado entre sesiones:** «identificador inválido» sigue también en `iroh_auth_repository_test.dart` (de Interfaz). Se ha conservado en `iroh_connection_test.dart`, que es donde está la lógica, y el de Interfaz no se ha tocado: conviene que esa sesión decida si lo quita.
- **Conexión iroh real:** sigue probada solo a mano. Los tests de la app usan una conexión falsa, y los del agente, iroh real pero por loopback, sin relés.
- **Documentación HTML** (`pdoc` y `dart doc`): no se ha generado, como se pidió. Los docstrings están escritos para ser compatibles, pero no se ha comprobado generándola.
- **El intérprete de los tests del agente:** se ejecutaron con el de `backend-agente`, porque el entorno de la carpeta `iroh` no tiene `cryptography`. No se ha instalado nada.
