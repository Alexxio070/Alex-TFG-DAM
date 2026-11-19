# Informe de la auditoría final: integración, revisión global y auditoría complementaria

- **Fecha:** 19/11/2026
- **Rama:** `refactor/auditoria-integracion`, cortada de `main` en `c7e1d9c`
- **Quién:** la sesión de gestión del proyecto
- **Objetivo:** comprobar el trabajo de las tres auditorías (agente, iroh e interfaz), reunirlo en una sola rama y buscar lo que se hubiera escapado antes de abrir el PR hacia `main`. Incluye una auditoría complementaria de lo que ninguna sesión había mirado: organización de carpetas y archivos, legibilidad, completitud de los comentarios, seguridad del login, dependencias y configuración de Android. Las correcciones que salieron de ella están aplicadas en esta misma rama.

Los otros tres informes de esta carpeta son los de cada sesión: `Informe_auditoria_backend.md`, `Informe_auditoria_iroh.md` e `Informe_auditoria_interfaz.md`.

---

## 1. Resumen

| | Resultado |
|---|---|
| Tests del agente | **155 pasan** (Python 3.14) |
| Tests de la app | **220 pasan** |
| `flutter analyze` y `dart doc` | `analyze` sin avisos; `dart doc` con 0 avisos y 0 errores |
| APK de release compilado desde una copia limpia, como dice el README | 26,1 MB, en unos 2 minutos |
| Fallos encontrados en el código de las tres auditorías | ninguno |
| Fallos encontrados fuera de ellas | 1 de gravedad alta (la instalación con `pipx`), corregido |
| Hallazgos de la auditoría complementaria | 21: 10 corregidos (algunos en parte), 5 son decisiones del autor, 5 no requieren acción y 1 no se puede cerrar desde el repositorio |
| Secretos o datos personales en el historial | ninguno (ver §7) |

El código está limpio y bien organizado: ninguna violación de capas, ningún import sin uso, ninguna duplicación real, ningún código comentado ni `print` olvidado. Los hallazgos son sobre todo de consistencia y mantenimiento.

---

## 2. Qué se hizo

1. **Lectura de los diffs completos** de las tres ramas, sin contar sus informes: iroh (17 archivos), agente (52) e interfaz (123). En interfaz, unos 85 archivos solo ganan comentarios o cabeceras y se revisaron aparte de los 40 que tocan código (28 en `lib/` y 12 en `test/`), que se leyeron enteros.
2. **Integración** en una rama nueva, con merges en este orden: agente, iroh, interfaz. Cada merge conserva los commits de la sesión; no se reescribe nada.
3. **Comprobaciones automáticas** sobre toda la rama (en el repositorio no hay ningún script nuevo, eran temporales): enlaces relativos y externos, rutas y nombres citados frente al código, referencias cruzadas entre documentos, versiones, rutas y códigos de error del contrato frente al agente y la app, y cifras de tests frente a los tests reales.
4. **Búsqueda de secretos y datos personales** en todo el historial.
5. **Ejecución real de la guía de instalación** en carpetas limpias y con un `HOME` temporal, sin tocar la configuración del usuario.
6. **Auditoría complementaria** (§6): estructura y capas, tamaños, formato, código sin uso, cobertura de docstrings y de `///`, revisión del flujo de login, vulnerabilidades y licencias de las dependencias, Android y capturas.
7. **Correcciones** de lo encontrado, cada una con sus tests y en commits separados (§9).

---

## 3. Revisión de las tres auditorías

Los tres informes coinciden con lo que hay en el código. Se contrastaron con comandos los puntos donde «quitar» o «unificar» podía cambiar el comportamiento:

