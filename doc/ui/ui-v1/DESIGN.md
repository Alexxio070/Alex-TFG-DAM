# Especificación de UI v1 — App Android (Flutter)

> **Histórico.** Sustituido por [`../ui-final/DESIGN.md`](../ui-final/DESIGN.md), la referencia actual de toda la interfaz. Se conserva como registro de cómo se llegó hasta allí.
>
> **Estado: v1 (prototipo inicial). La pantalla de Notas de esta versión (§6) queda DESCARTADA** y la sustituye la definitiva de [`../ui-v2/DESIGN.md`](../ui-v2/DESIGN.md).
> El resto de secciones (drawer, tema, Inicio, Métricas, Terminal y Ajustes) siguen vigentes como referencia visual y de comportamiento. La pantalla «Opciones» de este documento se llama ahora **«Ajustes»**. Esta carpeta se conserva como histórico de diseño.

Documento de traspaso para implementar en Flutter la interfaz diseñada en el prototipo `prototipo.dc.html`.
El prototipo es **la fuente de verdad** para colores, medidas, textos y comportamiento; este documento lo resume y explica qué es simulado.

> **Para ver el prototipo:** `prototipo.dc.html` y `support.js` deben estar en la misma carpeta; se abre con doble clic en Chrome. `support.js` es solo el motor que dibuja la plantilla: **no hay que portarlo a Flutter**, solo sirve para ver y probar el diseño.
>
> El prototipo es HTML con un componente JS (`class Component extends DCLogic`). Toda la lógica está en `renderVals()` y en los métodos de la clase. Los valores de estilo están inline en el HTML.

---

## 1. Estructura general

- Pantalla de referencia: **390 × 844** dp.
- **AppBar** blanca (64 dp), borde inferior 1 dp. A la izquierda: botón de menú (icono hamburguesa, 44×44) y, a su lado, el **nombre de la sección activa** (18 sp, peso 700).
- **Drawer desde la izquierda**, ancho 280 dp, con scrim #16181D (color `ink` claro) al 45 %.
  - Cabecera (64 dp): botón X para cerrar + nombre de la sección activa.
  - Opciones una debajo de otra (alto 48, radio 12): **Inicio, Métricas, Terminal, Notas**. La activa va con fondo del color de acento y texto blanco.
  - Pie: botón engranaje (abre **Ajustes**) a la izquierda y **estado de conexión** a la derecha (punto verde + "Conectado" / punto gris + "Sin emparejar").
- Al elegir una sección se cierra el drawer.

## 2. Tema y colores

Tokens (claro / oscuro):

| Token | Claro | Oscuro |
|---|---|---|
| bg | #F3F4F6 | #111316 |
| surface | #FFFFFF | #1B1E23 |
| ink (texto) | #16181D | #ECEEF1 |
| muted | #5B616E | #A3A9B4 |
| muted2 | #4A505C | #B8BDC6 |
| border | #E4E6EA | #2C3037 |
| line (divisores) | #EEF0F2 | #262A30 |
| border-strong | #D5D8DE | #3A3F47 |
| field (inputs) | #F7F8FA | #15181C |
| off (switch apagado) | #B9BEC7 | #4A4F58 |
| seg-on (segmento activo) | #FFFFFF | #3A3F47 |

- Rojo destructivo: **#B42318**. Verde conectado: **#1F9D55** (texto #146C43 claro / #5BD38C oscuro).
- **Colores de acento** (elegibles en Ajustes), por defecto el primero:
  Verde azulado #0F6B63 · Azul #3346C7 · Frambuesa #B4235A · Naranja #C2410C · Violeta #6D28D9 · Grafito #3F4652.
- Tipografía: **Plus Jakarta Sans** (UI) y **JetBrains Mono** (terminal, comandos).
- La terminal y su teclado son siempre oscuros, independientemente del tema.

## 3. Inicio — cuadrícula de macros

**Modelo**
```
Macro   { id, type:'macro', label, command, kind:'volume'|'lock'|'moon'|'bolt', confirm:bool }
Carpeta { id, type:'folder', name, color, children:[Macro] }
```

