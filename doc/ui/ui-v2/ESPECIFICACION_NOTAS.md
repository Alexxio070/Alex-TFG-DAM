# Especificación de UI v2 — Notas (espacio compartido)

> **Estado: definitiva.** Sustituye a la pantalla de Notas del prototipo v1 (`../ui-v1/ESPECIFICACION_UI.md`, §6), que queda descartada.
> Las demás pantallas (drawer, tema, Inicio, Métricas, Terminal y Ajustes) mantienen el diseño de v1.
> Origen funcional: Módulo F de `../../documentos-generales-del-proyecto/01-memoria-tecnica.md` y decisión 3.5 de `../../documentos-generales-del-proyecto/07-resumen-decisiones-y-contexto.md`.

## 1. Qué cambia respecto a v1

| | v1 (descartado) | v2 (definitivo) |
|---|---|---|
| Modelo | Un único campo de texto compartido | Lista de notas de texto o enlace |
| Operaciones | Escribir en el campo | Crear, editar, borrar y buscar (CRUD completo) |
| Tipo de nota | No existe | Se deduce solo del contenido; el usuario no lo elige. Los enlaces se detectan en cualquier parte del texto |
| Sincronización | En ambos sentidos, con estado «Sincronizando…» | Bajo demanda: al abrir la pantalla y al deslizar para recargar |
| Conflictos | No definidos | Si los dos lados editan la misma nota, se guarda el último cambio |

La app está pensada para usarse lejos del PC, por eso no hay actualización al momento.

## 2. Modelo de datos

Tabla `nota` del agente (ver `../../documentos-generales-del-proyecto/03-system-context.md`, sección 5a):

```
Nota { id, usuario_id, tipo:'texto'|'enlace', contenido, origen:'movil'|'pc', creado_en, actualizado_en }
```

La app no envía `usuario_id` ni `origen`: los pone el agente (`origen = 'movil'` para lo creado desde la app). `actualizado_en` lo actualiza el agente en cada cambio.

**Tipo deducido, sin pasos extra para el usuario.** El usuario solo pega o escribe el contenido. Al guardar, **el agente** marca la nota como `enlace` si su contenido incluye al menos una dirección web en cualquier parte del texto; en cualquier otro caso es `texto`. La app no envía el tipo: solo envía el contenido. El campo `tipo` queda guardado en la base de datos para que la TUI del PC lo muestre y filtre igual.

**Detección de direcciones.** Se considera dirección web todo fragmento que empiece por `http://`, `https://` o `www.` y continúe hasta el siguiente espacio o salto de línea. Se descartan los signos de puntuación finales (`. , ; : ! ? ) ] }` y comillas), de modo que «mira https://ejemplo.com/a.» enlaza a `https://ejemplo.com/a`. Si empieza por `www.`, al abrirla se le antepone `https://`.

API del agente:

```
GET    /notas?q=            lista (filtrada por texto si hay q), más recientes primero
POST   /notas               crea
PUT    /notas/{id}          edita
DELETE /notas/{id}          borra
```

## 3. Pantalla de lista

Sección «Notas» del drawer (mismo nombre y posición que en v1). El título de la AppBar es «Notas».

**Estructura**
- Barra de búsqueda arriba: campo de 36 dp, radio 12, borde `border-strong`, icono de lupa y texto «Buscar notas».
- Lista con scroll de tarjetas, separación 8 dp, márgenes laterales 12 dp.
- Botón flotante circular «+» (mismas medidas y posición que en Inicio: 60 dp, 20 dp del borde, 28 dp del fondo), color de acento.

**Tarjeta de nota** (fondo `surface`, borde 1 dp `border`, radio 16, padding 12)
- Contenido: 13 sp, máximo 3 líneas con elipsis.
- **Texto seleccionable, como una burbuja de mensajería.** El contenido es de solo lectura: **mantener pulsado** selecciona texto y muestra el menú nativo de Android (copiar, seleccionar todo, etc.).
- Las direcciones web que haya en el contenido, en cualquier posición, van en color de acento y subrayadas. **Pulsar sobre una abre ese enlace** en el navegador del móvil. El resto del texto mantiene el color normal.
- Pie: origen y fecha relativa a la izquierda, 11 sp `muted` (por ejemplo «Desde el PC · ayer»), y a la derecha dos botones de icono de 44 dp de área táctil: **copiar** (copia el contenido completo y muestra el aviso «Copiado») y **editar** (abre el formulario).
- Pulsar en el texto no abre la edición: solo selecciona o abre enlaces. La edición se abre únicamente con el icono de editar.