| Cambio | Comprobación | Resultado |
|---|---|---|
| Se elimina el parámetro `desde` de los intentos de login | El único llamador en `main` pasaba siempre `desde=""` | Equivalente |
| `registrar` exige `dispositivo` | La app lo envía siempre | Sin efecto en la app |
| Se quita `_toastTimer?.cancel()` de `_clearToast` | Solo lo llama el propio temporizador al dispararse | Seguro |
| La RAM usa `StorageUnit.format` | Es exactamente `formatNumber(x * factor, decimales)` | Idéntico |
| Login partido en cinco archivos | Comparado línea a línea con el original | Solo cambian los constructores, de privados a públicos |
| `AuthViewModel`: estado fijado una vez y `_enterSession` | Leído completo | Cada rama equivale a la anterior |
| Tests eliminados | Tablas de mutaciones de cada informe | Dos huecos que la prueba detectó se recuperaron (en el agente) |
| Cifras de los comentarios (300 ms, 2,2 s, 50 caracteres, 3 notas, 4 macros, comandos del shell simulado) | Contrastadas con el código | Correctas |

Observaciones menores, sin corregir porque no son fallos:

- **Un cambio de comportamiento que el propio informe de interfaz declara:** en el login, el límite de 3 s ahora cubre también la lectura del cuerpo de la respuesta, como ya pasaba en Métricas.
- `RegistroRequest.dispositivo` pasa de `str | None` a `str` con valor por defecto. Un cliente que enviara `"dispositivo": null` recibiría un 422 en vez de «Móvil». La app no lo hace.
- `test_el_origen_del_intento_se_guarda` exige el valor `"testclient"`, que pone el cliente de pruebas de FastAPI: queda ligado a ese detalle de la librería.
- El comentario de `app_drawer.dart` habla de «estado de conexión», pero ese indicador hoy no refleja nada real. Es el pendiente que el informe de interfaz ya anota.

---

## 4. Integración: conflictos y correcciones

Cinco conflictos de texto, resueltos a mano: `pairing_service.py`, `doc/agente/ESTRUCTURA.md`, `doc/agente/tests.md`, `doc/ui/tests.md` e `iroh_metrics_repository_test.dart`.

Dos fallos que Git no detecta y que solo salieron al ejecutar:

| Fallo | Cómo se vio | Corrección |
|---|---|---|
| El test nuevo de iroh importaba `AgentUnavailableException` desde un archivo del que interfaz la había movido | `flutter analyze` daba 5 errores | `cfb903f` |
| `doc/iroh/02-implementacion.md` citaba `pairing_service.IROH_KEY_PATH`, que el agente movió a `rutas.py` | Búsqueda de referencias | `6e71ff1` |

También se corrigió el comentario de `pairing_service.py`, que decía que usaba una función «privada» de iroh que la auditoría de iroh hace pública.

---

## 5. Hallazgos de la revisión global

| # | Gravedad | Hallazgo | Estado |
|---|---|---|---|
| 1 | **Alta** | **La instalación con `pipx` (y con `pip`, sin modo editable) estaba rota.** `schema.sql` estaba fuera del paquete, así que `sysmote` terminaba con un `FileNotFoundError` al abrir la base de datos. El README la ofrecía como alternativa válida | Corregido en `7c5142f`: el archivo pasa a `agent/sysmote/` y se declara como dato del paquete. Verificado con el paquete construido, instalado sin modo editable y arrancado, y con `pipx install ./agent` |
| 2 | Media | `07` decía que hasta la fase 9 la cuenta se crea en la TUI y que el QR llega en la fase 9. Contradecía `01` §5.1 y el contrato | Corregido en `1a2a2c5` |
| 3 | Media | La tabla de errores del contrato omitía `404 no_encontrado` y `405 metodo_no_permitido` | Corregido en `1a2a2c5` |
| 4 | Baja | `huella_distinta` figuraba como un error del agente, pero es un error de la app | Corregido en `1a2a2c5` |
| 5 | Baja | Los README no listaban `doc/auditoria/` y omitían `/login/solicitud/{id}` entre las rutas sin sesión | Corregido en `1a2a2c5` |
| 6 | Baja | `CONTRIBUTING.md` describía una rama `feature/<nombre>` por tarea, que ya no es el flujo real | Corregido en `1a2a2c5` |
| 7 | Baja | `pyproject.toml` no declaraba la licencia y `pytest-asyncio` avisaba del ámbito de los fixtures | Corregido en `d5a29f2` (licencia `GPL-3.0-only`) |
| 8 | Baja | Android: `allowBackup` no está definido y vale por defecto | Decisión del autor (ver §6.6) |
| 9 | Baja | Los `CLAUDE.md` locales, que no están en el repositorio, aún dicen que el agente no tiene `schema.sql` | Fuera del repositorio, sin corregir |
| 10 | Informativo | La app no llama todavía a `/capacidades`, aunque el agente y el contrato la tienen | Sin acción |
| 11 | Informativo | Tres `TODO` en la TUI, ya documentados en `tui.md`, y el aviso de firma de la release del `build.gradle.kts`, que el README ya declara | Sin acción |