**Layout**
- Zona de botones desde debajo de la AppBar hasta el **último cuarto** de la pantalla (alto 576 dp).
- **2 columnas**, botones **cuadrados de 166×166**, separación 18, margen lateral 20, margen superior 24. Radio 24.
- Macro: icono grande (64) centrado en color de acento, sin fondo, y el nombre centrado debajo (15 sp, 600).
- Carpeta: fondo de su color, arriba hasta 4 cuadraditos blancos (miniaturas), abajo el nombre y "N macros" en blanco.
- **Scroll vertical solo si hay más de 6 elementos.**

**Gestos**
| Acción | Resultado |
|---|---|
| Toque en macro | Ejecuta su comando (o pide confirmación si `confirm`) y muestra aviso |
| Toque en carpeta | Abre un diálogo con sus macros (2 columnas), que también se ejecutan al tocarlas |
| Mantener **420 ms** (macro o carpeta) | Empieza a arrastrar: el botón se levanta (escala 1.05 + sombra) y su hueco queda al 25 % de opacidad |
| Soltar en otro hueco | Reordena (el resto se recoloca con animación de 220 ms) |
| Soltar una **macro** sobre el centro de otra macro | Crea carpeta "Carpeta" con las dos |
| Soltar una **macro** sobre una carpeta | La añade a la carpeta |
| Soltar una carpeta sobre otro elemento | Solo reordena (no se anidan carpetas) |
| Mantener una **carpeta** quieta **1500 ms** | Cancela el arrastre y abre la hoja de edición (renombrar + 6 colores) |
| Mientras arrastras | Aparece **papelera** circular (64 dp) abajo en el centro; se pone roja y crece al pasar por encima. Soltar ahí elimina el elemento y el resto se reordena |
| Arrastrar cerca del borde superior/inferior | Autoscroll |
| Moverse >8 px antes de los 420 ms | Se interpreta como scroll, no como pulsación larga |

- Zona de "encima de otro" para fusionar: ±52 dp del centro del botón destino (se resalta con anillo del color de acento y escala 1.05).

**Botón añadir**
- FAB circular 60 dp, color de acento, icono "+", **abajo a la derecha** (20 dp del borde, 28 dp del fondo). Se oculta mientras arrastras.
- Abre diálogo **"Nueva macro"**: campo *Nombre*, campo *Comando* (monoespaciado, sin autocorrección), interruptor **"Pedir confirmación"**, botones Cancelar / Crear (Crear deshabilitado hasta rellenar ambos campos).

**Ejecución**
- Aviso inferior (snackbar oscuro, deja libre el FAB): título `Ejecutando «nombre»` y debajo `$ comando` en monoespaciada. Dura ~2,2 s.
- Si la macro tiene `confirm`: diálogo `¿Ejecutar «nombre»?` mostrando el comando, con Cancelar / Ejecutar.

## 4. Métricas

Lista con scroll de tarjetas a ancho completo (radio 20, padding 16, separación 16). Cada tarjeta: título a la izquierda, valor actual grande (28 sp) a la derecha, gráfico de área de los **últimos 60 s** y pie con "Hace 60 s · escala · Ahora". Actualización **cada 1 s**.

1. **Uso de CPU** — 0–100 %.
2. **Temperatura de CPU** — escala 30–100 °C (86–212 °F). Si la alerta está activa y se supera el límite: valor en rojo + etiqueta "Alta".
3. **Uso de RAM** — "usado / total" en GB o GiB.
4. **Uso de disco** — barra horizontal usado/libre, GB/GiB y %.
   - Por defecto la **partición del sistema** (`/`).
   - **Mantener pulsado 1 s** la tarjeta (se encoge a 0.97 durante la espera) **o** tocar el chip de partición de la cabecera → desplegable con las particiones (punto de montaje, dispositivo y tamaño) con check en la activa.

## 5. Terminal

