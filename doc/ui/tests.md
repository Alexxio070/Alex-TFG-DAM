# Tests de la app

Documentación de los tests de [`App-movil/test/`](../../App-movil/test/): qué prueba cada archivo y para qué sirve. Hay 96 tests, todos automáticos; ninguno depende de un móvil, de la red ni del agente real.

```bash
cd App-movil && flutter test                    # todos
cd App-movil && flutter test test/<archivo>.dart  # uno solo
```

Casi todos usan repositorios falsos o en memoria: prueban la app, no su conexión real con el agente. La única prueba de esa conexión es `http_metrics_repository_test`, con un cliente HTTP simulado. Las pruebas con el agente real (por USB con `adb reverse`) se hicieron a mano en la fase 1 y constan en el [plan de fases](../documentos-generales-del-proyecto/04-plan-de-fases.md).

## Apoyo (no son tests)

| Archivo | Para qué sirve |
|---|---|
| [`helpers/app_harness.dart`](../../App-movil/test/helpers/app_harness.dart) | `app()` monta la `SysmoteApp` completa con todos los repositorios falsos o en memoria; `pumpFor()` avanza el reloj falso a saltos de 100 ms para esperar animaciones y futuros. Lo usan todos los `*_widget_test.dart` |
| [`fakes/fake_metrics_repository.dart`](../../App-movil/test/fakes/fake_metrics_repository.dart) | Métricas aleatorias (CPU, RAM, temperatura) y 3 particiones de ejemplo (`/`, `/home`, `/mnt/datos`) |
| [`fakes/in_memory_settings_repository.dart`](../../App-movil/test/fakes/in_memory_settings_repository.dart) | Guarda los ajustes en una variable en memoria en vez de en `shared_preferences` |

## Lógica sin interfaz (36 tests)

| Archivo | Tests | Qué comprueba | Qué fallo detecta |
|---|---|---|---|
| [`http_metrics_repository_test.dart`](../../App-movil/test/http_metrics_repository_test.dart) | 9 | `HttpMetricsRepository` contra un `MockClient`: parsea partición y RAM; muestra actual en `loadHistory`; temperatura `null`; `watch()` pide `/metrics` en cada tick; URL desde Ajustes; código distinto de 200, JSON malformado, timeout de 5 s o tipo inesperado dan `AgentUnavailableException` | Que la app se quede colgada o muestre datos erróneos si el agente responde mal, tarde o con datos corruptos |
| [`metrics_viewmodel_test.dart`](../../App-movil/test/metrics_viewmodel_test.dart) | 2 | Si el repositorio falla al arrancar, pasa a estado de error (`error` con mensaje, `ready=false`); `retry()` se recupera cuando el agente vuelve | Que la pantalla de error con reintento no funcione de verdad |
| [`home_viewmodel_test.dart`](../../App-movil/test/home_viewmodel_test.dart) | 4 | `moveItem` cambia el orden; `mergeInto` de dos macros crea una carpeta; `mergeInto` sobre una carpeta existente añade dentro; `ungroupFolder` deja las macros sueltas | Errores de reordenado y agrupado de la cuadrícula de Inicio, sin simular arrastres |
| [`notes_viewmodel_test.dart`](../../App-movil/test/notes_viewmodel_test.dart) | 1 | Una respuesta lenta de una búsqueda antigua no pisa la de la más reciente (condición de carrera) | Que al escribir rápido en el buscador aparezcan resultados de una búsqueda ya abandonada |
| [`settings_viewmodel_test.dart`](../../App-movil/test/settings_viewmodel_test.dart) | 1 | Unos ajustes corruptos (`RangeError` al cargar) caen a los valores por defecto y `ready` pasa a `true` | Que unos `shared_preferences` dañados dejen la app en carga infinita |
| [`terminal_viewmodel_test.dart`](../../App-movil/test/terminal_viewmodel_test.dart) | 3 | Ctrl+letra manda el código de control (`\x03`); Alt antepone `ESC`; sin modificadores el carácter va tal cual | Que las teclas de la fila extra del teclado manden basura al PC |
| [`shared_preferences_settings_repository_test.dart`](../../App-movil/test/shared_preferences_settings_repository_test.dart) | 3 | Primer arranque sin nada guardado devuelve `null`; guardar y leer no pierde ningún campo; un índice de enum fuera de rango lanza `RangeError` | Pérdida silenciosa de datos al guardar o leer los ajustes |
| [`format_test.dart`](../../App-movil/test/format_test.dart) | 8 | `formatNumber`: coma decimal y decimales pedidos; `formatRelativeDate`: «ahora», «hace N min», «hoy», «ayer», día de la semana, `dd/mm/aaaa` | Números y fechas mal formateados en cualquier pantalla |
| [`note_links_test.dart`](../../App-movil/test/note_links_test.dart) | 5 | Detecta URLs solas y en medio de una frase (con y sin `http`), descarta la puntuación final, marca el rango exacto y ignora prefijos sueltos y texto sin enlaces | Enlaces mal recortados o falsos positivos al subrayar texto en Notas |