---

## 6. Auditoría complementaria

### 6.1 Organización de carpetas y archivos

El agente se organiza en `api/`, `services/`, `repositories/`, `models/` y `tui/`, y la app en `core/`, `data/` y `features/` (una carpeta por sección). Ambas estructuras son coherentes con lo que declara la documentación.

**Verificado:**
- **Agente:** ningún módulo de `services/`, `repositories/`, `models/` o `api/` importa de una capa que no le toca (la API ya no importa repositorios).
- **App:** las dependencias van en un solo sentido, `core` ← `data` ← `features`. Ninguna vista ni widget importa una implementación concreta de repositorio.
- **Tamaños:** el archivo de código más grande tiene 331 líneas (`auth_viewmodel.dart`) y ninguna función de Python pasa de 36 líneas.

| # | Gravedad | Hallazgo | Estado |
|---|---|---|---|
| A1 | Media | **Acoplamiento entre secciones de la app.** 13 imports entre secciones distintas. Ocho son legítimos (el shell compone las secciones y varios ViewModels dependen de `AuthViewModel`). Cuatro apuntaban a piezas compartidas alojadas dentro de una sección: `app_top_bar.dart`, `connection_sheet.dart` y `settings_viewmodel.dart` (leído por Métricas y Terminal) | **Corregido en parte.** `AppTopBar` se movió a `core/widgets/` (`5f9c76f`). `settings_viewmodel` y los dos widgets de conexión se quedan en `settings/`: dependen del estado global de Ajustes, así que moverlos solo desplazaría el acoplamiento. Se documenta como excepción en `estructura-app.md` (`9ce524c`) |
| A2 | Baja | **Tests sin reflejar la estructura del código:** 25 archivos planos en `App-movil/test/` y 18 en `agent/tests/`. Manejable hoy | Sin acción; espejar las carpetas si siguen creciendo |
| A3 | Baja | **Mezcla de idiomas en los nombres del agente:** la capa de métricas (fase 1) en inglés y la de seguridad (fase 3) en español, incluso dentro de `repositories/` | **Documentado** en `ESTRUCTURA.md` (`9ce524c`) como el criterio que sigue el código |
| A4 | Baja | **Estilo de los nombres de documentos:** MAYÚSCULAS (`ESTRUCTURA.md`, `XTERM_DART.md`, `DESIGN.md`), kebab-case (20 archivos) e `Informe_auditoria_*` | Decisión del autor |
| A5 | Info | `iroh_tunnel.py` vive fuera de las capas y `pairing_service` lo importa. Está documentado en `ESTRUCTURA.md` | Sin acción |
| A6 | Baja | El `applicationId` de Android (`io.github.alexxio070.sysmote`) contiene el usuario de GitHub. La app aún no está publicada, así que cambiarlo ahora no rompe actualizaciones | Decisión del autor, antes de publicar un APK nuevo |

### 6.2 Legibilidad y orden del código

