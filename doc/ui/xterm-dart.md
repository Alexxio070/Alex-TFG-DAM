# xterm.dart en la app

Documento breve sobre el paquete que dibuja la terminal remota. Versión usada: `xterm 4.0.0` (pub.dev, repositorio TerminalStudio/xterm.dart). La API descrita se ha comprobado leyendo el código fuente de esa versión (12/10/2026).

## Qué es

Un **emulador de terminal** para Flutter. Un shell no envía texto plano: envía secuencias de escape (colores, mover el cursor, borrar línea o pantalla, modo pantalla completa). El paquete las interpreta y pinta el resultado. Tiene dos piezas:

| Pieza | Qué hace |
|---|---|
| `Terminal` | El modelo: guarda la pantalla y el historial, interpreta lo que recibe y genera lo que se envía al shell. No tiene interfaz. |
| `TerminalView` | El widget que dibuja un `Terminal`, gestiona el teclado, la selección y el scroll. |

## Cómo se ha implementado

Hay dos niveles de `ViewModel`. `TerminalTabsViewModel` (uno, global) gestiona la lista de pestañas; cada pestaña es un `TerminalViewModel` independiente, con su propio `Terminal` de `xterm.dart` y su propio `TerminalRepository` (se le inyecta una fábrica, no una instancia compartida, para que cada pestaña tenga la suya):

```
Teclado / teclas extra
        │  (texto o teclas)
        ▼
   Terminal.onOutput ──► TerminalViewModel ──► TerminalRepository.send ──► agente (PTY)
                                                                              │
   TerminalView ◄── Terminal.write ◄── TerminalViewModel ◄── repository.output ◄┘

   TerminalTabsBar ──► TerminalTabsViewModel.addTab/selectTab/closeTab ──► crea/cierra TerminalViewModel
```

| Archivo (`App-movil/lib/`) | Responsabilidad |
|---|---|
| `features/terminal/terminal_tabs_viewmodel.dart` | Lista de pestañas: crear, seleccionar, cerrar (con límite de `kMaxTerminalTabs`) y cerrar sola una pestaña cuya sesión termina (`exit`/Ctrl+D). |
| `features/terminal/terminal_viewmodel.dart` | Una pestaña: crea el `Terminal`, lo conecta al repositorio y gestiona CTRL y ALT pegajosos. |
| `features/terminal/terminal_view.dart` | Pantalla: barra de pestañas + `TerminalView` con el tema y la fuente, y la fila de teclas extra cuando hay teclado. |
| `features/terminal/widgets/terminal_tabs_bar.dart` | Barra de pestañas: un chip por pestaña (título + cerrar, con confirmación) y el botón «+» para abrir una nueva. |
| `features/terminal/widgets/extra_keys_bar.dart` | Fila ESC, TAB, CTRL, ALT, `-`, `/`, ↑, ↓ y ocultar teclado. |
| `data/repositories/terminal_repository.dart` | Interfaz: ver más abajo. |
| `data/fake/fake_terminal_repository.dart` | Shell simulado (`help`, `ls`, `echo`, historial con ↑/↓...) hasta tener el agente; una instancia por pestaña. |

`TerminalTabsViewModel` se registra una sola vez en `app_providers.dart`, así que la lista de pestañas se conserva al cambiar de sección; cada `TerminalViewModel` vive mientras su pestaña está abierta, no más.

### Interfaz de `TerminalRepository`

```dart
abstract class TerminalRepository {
  Stream<String> get output;      // lo que responde el PC
  Stream<void> get sessionEnded;  // la sesión terminó por su cuenta (exit, Ctrl+D...)
  Future<void> createSession();   // abre la sesión; se resuelve cuando está lista
  void send(String data);         // lo que teclea el usuario
  Future<void> close();           // libera la sesión (dispose de la pestaña)
}
```

`TerminalViewModel.requestSession()` llama a `createSession()` y pasa a `TerminalSessionState.ready` cuando termina (encolando lo que se teclee mientras tanto); se suscribe a `sessionEnded` para volver a `empty` y vaciar la cola. `dispose()` llama a `close()`.

## Cómo se usa en el código

