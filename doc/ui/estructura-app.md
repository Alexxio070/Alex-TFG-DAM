# Estructura de la app Flutter

Documento de la organización de carpetas de `App-movil/lib/` y de cómo encajan las piezas. Arquitectura: **MVVM + provider** (ver `CLAUDE.md`). Árbol verificado leyendo `App-movil/lib/` el 20/10/2026.

La interfaz sigue [`interfaz-app.md`](interfaz-app.md), que refleja el código real de cada pantalla. `historico/ui-v1` y `historico/ui-v2` se conservan como historial (el prototipo inicial y la primera especificación de Notas).

## Árbol de carpetas

```
lib/
  main.dart                      arranque: crea los repositorios reales y llama a runApp
  app_providers.dart             lista única de providers y ViewModels (buildProviders)
  app.dart                       MaterialApp, tema y pantalla de carga mientras cargan los ajustes
  core/                          lo que usan todas las pantallas
    format.dart                  números con coma decimal y fechas relativas
    open_link.dart                abrir un enlace en el navegador
    theme/
      app_tokens.dart            colores claro/oscuro, paleta de acentos, constantes con nombre
      app_theme.dart             ThemeData + tokens
    widgets/
      app_button.dart            botón relleno o con borde
      app_fab.dart               botón flotante circular
      app_icon.dart              iconos SVG del diseño
      app_segmented.dart         control segmentado
      app_stepper.dart           botones - / valor / +
      app_switch.dart            interruptor 50x30 (área táctil 56x44)
      app_text_field.dart        campo de texto de una o varias líneas
      app_toast.dart             aviso inferior de una línea (con subtítulo opcional)
      confirm_card.dart          diálogo de confirmación único (showConfirmCard)
      field_label.dart           etiqueta + control, para formularios
      modal_card.dart            diálogo centrado y hoja inferior, con scrim
  data/                          de dónde salen los datos
    models/                      home_item, metrics, note, note_links, settings (enums y constantes)
    repositories/                interfaces abstractas
    http/                        implementación real contra el agente (HttpMetricsRepository)
    local/                       implementación real con shared_preferences (ajustes)
    fake/                        implementaciones con datos de prueba que usa la app
  features/                      una carpeta por sección
    shell/                       AppBar, drawer, estado de conexión, navegación
    home/                        cuadrícula de macros, carpetas, arrastre y diálogos
    metrics/                     tarjetas, gráficos de área, disco y particiones
    terminal/                    pestañas, xterm.dart y fila de teclas extra
    notes/                       lista de notas, búsqueda y formulario
    settings/                    ajustes
test/
  fakes/                         implementaciones en memoria que solo usan los tests
  *_test.dart                    un archivo por repositorio/ViewModel, más widget_test.dart
```

## Las cuatro capas

### core/
Piezas compartidas. Los controles que aparecen en más de una pantalla (interruptor, segmentado, stepper, campos de texto, diálogos, toast) se escriben una sola vez aquí para no duplicar lógica. `app_tokens.dart` también reúne las constantes con nombre que antes vivían sueltas en cada widget (colores de la terminal, fuente monoespaciada, ancho del drawer).

### data/
Todo lo relacionado con los datos.

- `models/`: clases simples que solo guardan datos. `note_links.dart` contiene la detección de enlaces; `settings.dart` tiene los enums de ajustes (`TempUnit`, `StorageUnit`, `ConnectionMode`) y sus conversiones.
- `repositories/`: interfaces que dicen qué se puede hacer, sin decir cómo.
- `http/` y `local/`: implementaciones reales (agente por HTTP, ajustes con `shared_preferences`).
- `fake/`: implementaciones con datos de prueba que se usan de verdad en la app (terminal, macros, notas, emparejado) mientras no existe esa parte del agente.

### features/
Cada sección sigue el mismo patrón:

| Archivo | Responsabilidad |
|---|---|
| `*_view.dart` | Dibuja la pantalla. |
| `*_viewmodel.dart` | Estado y acciones (`ChangeNotifier`). Habla con los repositorios. |
| `widgets/` | Piezas que solo usa esa sección. |

Terminal es la única sección con dos niveles: `TerminalTabsViewModel` gestiona la lista de pestañas, y cada pestaña tiene su propio `TerminalViewModel` (ver `XTERM_DART.md`).

### main.dart y app_providers.dart
`app_providers.dart` tiene la única lista de providers y ViewModels de la app (`buildProviders`), para no duplicarla entre `main.dart` y los tests (`test/widget_test.dart` la reutiliza con repositorios falsos). `main.dart` es el único sitio donde se decide qué implementación real de cada repositorio se usa.

## Qué es un repositorio

Una clase cuyo único trabajo es dar acceso a unos datos. Las pantallas piden lo que necesitan y no saben de dónde sale.