**Fechas relativas:** «ahora» (menos de 1 min), «hace N min» (menos de 1 h), «hoy», «ayer», día de la semana (menos de 7 días), fecha corta en otro caso.

**Gestos y estados**
- Deslizar hacia abajo desde el principio de la lista: recarga (indicador de carga estándar).
- Al abrir la pantalla: carga inicial con indicador de progreso centrado.
- Escribir en la búsqueda: pide `GET /notas?q=` con un retardo de 300 ms tras la última pulsación.
- Lista vacía: «Aún no hay notas» y debajo «Crea una nota para dejarla también en tu PC.»
- Búsqueda sin resultados: «Sin resultados para «texto»».
- Error de carga: aviso inferior (mismo estilo que el de Inicio) «No se pudieron cargar las notas»; se mantiene lo que ya había.
- Sin emparejar: la lista no se carga y se muestra «Sin emparejar · empareja el móvil para ver tus notas».

## 4. Formulario de nota

Pantalla completa bajo la AppBar, que muestra una X a la izquierda (cierra sin guardar) y el título «Nueva nota» o «Editar nota».

- **Contenido:** un único campo multilínea, `field`, radio 12, borde 2 dp de acento al enfocar, 14 sp, mínimo 150 dp de alto, con el teclado abierto al entrar en una nota nueva. Usa el `TextField` nativo para heredar selección y menú contextual de Android (pegar, copiar, cortar, seleccionar todo). No hay selector de tipo ni ningún otro campo.
- **Sin acciones de enlace en el formulario.** Es la caja donde se escribe: los enlaces se abren y se copian desde la tarjeta de la lista, igual que en las apps de mensajería (escribir en un sitio, leer en otro).
- **Guardar:** botón de acento de 48 dp. Deshabilitado mientras el contenido esté vacío.
- **Eliminar:** solo al editar. Botón con borde `border-strong` y texto rojo `#B42318`. Abre el diálogo «¿Eliminar esta nota?» con «Cancelar» / «Eliminar» (rojo), con el mismo estilo que el de desemparejar. Texto: «También dejará de estar en el PC.»
- Texto de ayuda al editar: «Si también la editas en el PC, se conserva el último cambio guardado.», 11 sp `muted`.
- Al guardar o eliminar se vuelve a la lista, que se recarga.

## 5. Datos simulados hasta conectar el agente

Detrás de `NotesRepository` (`list(q)`, `create`, `update`, `delete`), con una implementación `FakeNotesRepository` en memoria y tres notas de ejemplo (un enlace y dos textos, una creada desde el PC). Cuando el agente exista, solo cambia la implementación.

## 6. Implementación

- Abrir enlaces: paquete `url_launcher` (abre el navegador externo). Es la única dependencia nueva de esta pantalla.
- Copiar: `Clipboard` de Flutter (servicios del framework, sin dependencia extra).
- La detección de direcciones (sección 2) vive en un único sitio de la app (la capa de modelo) y solo la usa la tarjeta de la lista para mostrar los enlaces pulsables. El agente aplica la misma regla para deducir el tipo al guardar.
- La tarjeta usa `SelectableText.rich`: texto seleccionable con menú nativo y fragmentos pulsables (enlaces) mediante reconocedores de toque, que se crean y se liberan en el `State` del widget.
- El formulario usa `TextField` nativo; no necesita lógica de enlaces.

## 7. Criterios generales

- Mismos tokens de color, tipografía y medidas que v1.
- Áreas táctiles de al menos 44 dp. Botones de icono con descripción accesible.
- Toda la lógica de ordenación, búsqueda y marca de tiempo es del agente; la app solo muestra y envía.

## 8. Puntos abiertos (no bloquean la implementación)

- **Imágenes en el espacio compartido:** aún pensándolo; fuera de esta pantalla hasta decidirlo.
- **Borrado:** hoy solo desde el formulario. Si se quisiera deslizar para borrar en la lista, se añadiría después.
- **Otros esquemas** (`ftp://`, `mailto:`, direcciones sin `www.`, como `ejemplo.com`): no se detectan; solo `http`, `https` y `www.`.