## Pantallas completas (60 tests)

Montan la app real con `app()` y repositorios falsos.

| Archivo | Tests | Qué comprueba |
|---|---|---|
| [`shell_widget_test.dart`](../../App-movil/test/shell_widget_test.dart) | 6 | Arranca en Inicio con el menú cerrado; el menú cambia de sección y se cierra; el engranaje abre Ajustes; el menú se abre y cierra arrastrando desde el borde, y un arrastre corto no lo abre |
| [`home_widget_test.dart`](../../App-movil/test/home_widget_test.dart) | 9 | Muestra y ejecuta macros; crea una macro; rechaza un nombre repetido; elige icono; arrastra una macro a la papelera; junta dos macros en una carpeta; al arrastrar una carpeta con macros a la papelera pregunta qué hacer (mover a «Sin grupo» o borrar todo) |
| [`metrics_widget_test.dart`](../../App-movil/test/metrics_widget_test.dart) | 5 | Muestra las 4 tarjetas con la partición del sistema; cambia de partición; mantener pulsada la tarjeta de disco abre el menú de particiones; temperatura en °F y tamaños en GiB según los ajustes; avisa si no hay sensor de temperatura |
| [`notes_widget_test.dart`](../../App-movil/test/notes_widget_test.dart) | 10 | Lista notas de ejemplo con su origen; crea, edita y elimina (con confirmación); no deja guardar una nota vacía; filtra al buscar y avisa sin resultados; copiar muestra un aviso; un error al guardar avisa y permite reintentar; no deja guardar dos veces mientras la primera está en marcha |
| [`terminal_widget_test.dart`](../../App-movil/test/terminal_widget_test.dart) | 15 | Estado vacío y prompt al tocar; las teclas escritas durante la creación no se pierden; `exit` cierra la pestaña; ejecuta comandos y da error en los desconocidos; flecha arriba recupera el historial; Ctrl+C cancela la línea; `clear` limpia la pantalla; el botón «+» abre una pestaña; tocar una pestaña la activa; cerrar pide confirmación; límite de 6 pestañas; cerrar una pestaña mientras se crea no falla; cerrar por instancia no cierra la pestaña equivocada |
| [`settings_widget_test.dart`](../../App-movil/test/settings_widget_test.dart) | 12 | Muestra todos los grupos; cambia las unidades de temperatura y almacenamiento; la alerta muestra u oculta el límite (pasos de 5); el límite se mantiene entre 60 y 95 y la fuente entre 10 y 22; tema oscuro; color de acento; guarda la dirección del agente en modo Local y rechaza una con formato inválido; cambiar a iroh muestra el campo de identificador; desemparejar pide confirmación y cancelar mantiene el emparejamiento |
| [`system_navigation_bar_widget_test.dart`](../../App-movil/test/system_navigation_bar_widget_test.dart) | 3 | Con una barra de navegación del sistema simulada (`FakeViewPadding`), el botón de añadir macro y el de nueva nota quedan por encima de la barra, y la papelera sube con ella y sigue funcionando |
