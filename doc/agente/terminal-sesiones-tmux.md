# Terminal del agente: sesiones persistentes con tmux

Decisión del 14/10/2026. Sustituye al diseño inicial, en el que el PTY de la terminal estaba ligado a la conexión del móvil (se cerraba al desconectar).

> **Estado de verificación:** nada de esto está implementado ni probado. Los comandos de tmux y el comportamiento de los emuladores de terminal descritos proceden de conocimiento general y están marcados como **por verificar** donde corresponde.

## 1. Principio

**La sesión es del agente, no de la conexión.** La app solo envía un mensaje al agente del tipo «abre una terminal y ejecuta este comando». El agente crea la sesión y la app se engancha a ella para ver la salida en tiempo real y teclear. Si la app se cierra, pasa a segundo plano, se limpia de recientes o se pierde la cobertura, **la sesión y el comando siguen en el PC**.

## 2. Arquitectura

```
App (xterm.dart)  ◄── WebSocket ──►  Agente  ◄── tmux attach (PTY interno) ──►  Sesión de tmux  ◄── tmux attach ──►  Ventana del PC
                                                                                  (shell $SHELL -l)                   (kitty, Konsole…)
```

| Pieza | Qué hace | Qué aporta |
|---|---|---|
| **Sesión de tmux** | Contiene el shell del usuario y lo que ejecute. Es independiente de cualquier ventana o conexión | Que el comando sobreviva a la app, a la red y al cierre de ventanas; es la pieza clave |
| **Ventana del PC** | Terminal gráfica del usuario conectada a la misma sesión | Que al volver al PC se vea lo ocurrido, con su fuente, colores y atajos |
| **Cliente interno del agente** | `tmux attach` ejecutado en un PTY sin ventana; el agente lo conecta al WebSocket | Que la app reciba la salida en tiempo real y pueda teclear |
| **Historial** | Al reenganchar, el agente pide a tmux lo impreso mientras no había cliente (`capture-pane`, por verificar) | Que la app recupere lo que se perdió |
| **Orden inicial** | Se abre el shell y se le envía el comando con `send-keys` (por verificar), no se lanza directamente | Que la sesión **no desaparezca al terminar el comando**: se ve la salida y se puede seguir escribiendo; y que funcione `sudo` pidiendo contraseña |

## 3. API propuesta

Los nombres son un punto de partida, igual que el resto de rutas (ver las de cada módulo en `../documentos-generales-del-proyecto/01-memoria-tecnica.md`, §3).

```
POST   /terminales              {comando?}  → {id}     crea la sesión (y su ventana en el PC)
GET    /terminales                          → lista    sesiones activas
WS     /ws/terminal/{id}                               engancha: repite el historial y sigue en vivo
DELETE /terminales/{id}                                 cierra la sesión y su ventana en el PC
```

Todas requieren el token de sesión, igual que el resto de la API.

## 4. Ciclo de vida

| Evento | Qué ocurre |
|---|---|
| La app se abre sin sesiones activas | Muestra una **terminal vacía**; no se crea nada en el PC |
| El usuario toca la terminal o pulsa la primera tecla, sin sesión activa | La app pide crear una sesión (sin orden) y guarda las teclas hasta estar enganchada (siguiente fila) |
| La app pide crear una sesión | El agente crea la sesión de tmux, envía el comando (si lo hay) y abre la ventana en el PC (si hay sesión gráfica) |
| La app se cierra, va a segundo plano, se limpia de recientes o pierde red | **Nada**: la sesión sigue |
| La app vuelve a abrirse | Se reengancha a la sesión y recibe el historial |
| El usuario escribe `exit` (o Ctrl+D) | El shell termina; la sesión se cierra; se cierran la ventana del PC y la de la app |
| El usuario cierra la ventana **en la app** | La app envía `DELETE`; el agente cierra la sesión y la ventana del PC |
| El usuario cierra la ventana **en el PC** | **La sesión termina** (decisión del 14/10/2026). Ver los prototipos pendientes |
| Pasa el tiempo sin clientes | **Nada**: no hay caducidad por inactividad |
| Se reinicia el agente | **Depende de dónde arranque tmux** (por verificar): por defecto systemd termina todos los procesos del servicio, incluido un tmux lanzado por el agente. Para que sobrevivan, tmux debe arrancar fuera del grupo del servicio (por ejemplo con `systemd-run --user`) |

No hay un comando `close`: `exit` y cerrar la ventana en la app bastan.

### Estado inicial: sin sesiones

**Decisión del 14/10/2026** (revisada el mismo día: primero se pensó crear la sesión con la primera orden y se cambió a la primera tecla).

