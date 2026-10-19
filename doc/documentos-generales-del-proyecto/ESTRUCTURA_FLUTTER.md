# Estructura de la app Flutter

Documento de la organización de carpetas de `App-movil/lib/` y de cómo encajan las piezas. Arquitectura: **MVVM + provider** (ver `CLAUDE.md`).

La interfaz sigue `../ui/ui-v1/DESIGN.md` y `../ui/ui-v1/prototipo.dc.html`, salvo la pantalla de Notas, que sigue `../ui/ui-v2/DESIGN.md` (el campo único de v1 está descartado). Las diferencias de implementación están en la sección 10 de la v1 y en `08-historial-de-cambios.md`.

## Árbol de carpetas

```
lib/
  main.dart                      arranque: crea repositorios y providers, llama a runApp
  app.dart                       MaterialApp y tema
  core/                          lo que usan todas las pantallas
    format.dart                  números con coma decimal y fechas relativas
    open_link.dart               abrir un enlace en el navegador
    theme/
      app_tokens.dart            colores claro/oscuro, paleta de acentos, nombres
      app_theme.dart             ThemeData + tokens
    widgets/
      app_button.dart            botón relleno o con borde
      app_icon.dart              iconos SVG del diseño
      app_segmented.dart         control segmentado
      app_stepper.dart           botones - / valor / +
      app_switch.dart            interruptor 50x30 (área táctil 56x44)
      app_text_field.dart        campo de texto de una o varias líneas
      app_toast.dart             aviso inferior de una línea
      modal_card.dart            diálogo centrado y hoja inferior, con scrim
  data/                          de dónde salen los datos
    models/                      home_item (macro y carpeta), metrics, note, note_links
    repositories/                interfaces abstractas
    fake/                        implementaciones con datos de prueba
  features/                      una carpeta por sección
    shell/                       AppBar, drawer, estado de conexión, navegación
    home/                        cuadrícula de macros, carpetas, arrastre y diálogos
    metrics/                     tarjetas, gráficos de área, disco y particiones
    terminal/                    xterm.dart y fila de teclas extra
    notes/                       lista de notas, búsqueda y formulario
    settings/                    ajustes
```

## Las cuatro capas

### core/
Piezas compartidas. Los controles que aparecen en más de una pantalla (interruptor, segmentado, stepper, campos de texto, diálogos) se escriben una sola vez aquí para no duplicar lógica.

### data/
Todo lo relacionado con los datos.

- `models/`: clases simples que solo guardan datos. `note_links.dart` contiene la detección de enlaces.
- `repositories/`: interfaces que dicen qué se puede hacer, sin decir cómo.
- `fake/`: implementaciones con datos de prueba, igual que las simulaciones del prototipo.

### features/
Cada sección sigue el mismo patrón:

| Archivo | Responsabilidad |
|---|---|
| `*_view.dart` | Dibuja la pantalla. |
| `*_viewmodel.dart` | Estado y acciones (`ChangeNotifier`). Habla con los repositorios. |
| `widgets/` | Piezas que solo usa esa sección. |

### main.dart
Es el único sitio donde se decide qué implementación de cada repositorio se usa.

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

Para conectar el agente real basta con escribir la implementación nueva y cambiarla en `main.dart`. Ninguna pantalla se modifica.

| Repositorio | Entrega |
|---|---|
| `MacroRepository` | cargar y guardar la cuadrícula (macros y carpetas) y ejecutar una macro |
| `MetricsRepository` | datos de la máquina (RAM total, particiones), historial de 60 s y flujo de muestras |
| `TerminalRepository` | enviar teclas y recibir la salida de la sesión; con las sesiones del agente (`doc/agente/`), también crear y reenganchar una sesión (pendiente de la fase 4) |
| `NotesRepository` | listar (con búsqueda), crear, editar y borrar notas |
| `PairingRepository` | estado de emparejado, emparejar y desemparejar |

Los ajustes (tema, acento, unidades, alerta de temperatura, tamaño de fuente) son locales del móvil y no usan repositorio: los guarda un `SettingsViewModel` compartido que leen varias pantallas.

## Flujo de datos

```
View  ->  ViewModel  ->  Repository (interfaz)  ->  Fake / Agente
View  <-  ViewModel  <-  Repository
        (notifyListeners)
```

Ejemplo, tocar la macro «Bloquear»:

1. La cuadrícula (`MacroGrid`) detecta el toque y lo pasa a la vista de Inicio.
2. La vista decide si hay que pedir confirmación (`runMacro`); si no, llama a `HomeViewModel.execute(macro)`.
3. El ViewModel llama a `MacroRepository.run(macro)`: hoy lo recibe `FakeMacroRepository`; en el futuro, el agente.
4. El ViewModel activa el aviso «Ejecutando...» y la vista lo muestra.

## Decisiones tomadas

- Tema: la temperatura usa el color `ink` del tema, no `#16181D` fijo (el prototipo lo hace ilegible en oscuro).
- Fuentes: Plus Jakarta Sans y JetBrains Mono como assets locales en `assets/fonts/`.
- Gráficos de área con `CustomPainter`, sin librería de gráficos.
- Arrastre de la cuadrícula con `Listener` + `Stack` + `AnimatedPositioned`, sin librería de reordenado (ninguna cubre fusionar, papelera y edición a 1500 ms).
- Terminal con `xterm.dart` (ver `../ui/XTERM_DART.md`); el shell simulado se sustituirá por el WebSocket del agente.
- Notas con tarjetas de texto seleccionable y enlaces pulsables, y formulario aparte (ver `ui-v2`).
- Los ViewModels de las secciones se registran globalmente en `main.dart`, así que su estado se conserva al cambiar de sección.

## Orden de implementación

1. Drawer + tema + shell
2. Inicio
3. Métricas
4. Terminal
5. Notas
6. Ajustes

Las seis secciones están implementadas con datos simulados.