| # | Gravedad | Hallazgo | Estado |
|---|---|---|---|
| B1 | Media | **No había formateador.** En Dart, `dart format` cambiaba 98 de 121 archivos con el ancho por defecto y 60 con 100 columnas (el código está escrito hacia las 100: percentil 99 en 94 columnas). En Python tampoco hay formateador: 65 líneas pasan de 100 columnas y 3 de 120 | **Dart corregido** en `7002826` (`page_width: 100` en `analysis_options.yaml` y un solo commit de formato, con el diff pequeño: +390 −434). **Python pendiente:** hace falta elegir y ejecutar un formateador, y `ruff` no pudo ejecutarse (ver §8) |
| B2 | Baja | `auth_viewmodel.dart` (331 líneas) y `auth_service.py` (313) son los archivos más grandes y concentran el flujo de login | Sin acción; vigilarlos |

**Lo que está bien:** ningún import sin uso; solo 8 funciones públicas sin referencias, y son los manejadores de rutas de FastAPI, que se registran por decorador; ninguna duplicación real (los bloques repetidos de Dart son la estructura normal de un widget); sin código comentado ni `print`.

### 6.3 Comentarios y documentación

**Cobertura, después de las correcciones:**
- **Python:** módulos 37/37, clases 23/23 y funciones públicas 96/96. Todas las secciones `Args:` coinciden con los parámetros reales.
- **Dart:** cabecera en los 121 archivos de `lib/` y `test/`, y `///` en las 176 declaraciones públicas. `dart doc` termina con 0 avisos y 0 errores.
- **Importar los 44 módulos del agente** no falla, no imprime nada y no crea archivos, que es lo que necesita cualquier generador de documentación.

**Coherencia:** sin comentarios en inglés (salvo los de las plantillas de Flutter en `build.gradle.kts` y el manifiesto), sin código comentado y sin emojis en el código fuente.

| # | Gravedad | Hallazgo | Estado |
|---|---|---|---|
| C1 | Baja | Dos docstrings de Python y 13 `///` de Dart sin escribir (nueve constantes de color, `AppTokensContext`, `IrohConnector` y dos mensajes de `settings.dart`) | **Corregido** en `7a332bd` |
| C2 | Media | **Capturas desfasadas.** Todas eran del 16/11. `tui-emparejamiento.png` era anterior al QR de la fase 3 (no mostraba la línea de ayuda del QR de la pestaña Dispositivo) | **TUI corregida** en `fc10d41`, regenerada con el propio Textual y una base de datos vacía. **Pendientes las cuatro de la app:** necesitan un móvil o un emulador. Tienen entre 2 y 5 commits posteriores en sus pantallas, casi todos refactors, y no he comprobado si cambió algo visible |
| C3 | Baja | **Enlace roto en la bibliografía:** `05` citaba `https://www.uvicorn.org/`, que ya no responde | **Corregido** en `9ce524c`: ahora cita `https://uvicorn.dev/` |
| C4 | Baja | **«TLS 1.3» en `02` §5.** Comprobado en vivo: el servidor acepta TLS 1.2 y 1.3. Forzar la 1.3 podría dejar fuera a los Android más antiguos que el proyecto admite (según mi conocimiento, la 1.3 llega por defecto con Android 10; no verificado) | **Corregido** en `9ce524c`: el texto dice que se aceptan las dos |
| C5 | Info | 72 emojis en `04`, `05` y `06` (iconos de estado y leyenda de dificultad). Tu norma de «sin emojis» se refiere al código, donde hay cero | Decisión del autor |

### 6.4 Seguridad: revisión del flujo de login (lectura de código, no pruebas de intrusión)

**Lo que está bien:** Argon2 con los parámetros por defecto de `argon2-cffi`; tokens de 32 bytes aleatorios guardados solo como hash SHA-256; códigos de registro de 16 caracteres base32 (80 bits), de un solo uso y con caducidad; certificado EC P-256 con la clave en modo `0600`; huella fijada en la app con almacén de confianza vacío; límite de intentos por cuenta; sesión única con confirmación en la TUI; `/docs` cerrado; base de datos y claves con permisos `0600`.