Si no hay ninguna sesión activa, la app dibuja una **terminal vacía** con un **mensaje genérico** (por ejemplo, «Toca para abrir una terminal»). El primer toque sobre esa zona **cuenta como el disparador**: es lo que normalmente abre el teclado, y aquí además hace desaparecer el mensaje y pide crear la sesión; cualquier tecla que se pulse justo después se trata igual. En cuanto la sesión está lista, el mensaje genérico se sustituye por el **prompt real** del shell. Cuando se cierra la última pestaña, la app vuelve a la terminal vacía con el mensaje genérico.

Qué aporta:
- **Shell real desde el primer momento** tras ese primer toque o tecla: prompt, autocompletado con Tab e historial con ↑/↓, igual que en cualquier terminal.
- **No hay una sesión «principal» permanente:** el PC no acumula terminales que nadie ha pedido.

Qué implica:
- **Hay un retraso** entre el primer toque y que la sesión esté lista (crear la sesión, abrir la ventana del PC y engancharse); estimado en 200 ms–1 s en LAN y hasta 1,5–2 s en WAN por relé (sin verificar; a medir en la fase 4). Mientras tanto se mantiene el mensaje genérico o un indicador de carga, y las teclas que lleguen en ese intervalo se guardan y se envían en orden al estar enganchada, para no perder ninguna.
- **Aviso obligatorio:** como un simple toque o tecla ya abre una ventana en el PC, aunque el usuario no llegue a ejecutar nada, el mensaje genérico debe decirlo explícitamente (por ejemplo, «Toca para abrir una terminal en tu PC»), para que no sea una sorpresa. Para quitar esa terminal, se cierra la pestaña o se escribe `exit`.
- Qué cuenta exactamente como el toque o tecla que dispara la creación queda por afinar (ver sección 9): por ejemplo, si un toque accidental al hacer scroll debería contar.

## 5. Qué pasa en cada caso

| Caso | Resultado |
|---|---|
| Comando largo y cierras la app | Sigue; al volver ves la salida |
| `sudo pacman -Syu` / `sudo apt upgrade` y pierdes cobertura | Termina; no queda a medias por culpa del móvil |
| Lanzas un servidor en primer plano (`npm run dev`) y cierras la app | Sigue en marcha mientras no cierres la sesión |
| Vuelves al PC | Ves la ventana con todo lo ocurrido |
| Se pierde la red a medias y el móvil no cierra el socket | El agente lo detecta con *keepalive*; la sesión sigue |

## 6. Requisitos en el PC

| Requisito | Para qué | Si falta |
|---|---|---|
| `tmux` | Sesiones persistentes | La terminal funciona **ligada a la conexión** (se corta al desconectar), con un aviso visible |
| Sesión gráfica iniciada y variables `WAYLAND_DISPLAY`/`DISPLAY` | Abrir la ventana del PC | La sesión funciona igual, solo en la app |
| Un emulador de terminal | La ventana del PC | Igual que arriba |

`pipx` no instala `tmux`: se instala con el gestor de paquetes de la distribución. La TUI debería comprobarlo al arrancar y avisar.

## 7. Qué terminal se abre

Orden de búsqueda: valor `terminal` de `config.toml` → variable `$TERMINAL` → `xdg-terminal-exec` → lista conocida (kitty, Konsole, Alacritty, foot, GNOME Terminal…).

Cada emulador pasa el comando a ejecutar de forma distinta. Hace falta una tabla «emulador → cómo lanzarlo»:

| Emulador | Cómo ejecuta un comando |
|---|---|
| kitty | **Por verificar** |
| Konsole | **Por verificar** |
| Alacritty | **Por verificar** |
| GNOME Terminal | **Por verificar** |
| foot | **Por verificar** |

## 8. Límites conocidos

- **Un solo tamaño:** la terminal tiene una única cuadrícula de filas y columnas. Si hay dos clientes (móvil estrecho y ventana ancha), el tamaño lo dicta el último activo y el otro se ve con bordes o recortado.
- **Historial limitado** por el tamaño del buffer de tmux y por lo que se pida al reenganchar.
- **Reinicio del agente:** que las sesiones sobrevivan no está garantizado por defecto (ver sección 4).
- **Dependencia del sistema:** tmux. Ver la evolución a largo plazo (sección 11).
- **Una ventana del PC por sesión.** Con varias pestañas en la app (sección 10, ya implementadas en la app), cada una tiene su propia ventana.

## 9. Pendientes

### Prototipos antes de implementar (fase 4)

1. **Cierre de la sesión al cerrar la ventana del PC.** Por defecto, cerrar la ventana solo desengancha el cliente. Dos opciones: un gancho de tmux o que el agente vigile el proceso de la ventana (algunos emuladores se desvinculan y su PID no es fiable). El gancho debe distinguir la ventana del PC del cliente interno del agente.
2. **Historial sin duplicados:** recuperar lo acumulado y engancharse en vivo sin repetir líneas.
3. **Abrir la ventana** en kitty y en Konsole, con la sesión gráfica de KDE Plasma, y completar la tabla de la sección 7.
4. **Versión mínima de tmux** necesaria para las opciones usadas.
5. **Supervivencia al reinicio del agente:** comprobar que un tmux lanzado fuera del grupo del servicio sigue vivo cuando systemd reinicia `companion.service`, y que el agente se vuelve a enganchar.