```dart
abstract class MacroRepository {
  Future<List<HomeItem>> loadItems();
  Future<void> saveItems(List<HomeItem> items);
  Future<void> run(Macro macro);
}

class FakeMacroRepository implements MacroRepository { ... }   // datos de prueba
class AgentMacroRepository implements MacroRepository { ... }  // agente Python (futuro)
```

Para conectar el agente real basta con escribir la implementación nueva y cambiarla en `main.dart`. Ninguna pantalla se modifica. Ya ha pasado con `MetricsRepository` y `SettingsRepository` (ver más abajo).

| Repositorio | Entrega | Implementación en `main.dart` |
|---|---|---|
| `MacroRepository` | cargar y guardar la cuadrícula (macros y carpetas) y ejecutar una macro | `FakeMacroRepository` |
| `MetricsRepository` | datos de la máquina (RAM total, particiones), historial de 60 s y flujo de muestras; lanza `AgentUnavailableException` si el agente no responde | `HttpMetricsRepository`, contra el agente real |
| `TerminalRepository` | enviar teclas, recibir la salida, crear sesión (`createSession`), avisar de que terminó (`sessionEnded`) y cerrar (`close`); se inyecta una fábrica (`TerminalRepository Function()`), una instancia por pestaña | `FakeTerminalRepository` |
| `NotesRepository` | listar (con búsqueda), crear, editar y borrar notas | `FakeNotesRepository` |
| `PairingRepository` | estado de emparejado, emparejar y desemparejar | `FakePairingRepository` |
| `SettingsRepository` | cargar y guardar tema, acento, unidades, alerta de temperatura, tamaño de fuente y conexión; `load()` devuelve `null` en el primer arranque | `SharedPreferencesSettingsRepository`, con persistencia local |

Los ajustes ya no son solo del móvil: se guardan con `SettingsRepository`, pero los lee un único `SettingsViewModel` compartido (registrado en `app_providers.dart`), no cada pantalla por su cuenta.

## Flujo de datos

```
View  ->  ViewModel  ->  Repository (interfaz)  ->  Fake / Http / SharedPreferences
View  <-  ViewModel  <-  Repository
        (notifyListeners)
```

Ejemplo, tocar la macro «Bloquear»:

1. La cuadrícula (`MacroGrid`) detecta el toque y lo pasa a la vista de Inicio.
2. La vista decide si hay que pedir confirmación (`runMacro`); si no, llama a `HomeViewModel.execute(macro)`.
3. El ViewModel llama a `MacroRepository.run(macro)`: hoy lo recibe `FakeMacroRepository`; en el futuro, el agente.
4. El ViewModel activa el aviso «Ejecutando...» y la vista lo muestra.

Ejemplo con un repositorio ya real, Métricas:

1. `MetricsViewModel.start()` pide `loadInfo()`/`loadHistory()` y se suscribe a `watch()`.
2. `HttpMetricsRepository` hace `GET http://<dirección>/metrics` al agente; si tarda más de 3 s o responde mal, lanza `AgentUnavailableException`.
3. El ViewModel guarda ese error (`error`) y la vista (`MetricsView`) muestra el aviso «No se puede conectar con el agente» con un botón «Reintentar» en vez de las tarjetas.
4. Al salir de la pantalla se llama a `stop()` (y al volver, `start()` de nuevo), con `AppLifecycleListener` para pausar también en segundo plano: así no se sigue sondeando al agente sin necesidad.

## Decisiones tomadas

- Tema: la temperatura usa el color `ink` del tema, no `#16181D` fijo (el prototipo lo hace ilegible en oscuro).
- Fuentes de la interfaz: Plus Jakarta Sans y JetBrains Mono como assets locales en `assets/fonts/`. La terminal real usa la fuente del sistema, no una empaquetada (ver `XTERM_DART.md`).
- Gráficos de área con `CustomPainter`, sin librería de gráficos.
- Arrastre de la cuadrícula con `Listener` + `Stack` + `AnimatedPositioned`, sin librería de reordenado (ninguna cubre fusionar, papelera y edición a 1500 ms). La geometría y los cálculos de impacto viven aparte, en `macro_grid_geometry.dart`.
- Terminal con `xterm.dart` (ver `XTERM_DART.md`); el shell simulado se sustituirá por el WebSocket del agente. Varias pestañas, cada una con su propio `TerminalViewModel`.
- Notas con tarjetas de texto seleccionable y enlaces pulsables, y formulario aparte (ver `historico/ui-v2`).
- Los ViewModels de las secciones se registran en `app_providers.dart`, así que su estado se conserva al cambiar de sección.
- Identificador de la app: `io.github.alexxio070.sysmote`; nombre visible: «Sysmote».

## Orden de implementación

1. Drawer + tema + shell
2. Inicio
3. Métricas
4. Terminal
5. Notas
6. Ajustes

Las seis secciones están implementadas; Métricas y Ajustes ya hablan con implementaciones reales (agente por HTTP y `shared_preferences`), el resto sigue con datos simulados hasta que exista esa parte del agente.
