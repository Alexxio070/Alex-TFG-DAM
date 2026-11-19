# Auditoría de simplificación y legibilidad: interfaz

Rama local `refactor/auditoria-interfaz`, creada desde `main` (`c7e1d9c`) el 19/11/2026.

**Alcance:** todo `App-movil/` salvo `lib/data/iroh/iroh_metrics_repository.dart` y su test (de la sesión de iroh), más `doc/ui/` (`interfaz-app.md`, `estructura-app.md`, `tests.md`).

**Objetivo:** que cualquiera entienda cómo funciona la app y que se pueda explicar en directo cualquier parte, sin cambiar el comportamiento ni el contrato.

## Resultado

| | Antes | Después |
|---|---|---|
| `flutter analyze` | No issues found | No issues found |
| `flutter test` | 223 pasan | 221 pasan |
| Cobertura de líneas (`flutter test --coverage`) | 89,1 % (2893/3247) | 89,2 % (2871/3220) |
| Archivos `.dart` en `lib/` | 85 | 90 (login partido en 5 archivos) |
| Archivos con comentario de cabecera (lib + test) | 1 | todos los del alcance |

`analyze` y `test` se ejecutaron antes de empezar y después de cada bloque, y salieron en verde todas las veces.

## Qué se hizo, por bloques

### Código muerto
- `notes_view.dart`: quitado el aviso «Sin emparejar», que no se podía alcanzar porque Notas solo se muestra con la sesión abierta. Se mantiene la guarda de `NotesViewModel`.
- `secure_token_storage.dart`: quitado el parámetro `storage`, que nadie pasaba.
- `home_viewmodel.dart`: quitado un `cancel()` del temporizador que acababa de terminar.
- `auth_viewmodel.dart`: quitado `usuario` (getter, campo y 5 asignaciones). Ninguna pantalla lo mostraba; solo lo comprobaban 2 líneas de test.
- `metrics_viewmodel.dart`: corregido un comentario que hablaba de un estado que ya no existe.
- **Se mantienen a propósito:** `AgentStatus.api` y `SessionInfo.dispositivo/creada`. No se usan, pero leerlos valida que la respuesta del agente está completa.

### Simplificación
- `AuthViewModel`:
  - `_enterSession(token)` sustituye tres copias de «guardar el token y entrar en sesión».
  - `register` y `submit` ya no repiten `_stage = …; notifyListeners();` en cada `catch`: cada uno pone su mensaje y el estado se fija una vez al final.
  - `_stopWaitingWithError(mensaje)` agrupa los tres finales de la espera de confirmación (rechazada, caducada o error).
- HTTP:
  - `sendToAgent()` en `pinned_http_client.dart` reúne el envío con límite de 3 s y la conversión de errores de red, que estaban duplicados en `HttpAuthRepository` y `HttpMetricsRepository`.
  - Único cambio de detalle: en el login el límite de 3 s ahora cubre también la lectura del cuerpo, como ya pasaba en Métricas.
- `kUnexpectedFormatMessage` sustituye 7 copias del texto «Respuesta del agente con formato inesperado». Las copias de `iroh_metrics_repository.dart` y `iroh_connection.dart` quedan como estaban, porque son de la sesión de iroh.
- Métricas:
  - La RAM usa `StorageUnit.format` en vez de repetir el cálculo.
  - `disk_card.dart` y `partition_menu.dart` importan el modelo de ajustes en vez del ViewModel.
- `kTerminalBlue` en `app_tokens.dart` sustituye el azul repetido en la terminal y en su vista previa.

### Reestructuración
- `features/auth/login_view.dart` (362 líneas, 8 clases) queda en 86 líneas, con solo la elección de pantalla. Las piezas pasan a `features/auth/widgets/`:
  - `registration_form.dart`
  - `login_form.dart`
  - `pending_confirmation.dart`
  - `auth_status_messages.dart` (sin cuenta / agente inalcanzable)
  - `auth_banner.dart`

### Comentarios
- Cada archivo del alcance (lib y test) empieza con un comentario breve que dice qué hace y qué papel tiene.
- Cada clase y cada función pública con un propósito que no es evidente tiene un `///` en español, compatible con `dart doc`.
- Los tres repositorios de `lib/data/fake/` (macros, notas y terminal) están marcados como **PLACEHOLDER**: no son código muerto y los usa `main.dart`.