### Decisiones abiertas

- Límite de sesiones simultáneas y tamaño del historial.
- *Keepalive*: intervalo y tiempo de espera.
- **Qué cuenta como disparador:** el toque sobre la terminal vacía y cualquier tecla que genere entrada (letras, Intro, Tab, flechas, Esc) deberían contar; los modificadores solos (CTRL, ALT) y el botón de ocultar teclado, no. Confirmar que un toque de scroll accidental no dispara la creación.
- **Texto exacto del mensaje genérico** y del aviso de que se abrirá una ventana en el PC.
- **Indicador de carga** mientras se crea la sesión (spinner, mensaje «Abriendo terminal…») y cuánto tiempo se guardan las teclas si la creación tarda más de lo normal o falla.

## 10. Varias terminales: pestañas en la app

**Estado (19/10/2026): implementado en la app.** Diseño final en
`doc/ui/interfaz-app.md` §5. Lo que sigue en esta sección es el diseño
previo a esa implementación; se conserva como referencia del lado del
agente (la API ya lo soportaba sin cambios, ver "Lo que no cambia en el
diseño" más abajo).

**La idea:** en la app se pueden abrir varias terminales a la vez, **como las pestañas de un navegador**. Cada pestaña es una terminal independiente, con sus propios comandos en ejecución.

| Término | Significado |
|---|---|
| **Pestaña** | Una terminal en la app |
| Sesión | La sesión de tmux que hay detrás (una por pestaña) |
| Ventana del PC | La ventana de la terminal gráfica (kitty, Konsole…) conectada a esa sesión (una por pestaña) |

### Comportamiento (como en un navegador)

- **Barra de pestañas** en la parte superior de la pantalla Terminal, con desplazamiento horizontal si hay muchas, y un botón **«+»** que abre una pestaña nueva: nueva sesión y nueva ventana en el PC.
- **Cambiar de pestaña no corta nada.** A diferencia de un navegador, todas las pestañas siguen ejecutando sus comandos en el PC, estén o no en pantalla.
- **Cerrar una pestaña** (×) cierra su sesión y su ventana en el PC. Así no se acumulan terminales abiertas cuando el usuario vuelve al PC.
- **Cerrar la ventana en el PC o terminar con `exit`** hace que la pestaña desaparezca de la app.
- **Al volver a abrir la app**, se restauran como pestañas las sesiones que la app tenía abiertas al cerrarse, consultando `GET /terminales`: solo las suyas, no cualquier otra sesión de tmux que exista en el PC. Si alguna ya no existe (se cerró desde el PC, o el agente se reinició sin sobrevivir), esa pestaña simplemente no se restaura.
- **Cada pestaña es independiente:** su directorio, sus variables y sus procesos no se comparten con las demás.

### Lo que no cambia en el diseño
- La API ya soporta varias sesiones (`POST`, `GET` y `DELETE /terminales`, con identificador por sesión).
- Cada pestaña usa su propia instancia de `Terminal` de `xterm.dart` en la app.

### Pendiente de definir

**Resuelto (19/10/2026):** todas las dudas de esta tabla quedaron cerradas al
implementar las pestañas en la app. Los valores concretos (título de pestaña,
límite, indicador de actividad, etc.) están en `doc/ui/interfaz-app.md`
§5, no se repiten aquí.

### Impacto en la app y en la interfaz
- `TerminalRepository` gana: listar sesiones, crear y cerrar. `TerminalViewModel` mantiene una lista de pestañas, cada una con su propio `Terminal`.
- Interfaz de la barra de pestañas especificada e implementada: ver `doc/ui/interfaz-app.md` §5.

## 11. Evolución a muy largo plazo: cliente propio, sin tmux

Para **eliminar la dependencia de tmux**, el agente podría sustituirlo por un gestor de sesiones propio:

- PTY propio del agente para cada sesión y buffer circular de salida (en lugar de `capture-pane`);
- un cliente del propio agente (`companion attach <id>`) que ejecuta la ventana del PC;
- reenganche por identificador de sesión.

**Qué se ganaría:** ninguna dependencia nueva en el PC y control total del comportamiento.
**Qué cuesta:** más código y mantenimiento, y reimplementar lo que tmux ya hace. Además, las sesiones no sobrevivirían a un reinicio del agente salvo que se diseñe expresamente.

Se descarta para el TFG por plazo y se deja como posibilidad futura. También figura en `../documentos-generales-del-proyecto/06-ideas-de-futuro.md`.
