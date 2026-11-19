# Informe de la auditoría final: integración y revisión global

- **Fecha:** 19/11/2026
- **Rama:** `refactor/auditoria-integracion`, cortada de `main` en `c7e1d9c`
- **Quién:** la sesión de gestión del proyecto
- **Objetivo:** comprobar el trabajo de las tres auditorías (agente, iroh e interfaz), reunirlo en una sola rama y buscar lo que se hubiera escapado en el código y en la documentación antes de abrir el PR hacia `main`. No añade funciones ni cambia el comportamiento de la API.

Los otros tres informes de esta carpeta son los de cada sesión: `Informe_auditoria_backend.md`, `Informe_auditoria_iroh.md` e `Informe_auditoria_interfaz.md`.

---

## 1. Resumen

| | Resultado |
|---|---|
| Tests del agente (suite completa) | **153 pasan**, con Python 3.14 y con Python 3.11 |
| Tests de la app | **220 pasan** |
| `flutter analyze` | sin avisos |
| APK de release compilado desde una copia limpia, como dice el README | 26,1 MB, en unos 2 minutos |
| Fallos encontrados en el código de las tres auditorías | ninguno |
| Fallos encontrados fuera de ellas | 1 de gravedad alta (la instalación con `pipx`), corregido |
| Incoherencias de documentación | 5, corregidas |
| Secretos o datos personales en el historial | ninguno (ver §5) |

---

## 2. Qué se hizo

1. **Lectura de los diffs completos** de las tres ramas, sin contar sus informes: iroh (17 archivos), agente (52) e interfaz (123). En interfaz, unos 85 archivos solo ganan comentarios o cabeceras y se revisaron aparte de los 40 que tocan código (28 en `lib/` y 12 en `test/`), que se leyeron enteros.
2. **Integración** en una rama nueva, con merges en este orden: agente, iroh, interfaz. Cada merge conserva los commits de la sesión; no se reescribe nada.
3. **Comprobaciones automáticas** sobre toda la rama (en el repositorio no hay ningún script nuevo, eran temporales): enlaces relativos de todos los documentos Markdown, rutas y nombres citados entre comillas frente al código, nombres antiguos del proyecto, marcas `TODO`, versiones declaradas frente a las citadas, rutas y códigos de error del contrato frente al agente y la app, y cifras de tests frente a los tests reales.
4. **Búsqueda de secretos y datos personales** en todo el historial.
5. **Ejecución real de la guía de instalación** en carpetas limpias y con un `HOME` temporal, sin tocar la configuración del usuario.

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

Cinco conflictos de texto, resueltos a mano: `pairing_service.py`, `doc/agente/ESTRUCTURA.md`, `doc/agente/tests.md`, `doc/ui/tests.md` y `iroh_metrics_repository_test.dart`.

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
| 2 | Media | `07` decía que hasta la fase 9 la cuenta se crea en la TUI y que el QR llega en la fase 9. Contradecía `01` §5.1 y el contrato: la cuenta la crea la app con un código, y el QR se muestra desde la fase 3 | Corregido en `1a2a2c5` |
| 3 | Media | La tabla de errores del contrato omitía `404 no_encontrado` y `405 metodo_no_permitido`, y `solicitud_desconocida` solo aparecía aparte | Corregido en `1a2a2c5` |
| 4 | Baja | `huella_distinta` figuraba como un error del agente, pero es un error de la app y solo existe como mensaje de texto | Corregido en `1a2a2c5` |
| 5 | Baja | Los README no listaban `doc/auditoria/` y omitían `/login/solicitud/{id}` entre las rutas que responden sin sesión | Corregido en `1a2a2c5` |
| 6 | Baja | `CONTRIBUTING.md` describía una rama `feature/<nombre>` por tarea, que ya no es el flujo real | Corregido en `1a2a2c5` |
| 7 | Baja | `pyproject.toml` no declaraba la licencia y `pytest-asyncio` avisaba de que faltaba fijar el ámbito de los fixtures | Corregido en `d5a29f2` |
| 8 | Baja | Android: `allowBackup` no está definido y vale por defecto. Es un endurecimiento opcional; no se ha comprobado si es explotable | Sin corregir |
| 9 | Baja | Los `CLAUDE.md` locales, que no están en el repositorio, aún dicen que el agente no tiene `schema.sql` | Fuera del repositorio, sin corregir |
| 10 | Informativo | La app no llama todavía a `/capacidades`, aunque el agente y el contrato la tienen | Sin acción |
| 11 | Informativo | Tres `TODO` en la TUI, ya documentados en `tui.md`, y el aviso de firma de la release del `build.gradle.kts`, que el README ya declara | Sin acción |

---

## 6. Lo que se comprobó y está bien