### Tests (223 → 221)
- **Borrados**, cada uno después de probar con el código roto a propósito que otro test lo cubre:
  - `terminal_widget_test` «ejecuta un comando y muestra su salida». Al romper la salida de `whoami` en el fake, falla también «las teclas escritas mientras se crea la sesión no se pierden», que hace lo mismo y además prueba la cola de teclas.
  - `terminal_widget_test` «CTRL + c cancela la línea». Al romper el código de Ctrl en `TerminalViewModel`, falla `terminal_viewmodel_test` «Ctrl + letra manda el código de control». Lo único propio del test borrado era el `^C` que pinta el shell simulado; la cobertura del fake de la terminal baja de 84 % a 81 %.
- **Agrupados:** los 4 tests que solo prueban el shell simulado van en `group('shell de ejemplo (placeholder)')`, para quitarlos con él en la fase 4.
- **`home_widget_test`:**
  - Los arrastres usan un helper `dragTile` y calculan los puntos con `getCenter` sobre la ficha y la papelera, en vez de coordenadas fijas como `Offset(103, 171)`.
  - Se quitó el código del helper `makeFolder` que estaba copiado dentro de un test.
- **Se mantienen todos** los tests de autenticación, sesión, huella del certificado y registro, aunque se solapen entre capas.

### Documentación (`doc/ui/`)
- **`interfaz-app.md`:**
  - el texto de «sin cuenta» coincide con el de la app;
  - se indica que `FakeMetricsRepository` vive en `test/fakes/`.
- **`estructura-app.md`:**
  - descripción completa de `app.dart`;
  - `fake/` marcado como placeholders;
  - `auth/widgets/` y `sendToAgent` en el árbol;
  - fuera la nota histórica de `PairingRepository`, que ya está en el historial de cambios.
- **`tests.md`:** recuentos (221; pantallas 79; terminal 13) y el grupo placeholder.

## Clasificación de los tests (después)

| Tipo | Tests | Archivos |
|---|---|---|
| Repositorio | 69 | `fake_auth` 22, `http_auth` 18, `http_metrics` 13, `iroh_auth` 8, `connection_mode_auth` 3, `connection_mode_metrics` 2, `shared_preferences` 3 |
| ViewModel | 45 | `auth` 30, `metrics` 5, `home` 4, `terminal` 3, `settings` 2, `notes` 1 |
| Modelo / utilidades | 13 | `format` 8, `note_links` 5 |
| Widget | 79 | `login` 13, `settings` 13, `terminal` 13, `metrics` 10, `notes` 10, `home` 9, `shell` 8, `system_nav` 3 |
| Fuera del alcance | 15 | `iroh_metrics_repository_test` |

Huecos de cobertura que siguen igual. No se ha añadido nada porque la auditoría no añade tests nuevos:
- `extra_keys_bar.dart`: 0 %.
- `folder_dialog.dart`: 0 %.
- `folder_edit_sheet.dart`: 0 %.
- `run_macro.dart`: 44 %; falta el camino de «pedir confirmación».

## Descartado o pendiente

- **Pendiente, por decisión de Alex (19/11/2026): indicador real de conexión en el menú lateral.**
  - Hoy `ShellViewModel.isPaired` siempre es `true` con la sesión abierta, así que el pie del menú no refleja nada.
  - Propuesta: un `ConnectionStatusViewModel` que pida `GET /sesion` cada 10 s y muestre «Conectado» o «Desconectado», con sus tests, en un commit `feat:` aparte.
  - Con él hay que actualizar `doc/ui/interfaz-app.md` §1. Se hace después de la auditoría.
- **R2, no hecho:** mover `AgentUnavailableException` y `throwIfSessionError` a un archivo de excepciones común. Obligaría a tocar `iroh_metrics_repository.dart`, que es de la sesión de iroh. Habría que coordinarlo con ella.
- **R3, descartado:** renombrar las constantes públicas de `macro_grid_geometry.dart`. Solo las importa `macro_grid.dart`, así que renombrarlas sería cambiar por cambiar.