| # | Gravedad | Hallazgo | Estado |
|---|---|---|---|
| D1 | Baja | **Cualquiera que alcance el puerto puede bloquear al dueño.** El límite es por cuenta (decisión razonada en el contrato: por iroh todas las conexiones llegan desde `127.0.0.1`), así que cinco fallos seguidos bloquean el login legítimo 10 minutos. Estaba en el contrato, pero no en «Limitaciones conocidas» | **Documentado** en los dos README (`9ce524c`) |
| D2 | Baja | **Diferencia de tiempo en el login.** Si el usuario no existía no se ejecutaba Argon2, así que la respuesta era más rápida y permitía saber si un nombre de usuario existe | **Corregido** en `6625198`: se ejecuta Argon2 contra un hash de relleno. Test nuevo, que falla con el código anterior |
| D3 | Baja | **El registro no era atómico.** Dos peticiones simultáneas con un código válido podían crear dos cuentas, porque solo `nombre_usuario` era `UNIQUE` (deducido de la lectura, no reproducido) | **Corregido** en `6625198`: un índice único en el esquema limita la base de datos a una cuenta, y `registrar` convierte el rechazo en `registro_cerrado`. Dos tests nuevos, que fallan con el código anterior |
| D4 | Info | El HTTP interno (`127.0.0.1:8444`) no tiene TLS: cualquier proceso local alcanza la API, aunque sigue necesitando un token. Es el diseño del túnel iroh | Sin acción |
| D5 | Info | `/estado` es público y dice si hay cuenta, si el registro está abierto y si hay sesión. Es necesario para que la app sepa qué pantalla mostrar | Sin acción |

El segundo y el tercero se probaron con tests que **fallan contra el código anterior**: se ejecutaron sobre una copia del último commit para comprobarlo. Al limitar la base de datos a una cuenta dejó de tener sentido `test_sesion_repository.py` (comprobaba el filtro por usuario con dos cuentas), y se eliminó con su fila en `doc/agente/tests.md`.

### 6.5 Dependencias

| # | Gravedad | Hallazgo | Estado |
|---|---|---|---|
| E1 | Baja | **Aviso `GHSA-mf5v-w3w3-f6cg`** en `opentelemetry-api 1.45.1`, que traen `fastapi` y `starlette`: denegación de servicio por análisis lento de la cabecera `traceparent`, de gravedad baja (impacto solo en disponibilidad), publicado el 13/11/2026 y corregido en 1.45.2. Si la API del agente lo usa de verdad no está verificado | No se puede cerrar desde el repositorio: es una dependencia transitiva y no está fijada. Una instalación nueva resuelve la última versión disponible (deducido); en el entorno de desarrollo basta `pip install -U opentelemetry-api` |
| E2 | Baja | Las dependencias de Python tienen solo cota mínima (`>=`) y no hay archivo de bloqueo: dos instalaciones pueden dar versiones distintas. En Dart sí hay `pubspec.lock` | Decisión del autor |

- **Vulnerabilidades:** 132 paquetes (39 de Python y 93 de Dart) consultados en la base pública OSV, enviando solo nombre y versión. Un único aviso, el de arriba; ninguno en Dart.
- **Licencias:** las 12 dependencias directas de Python son permisivas (MIT, BSD o Apache 2.0). El binding `iroh` no declara licencia en PyPI, pero su repositorio (`n0-computer/iroh-ffi`) incluye `LICENSE-APACHE` y `LICENSE-MIT` (comprobado hoy con la API de GitHub). De los 97 paquetes de Dart, 93 se clasificaron por su archivo `LICENSE` (heurística: 74 BSD, 12 MIT y 7 Apache 2.0) y 4 son del SDK de Flutter. Ninguno con copyleft. Son compatibles con `GPL-3.0-only`.

### 6.6 Configuración de Android