Crear el terminal y conectarlo al repositorio:

```dart
final terminal = Terminal(maxLines: 1000);

terminal.onOutput = (data) => _repository.send(data);   // lo que teclea el usuario
_repository.output.listen(terminal.write);               // lo que responde el PC
```

Enviar teclas desde la fila extra:

```dart
terminal.keyInput(TerminalKey.escape);   // teclas especiales
terminal.textInput('-');                 // texto
```

Dibujarlo, con el tema y la fuente de la app:

```dart
TerminalView(
  vm.terminal,
  focusNode: _focus,
  theme: _theme,                         // fondo #0D0F12, texto #E6E8EB, ANSI
  deleteDetection: true,                 // borrar con el teclado de Android
  textStyle: TerminalStyle(fontSize: 13, height: 1.5), // fontFamily por defecto: 'monospace'
)
```

CTRL y ALT pegajosos: el `ViewModel` intercepta el siguiente carácter en `onOutput` y lo transforma (CTRL + `c` envía `\x03`; ALT antepone `ESC`) antes de enviarlo.

## Qué se gana usándolo

- **Terminal real, no una lista de líneas:** colores ANSI, cursor, borrado de línea y pantalla, y líneas que se parten, todo interpretado.
- **Programas a pantalla completa** (`vim`, `nano`, `htop`, `less`) gracias al buffer alternativo.
- **Selección** (mantener pulsado), historial con scroll y caracteres anchos o unicode, incluidos. **Copiar y pegar** solo vienen con atajos de teclado físico (Ctrl+Shift+C y Ctrl+V); el paquete no muestra menú de copiar/pegar en el móvil, así que hay que programarlo con `TerminalController` (selección) y `Clipboard` (como hace el ejemplo oficial del paquete).
- **Teclado correcto:** `keyInput` genera las secuencias que espera el shell (flechas, Ctrl, Alt, Esc).
- **Tamaño dinámico:** `TerminalView` (con `autoResize`, activo por defecto) calcula filas y columnas y redimensiona el `Terminal`, que avisa con `Terminal.onResize(columnas, filas, anchoPx, altoPx)`, necesario para un PTY.
- **Cambiar el origen de datos no toca la pantalla:** la UI solo ve `Terminal`; el repositorio puede ser el simulado o el WebSocket del agente.

## Límites y pendientes

- El cursor **no parpadea** en esta versión. Decisión del 15/10/2026: se descarta implementarlo; no compensa el esfuerzo de montar un parpadeo por fuera del paquete.
- **Fuente de la terminal: la del sistema, no una empaquetada (decisión del 15/10/2026).** No se pasa `fontFamily`, así que `xterm.dart` usa su valor por defecto, `'monospace'`, que en Android resuelve a la fuente monoespaciada del propio dispositivo (verificado en el código fuente del paquete, `lib/src/ui/terminal_text_style.dart`). Se descarta tanto JetBrains Mono como una Nerd Font.
  - **Conflicto con el espejo de la sesión:** el diseño de la terminal (`../agente/terminal-sesiones-tmux.md`) hace que la app y la ventana del PC muestren la misma sesión de tmux. El *contenido* es idéntico, pero el *aspecto* ya no: la ventana del PC usa la fuente que tenga configurada el usuario ahí (posiblemente una Nerd Font, con los iconos de prompts como Starship), y la app usa la fuente del sistema Android, que normalmente no es una Nerd Font. Los iconos de prompt que se vean bien en el PC pueden salir como cuadros en la app. Es una discrepancia visual aceptada, no un error.
- `onResize` aún no se envía al agente (se conectará con el PTY real).
- Al volver a abrir la app, la salida acumulada en la sesión del agente debe recuperarse y escribirse en el `Terminal`; pendiente con las sesiones persistentes (`../agente/terminal-sesiones-tmux.md`).
- Es una dependencia de terceros. Estado consultado el 12/10/2026: la 4.0.0 (27/02/2024) es la última versión en pub.dev y el paquete no está marcado como discontinuado; requiere Flutter ≥ 3.19. El repositorio no está archivado y su último push es del 19/06/2025.