- Pantalla completa bajo la AppBar, fondo #0D0F12, texto #E6E8EB, JetBrains Mono.
- Prompt `usuario@pc:~$` (usuario #7EE787, `~` #79C0FF). Errores en #FF7B72. Cursor de bloque parpadeante.
- **Tocar en cualquier parte abre el teclado.** En la app real: teclado del sistema + **fila de teclas extra estilo Termux** encima: `ESC TAB CTRL ALT - / ↑ ↓` y botón para ocultar teclado. (El teclado QWERTY del prototipo es solo una simulación visual.)
- ↑/↓ recorren el historial. CTRL+C cancela la línea (`^C`), CTRL+L limpia.
- Tamaño de fuente configurable en Ajustes (10–22, por defecto 13).
- En el prototipo las respuestas son simuladas; en la app real la entrada/salida va al PC.

## 6. Notas — DESCARTADO en v1

> **Idea descartada.** Un único campo de texto compartido no cubre el espacio compartido definido en la memoria técnica (notas de texto y enlaces con CRUD, búsqueda y recarga). Ver la pantalla definitiva en [`../ui-v2/DESIGN.md`](../ui-v2/DESIGN.md). Lo que sigue se conserva solo como histórico.

- Un único campo de texto multilínea a pantalla completa, **compartido con el PC** en ambos sentidos.
- Barra de estado superior (40 dp): punto + "Sincronizado con el PC" / "Sincronizando…" (ámbar #D97706) / "Sin emparejar · no se sincroniza"; a la derecha, número de caracteres.
- Usar el **TextField de Flutter** para heredar la selección y el menú de texto con el aspecto de Android (pegar, copiar, cortar, seleccionar todo, compartir). No es el menú nativo: Flutter lo dibuja él mismo, y la opción «buscar» solo existe en iOS. No implementar menús propios.

## 7. Ajustes, antes «Opciones» (engranaje del drawer)

| Grupo | Ajuste | Valores | Efecto |
|---|---|---|---|
| Unidades | Temperatura | °C / °F | Métricas → temperatura y escala |
| Unidades | Almacenamiento | GB / GiB (×0,9313) | Métricas → RAM y disco |
| Métricas | Alerta de temperatura | on/off | Resalta temperatura alta |
| Métricas | Límite (si alerta on) | 60–95 °C, pasos de 5 (defecto 85) | Umbral de la alerta |
| Terminal | Tamaño de fuente | 10–22 (defecto 13), con vista previa | Terminal |
| Apariencia | Tema | Claro / Oscuro | Toda la app (salvo terminal) |
| Apariencia | Color de acento | Botón que abre hoja inferior con 6 colores | Toda la app |
| Dispositivo | Desemparejar | Botón rojo → diálogo de confirmación | Estado "Sin emparejar" en drawer y Notas |

Controles: segmentados (fondo `line`, segmento activo `seg-on`), interruptores 50×30 en área táctil 56×44, steppers − / + de 44×44.

## 8. Qué es simulado en el prototipo

- Datos de métricas (aleatorios), particiones de ejemplo, respuestas de la terminal, sincronización de notas, ejecución de macros (solo muestra el aviso) y emparejado.
- En la app real todo eso viene del **agente Python del PC**.

## 9. Criterios generales

- Áreas táctiles ≥ 44 dp. Todos los botones de icono con descripción accesible.
- Animaciones: drawer 280 ms, recolocación de botones 220 ms, interruptores 150 ms.

## 10. Notas de implementación en Flutter

Diferencias entre este documento y la app Flutter actual (`App-movil/`). El prototipo HTML no se ha modificado.

| Tema | Prototipo / especificación | Implementación |
|---|---|---|
| Pantalla de Notas | Campo único compartido (§6) | Sustituida por la lista de `ui-v2` |
| Opciones | «Opciones» | Se llama «Ajustes» |
| Tamaño de los botones de Inicio | Fijo, 166 dp | Se adapta al ancho del móvil (166 dp a 390 dp de ancho) |
| Aviso «No caben más botones» | Muestra una línea `$` vacía | No muestra la línea del comando |
| Vibración al ejecutar | Sí (15 ms) | `HapticFeedback.lightImpact()` |
| Valor de la temperatura | Color fijo `#16181D` (ilegible en oscuro) | Color `ink` del tema; rojo con «Alta» si pasa el límite |
| Teclado de la terminal | Teclado QWERTY simulado | Teclado del sistema con la fila de teclas extra de §5 |
| Cursor de la terminal | Bloque parpadeante | Bloque **sin parpadeo** (limitación de `xterm.dart` 4.0.0) |
| Terminal | Texto simulado | `xterm.dart` con shell simulado detrás de `TerminalRepository` |
| Feedback táctil | Sin onda | Onda estándar de Android en botones y filas |
| Gráficas de Métricas | Trazados SVG | `CustomPainter` con la misma cuadrícula y escala |
| Fuentes | Plus Jakarta Sans y JetBrains Mono | Mismas, como assets locales (JetBrains Mono no es Nerd Font; ver `08`) |