- **Manifiesto:** solo el permiso de Internet; sin tráfico en claro.
- **Gradle:** el NDK `29.0.14206865` coincide con el README; la versión mínima es Android 7 (API 24).
- **Firma:** el APK de release se firma con la clave de depuración, tal como declara el README y el `TODO` de `build.gradle.kts`.
- **Copia de seguridad:** `allowBackup` no está definido y vale por defecto. Es un endurecimiento opcional y no he comprobado si es explotable, porque el token está en el almacenamiento seguro de Android. Si se desactiva, una reinstalación pierde los ajustes de conexión. **Decisión del autor.**

### 6.7 Documentos generales y enlaces

- **`05` y `06`:** leídos por estructura y encabezados, no línea a línea. Están bien organizados. Sus referencias cruzadas con el resto de documentos son válidas (124 de 124 en todo el repositorio).
- **Enlaces externos:** 46 comprobados, 45 respondían; el único roto era el de uvicorn (C3).

---

## 7. Lo que se comprobó y está bien

- **Documentación:** 0 enlaces relativos rotos, 0 nombres antiguos del proyecto y ninguna referencia a funciones eliminadas fuera de los históricos. Las cifras de tests de `doc/agente/tests.md` (155) y `doc/ui/tests.md` (220) coinciden archivo por archivo con los tests reales.
- **Contrato frente a código:** las 8 rutas del contrato existen en el agente y las usa la app (salvo `/capacidades`). Los códigos de error coinciden.
- **Versiones:** `iroh`, `iroh_flutter`, `argon2-cffi` y `cryptography` citadas en `02` coinciden con lo declarado. El NDK del README, el mínimo de Android y Dart `^3.13.4` también.
- **README en español e inglés:** dicen lo mismo en los datos clave.
- **Secretos y datos personales:** en los 411 commits alcanzables en el momento del análisis, desde cualquier rama o etiqueta, no hay claves privadas, tokens de GitHub, claves de API, `Bearer` largos, correos personales ni rutas con el usuario. Las únicas coincidencias son contraseñas de prueba de los tests, direcciones de ejemplo (`192.168.1.x`, `10.0.2.2`) y hashes de `pubspec.lock` o de prueba. No hay ninguna huella ni identificador iroh reales. Todos los commits usan el correo `noreply` de GitHub.
- **Guía de instalación**, ejecutada en carpetas limpias:
  - el entorno virtual se crea y el agente se instala; 153 tests pasaron desde esa instalación, con Python 3.14 y con 3.11 (antes de las últimas correcciones);
  - `sysmote` arranca los servidores HTTPS (8443) e interno (8444): `/metrics` pide sesión (401), `/docs` y `/openapi.json` están cerrados (404), el HTTP plano no entra por el puerto HTTPS y la base de datos y las claves nacen con permisos `0600`;
  - la ruta `pipx` funciona tras la corrección;
  - el APK de release se compila (26,1 MB).
- **Seguridad de la app:** el cliente de la huella del certificado empieza con un almacén de confianza vacío, rechaza una huella vacía y compara el SHA-256 del DER. El manifiesto solo pide el permiso de Internet y no permite tráfico en claro.

---

## 8. Lo que no se ha podido verificar

- **`ruff`, `vulture` y `pip-audit`:** intenté ejecutar `ruff` y `vulture` con `uvx` y el clasificador del modo automático lo denegó. No lo rodeé: los sustituí por comprobaciones propias con la biblioteca estándar (imports sin uso, código sin referencias, docstrings, duplicación). Para las vulnerabilidades consulté directamente la base OSV.
- **`pdoc`:** no se ha generado la documentación HTML del agente. Sí se comprobó que los docstrings siguen un estilo uniforme y que el paquete se importa sin efectos secundarios.
- **Cobertura de código del agente:** no se ha medido (necesita una herramienta que no está instalada).
- **Python 3.11 con las últimas correcciones:** los 155 tests se ejecutaron en 3.14. Las correcciones no usan nada posterior a 3.11, pero no se han vuelto a pasar en esa versión.
- El móvil físico, `adb reverse` y el escáner de QR (que aún no existe), y la conexión por iroh con el login y a través de los relés reales. Lo que sí se vio es que el agente levanta el túnel al arrancar.
- Los detalles de `GPL-3.0-only` frente a `or-later` en las páginas de GNU, que devolvieron un límite de peticiones. La explicación se tomó del texto de la propia licencia (`LICENSE`, §14). Tampoco es asesoramiento legal.
- La cobertura de código de los informes de interfaz (89,2 %), que no se ha vuelto a medir. Rendimiento y accesibilidad quedan fuera de alcance.