- **Documentación:** 0 enlaces relativos rotos, 0 nombres antiguos del proyecto y ninguna referencia a funciones eliminadas fuera de los históricos. Las cifras de tests de `doc/agente/tests.md` (153) y `doc/ui/tests.md` (220) coinciden archivo por archivo con los tests reales.
- **Contrato frente a código:** las 8 rutas del contrato existen en el agente y las usa la app (salvo `/capacidades`). Los códigos de error coinciden.
- **Versiones:** `iroh`, `iroh_flutter`, `argon2-cffi` y `cryptography` citadas en `02` coinciden con lo declarado. El NDK del README (`29.0.14206865`), el mínimo de Android (API 24, Android 7) y Dart `^3.13.4` también.
- **README en español e inglés:** dicen lo mismo en los datos clave.
- **Secretos y datos personales:** en los 411 commits alcanzables en el momento del análisis, desde cualquier rama o etiqueta, no hay claves privadas, tokens de GitHub, claves de API, `Bearer` largos, correos personales ni rutas con el usuario. Las únicas coincidencias son contraseñas de prueba de los tests, direcciones de ejemplo (`192.168.1.x`, `10.0.2.2`) y hashes de `pubspec.lock` o de prueba. No hay ninguna huella ni identificador iroh reales. Todos los commits usan el correo `noreply` de GitHub.
- **Guía de instalación**, ejecutada en carpetas limpias:
  - el entorno virtual se crea y el agente se instala;
  - 153 tests pasan desde esa instalación, con Python 3.14 y con 3.11;
  - `sysmote` arranca los servidores HTTPS (8443) e interno (8444): `/metrics` pide sesión (401), `/docs` y `/openapi.json` están cerrados (404), el HTTP plano no entra por el puerto HTTPS y la base de datos y las claves nacen con permisos `0600`;
  - la ruta `pipx` funciona tras la corrección;
  - el APK de release se compila (26,1 MB).
- **Seguridad de la app:** el cliente de la huella del certificado empieza con un almacén de confianza vacío, rechaza una huella vacía y compara el SHA-256 del DER. El manifiesto solo pide el permiso de Internet y no permite tráfico en claro.

---

## 7. Lo que no se ha podido verificar

- El móvil físico, `adb reverse` y el escáner de QR (que aún no existe).
- La conexión por iroh con el login y a través de los relés reales. Lo que sí se vio es que el agente levanta el túnel al arrancar.
- Las licencias de las dependencias y su compatibilidad con la GPL. No se han revisado.
- Los detalles de `GPL-3.0-only` frente a `or-later` en las páginas de GNU: devolvieron un límite de peticiones. La explicación se tomó del texto de la propia licencia (`LICENSE`, §14).
- La cobertura de código de los informes de interfaz (89,2 %), que no se ha vuelto a medir.

---

## 8. Decisiones del autor registradas durante la revisión

- Los informes de las auditorías van en `doc/auditoria/<fecha>/` con el nombre `Informe_auditoria_*`.
- Licencia: `GPL-3.0-only`.
- El agente se publica como paquete de Python en PyPI (`pip`, `pipx install sysmote`). Los paquetes nativos de las distribuciones quedan como trabajo futuro, como ya decía `02` §7.2.
- Al limpiar el historial, todos los commits se unifican bajo el nombre real del autor. Hoy aparecen tres variantes (`Alexxio`, `Alexxio070` y el nombre completo en 13 commits).

---

## 9. Commits de esta revisión sobre las tres ramas

| Commit | Qué hace |
|---|---|
| `c40251c`, `0662951`, `a073b77` | Merges de las auditorías del agente, de iroh y de la interfaz |
| `cfb903f` | Corrige el import del test de la conexión iroh |
| `6e71ff1` | Corrige la ruta de la clave iroh en `doc/iroh/` |
| `1e3a9fb`, `08b2391` | Mueven los informes a `doc/auditoria/2026-11-19/` y los renombran |
| `1a2a2c5` | Alinea `07`, el contrato, los README y `CONTRIBUTING.md` con el código |
| `d5a29f2` | Declara la licencia y fija el ámbito de los fixtures de `pytest-asyncio` |
| `7c5142f` | Incluye `schema.sql` en el paquete del agente |

Autoría de todos: la del autor del proyecto, sin `Co-Authored-By`.

---

## 10. Pendiente

- Abrir el PR de esta rama hacia `main`.
- Limpieza del historial (reducir commits redundantes y unificar la autoría). Necesita decidir el nivel de compactación y un `push` forzado hecho por el autor.
- Publicar el agente en PyPI. Cuando exista, la guía de instalación del README dirá `pipx install sysmote`.
- Pruebas en un móvil físico, por USB y por iroh, con el login.
- Los hallazgos 8 y 9 de §5, si se quieren atender.