---

## 9. Decisiones del autor registradas durante la revisión

- Los informes de las auditorías van en `doc/auditoria/<fecha>/` con el nombre `Informe_auditoria_*`.
- Licencia: `GPL-3.0-only`.
- El agente se publica como paquete de Python en PyPI (`pip`, `pipx install sysmote`). Los paquetes nativos de las distribuciones quedan como trabajo futuro, como ya decía `02` §7.2.
- Al limpiar el historial, todos los commits se unifican bajo el nombre real del autor. Hoy aparecen tres variantes (`Alexxio`, `Alexxio070` y el nombre completo en 13 commits).

---

## 10. Commits de esta revisión sobre las tres ramas

| Commit | Qué hace |
|---|---|
| `c40251c`, `0662951`, `a073b77` | Merges de las auditorías del agente, de iroh y de la interfaz |
| `cfb903f` | Corrige el import del test de la conexión iroh |
| `6e71ff1` | Corrige la ruta de la clave iroh en `doc/iroh/` |
| `1e3a9fb`, `08b2391` | Mueven los informes a `doc/auditoria/2026-11-19/` y los renombran |
| `1a2a2c5` | Alinea `07`, el contrato, los README y `CONTRIBUTING.md` con el código |
| `d5a29f2` | Declara la licencia y fija el ámbito de los fixtures de `pytest-asyncio` |
| `7c5142f` | Incluye `schema.sql` en el paquete del agente |
| `f48c9ef` | Primera versión de este informe |
| `6625198` | Igual tiempo de login con usuario inexistente y una sola cuenta en la base de datos (D2 y D3) |
| `5f9c76f` | Mueve `AppTopBar` a `core/widgets/` (A1) |
| `7a332bd` | Documenta las constantes, el typedef y las funciones internas que faltaban (C1) |
| `9ce524c` | Corrige la URL de uvicorn, el texto de TLS y documenta el bloqueo por intentos y los criterios de estructura (A1, A3, C3, C4 y D1) |
| `7002826` | Formatea el código Dart a 100 columnas y lo fija en `analysis_options.yaml` (B1) |
| `fc10d41` | Regenera la captura de la TUI de emparejamiento (C2) |

Autoría de todos: la del autor del proyecto, sin `Co-Authored-By`.

---

## 11. Pendiente

**Decisiones del autor:**
- Convención de nombres de los documentos (A4), identificador de la app de Android (A6), emojis de `04` a `06` (C5), `allowBackup` (§6.6) y un archivo de restricciones para las dependencias de Python (E2).
- Qué formateador usar en Python (B1). Hoy hay 65 líneas de más de 100 columnas.

**Trabajo que queda:**
- Regenerar las cuatro capturas de la app (C2), que necesitan un móvil o un emulador.
- Actualizar `opentelemetry-api` en el entorno de desarrollo (E1).
- Abrir el PR de esta rama hacia `main`.
- Limpieza del historial: reducir commits redundantes y unificar la autoría. Necesita decidir el nivel de compactación y un `push` forzado hecho por el autor.
- Publicar el agente en PyPI. Cuando exista, la guía de instalación del README dirá `pipx install sysmote`.
- Pruebas en un móvil físico, por USB y por iroh, con el login.
