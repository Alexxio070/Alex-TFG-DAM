# Visión general del proyecto

Descripción del proyecto en lenguaje llano, sin tecnicismos: qué es, cómo funciona cada parte por dentro y cómo se relaciona con los requisitos del título y con lo aprendido en el ciclo. Pensado para el tribunal, los evaluadores y para el propio autor, como complemento a `01-memoria-tecnica.md` (que sí entra en el detalle técnico: arquitectura, API, base de datos, código).

---

## 1. Qué es el proyecto

**Linux System Companion** es una aplicación para controlar y vigilar un PC con Linux desde el móvil, cuando no se está delante de él: fuera de casa, en otra habitación o simplemente sin querer sentarse al ordenador.

El sistema tiene dos partes que se instalan por separado y se hablan entre ellas:

- **Una app para el móvil Android**, que es lo que el usuario ve y toca.
- **Un programa que se instala en el PC** (el «agente»), que se queda escuchando en segundo plano y es quien realmente hace el trabajo: abre terminales, lee el estado del sistema, ejecuta comandos y guarda los datos.

La app nunca accede al PC directamente: siempre pide las cosas al agente, y es el agente quien las hace y le devuelve el resultado.

**Qué se puede hacer con ella:**
- usar una terminal real del PC desde el móvil, como si se estuviera delante;
- ver en vivo cómo va el PC (uso de CPU, temperatura, memoria, disco);
- apagar, reiniciar, suspender o bloquear el PC en remoto;
- ver y cerrar programas que se han quedado colgados;
- guardar comandos frecuentes como botones de un toque (por ejemplo, «actualizar el sistema» o «hacer una copia de seguridad»);
- dejar notas de texto o enlaces compartidos entre el móvil y el PC;
- recibir en el móvil un aviso cuando pase algo en el PC (un proceso largo termina, la CPU se calienta demasiado…).

**Por qué funciona desde cualquier sitio sin configurar nada en el router:** el móvil y el PC se encuentran a través de un servicio intermediario de terceros (no un servidor propio) que les ayuda a establecer una conexión directa y cifrada entre ellos, sin que el usuario tenga que abrir puertos ni instalar una VPN. En casa, en la misma red Wi-Fi, la conexión es directa.

**Por qué tiene sentido como proyecto:** ninguna herramienta existente cubre esto completo. Hay apps para mirar el PC solo cuando se está cerca (en la misma red), y hay apps de terminal remota que exigen abrir el PC a Internet a mano. Esta aplicación junta terminal, monitorización, gestión del PC y avisos en una sola app que funciona igual estés donde estés, sin que el usuario tenga que configurar redes.

---

## 2. Cómo funciona cada parte

### Primera configuración y emparejamiento

Antes de poder usar la app, hay que emparejar el móvil con el PC una vez. Al instalar el agente, este abre en el propio PC una pantalla de texto con botones (sin necesidad de ratón) donde se pulsa "configuración inicial". Esa pantalla muestra un **código QR** en la propia terminal. Se abre la app en el móvil, se escanea ese código con la cámara, y con eso el móvil ya sabe cómo encontrar a ese PC y confía en él. A continuación se crea un usuario y una contraseña para la app, y a partir de ahí los dos dispositivos quedan emparejados: ese PC solo hablará con ese móvil (y con los que se emparejen después de la misma forma).

### Iniciar sesión y seguridad

Una vez emparejados, cada vez que se usa la app hay que iniciar sesión con el usuario y la contraseña creados al emparejar. El PC guarda la contraseña de forma que ni él mismo puede leerla directamente (solo puede comprobar si una contraseña es correcta, no recuperarla). Si alguien intenta adivinar la contraseña a base de probar, el sistema le obliga a esperar cada vez más entre intentos. Y en cualquier momento se puede, desde el propio PC, cerrar la sesión de todos los móviles a la vez, por ejemplo si se pierde el teléfono.

### Terminal remota

Es la función principal del proyecto: usar la shell real del PC (la misma terminal que se usaría sentado delante, con los mismos programas, los mismos atajos y la misma configuración personal) pero escribiendo desde el móvil. La sesión de terminal vive en el PC, no en la conexión del móvil: si se cierra la app, se pierde la cobertura o se guarda el móvil en el bolsillo, lo que se estaba ejecutando sigue corriendo en el PC, y al volver a abrir la app se recupera tal y como estaba, con toda la salida que se haya generado mientras tanto. Esto permite, por ejemplo, lanzar una actualización larga del sistema desde el móvil y no preocuparse de mantener la pantalla encendida.

### Monitorización en vivo

La app muestra en tiempo real cómo está el PC: cuánto está trabajando el procesador, a qué temperatura está, cuánta memoria y espacio en disco queda libre. Los datos se actualizan cada segundo y se ven como gráficas, no solo como números, para poder ver de un vistazo si algo se está disparando.

### Energía y procesos

Desde el móvil se puede apagar, reiniciar, suspender o bloquear el PC, y también ver qué programas están abiertos y cuáles consumen más recursos, para poder cerrarlos si algo se ha quedado colgado. Todas las acciones que podrían causar una pérdida de trabajo (apagar, matar un programa) piden confirmación antes de ejecutarse.

### Acciones rápidas

Son comandos que el usuario guarda de antemano para no tener que escribirlos cada vez: por ejemplo, un botón «Actualizar sistema» que en realidad ejecuta el comando de actualización, o un botón «Copia de seguridad» que lanza un script guardado. Estos botones se organizan como una cuadrícula de iconos en la pantalla de inicio de la app, agrupables en carpetas, y se pueden reordenar arrastrando. Cada vez que se ejecuta una acción se guarda en un historial (si salió bien o mal, cuánto tardó, qué mostró por pantalla), de forma que se puede comprobar más tarde si algo falló mientras no se estaba mirando el móvil.

### Espacio compartido (notas)

Un sitio común entre el móvil y el PC donde dejar notas de texto o enlaces, para pasar información rápida de un lado a otro sin depender de otra app externa: por ejemplo, copiar un enlace interesante en el PC y abrirlo luego en el móvil estando fuera de casa, o dejar desde el móvil un recordatorio de algo que hacer en el PC.

### Notificaciones y reglas de alerta

El PC puede avisar al móvil de dos formas: a mano, mandando una notificación desde cualquier script o programa (por ejemplo, al terminar una compilación larga), o automáticamente, mediante reglas que el propio usuario define («avísame si la CPU pasa del 90 % durante más de 2 minutos»). Los avisos llegan como notificaciones normales de Android, sin depender de ningún servicio de terceros para el envío.

### Cómo se guardan los datos

Todo lo que el sistema necesita recordar (usuarios, acciones guardadas, su historial, reglas de alerta, notas, notificaciones) se guarda en una base de datos sencilla dentro del propio PC, no en ningún servidor externo. Nada de esto sale de los dos dispositivos del usuario salvo lo imprescindible para que se vean entre ellos.

### Cómo se conectan el móvil y el PC

En casa, en la misma red Wi-Fi, el móvil encuentra al PC automáticamente, sin escribir ninguna dirección a mano. Fuera de casa, usan un túnel cifrado de extremo a extremo que les ayuda a encontrarse sin que el usuario tenga que abrir puertos en el router ni instalar una VPN. La app funciona exactamente igual en los dos casos: ni la terminal, ni las métricas, ni ninguna otra pantalla saben ni necesitan saber si la conexión es local o remota.

---

## 3. Cómo se adapta a los requisitos mínimos del proyecto

Según los requisitos mínimos del proyecto final de DAM (apartados generales y los específicos de aplicación móvil):

| Requisito mínimo | Cómo lo cumple el proyecto |
|---|---|
| Tipología: aplicación móvil Android | App Android hecha con Flutter |
| Arquitectura con capas diferenciadas | MVVM en la app (vistas → ViewModels → repositorios → servicios de red); capas en el agente (rutas de la API → servicios → repositorios → modelos) |
| Control de versiones con Git, ramas y commits | Git con rama `main` y una `feature/<nombre>` por tarea o fase, commits convencionales |
| Manual de instalación y ejecución | README del repositorio |
| Interfaz gráfica funcional y usable | Interfaz definitiva de la app, con sus seis pantallas |
| Navegación fluida entre pantallas | Menú lateral (drawer) entre Inicio, Métricas, Terminal, Notas y Ajustes |
| Validaciones en formularios | Validaciones en el login, en el formulario de acciones rápidas y en los ajustes |
| Gestión de usuarios y autenticación (registro/login) | Emparejamiento por QR, login con token de sesión, contraseña con Argon2 |
| CRUD de al menos dos entidades relacionadas | Grupos y acciones rápidas (fase 7); reforzado con reglas de alerta/notificaciones y notas |
| Lógica de negocio (búsquedas, cálculos, filtrado) | Reglas de alerta por umbral, estadísticas de ejecuciones, filtros y orden de procesos |
| Gestión de errores y feedback al usuario | Avisos de conexión con reintento, confirmaciones antes de acciones destructivas, mensajes de error claros |
| Base de datos con mínimo 3-4 tablas y relaciones | 9 tablas relacionadas en `schema.sql` |
| Acceso a datos mediante clases o funciones estructuradas | Patrón repository, una clase por tabla, sin ORM |
| Script de creación o exportación de la base de datos | `schema.sql`, más exportación de datos y estructura desde la TUI |
| Documentación completa (introducción, planificación, tecnologías, BD, pruebas, manual, estado del arte) | `doc/documentos-generales-del-proyecto/` (01-08) |
| Elemento diferenciador — uso de sensores del dispositivo | Cámara para escanear el QR de emparejamiento y registro |
| Elemento diferenciador — notificaciones push o servicios en segundo plano | Servicio en primer plano del móvil con notificaciones locales del PC (sin Firebase: conexión P2P propia con iroh) |
| Elemento diferenciador — integración con Firebase | Descartado a propósito: el proyecto evita servidores de terceros; el P2P con iroh cubre el mismo papel sin depender de Google |

---

## 4. Conocimientos de los módulos formativos aplicados

Resultados de Aprendizaje (RA) según el Real Decreto 405/2023, de 29 de mayo (currículo estatal actualizado del título de Técnico Superior en DAM, Anexo I):

| Módulo profesional | Código | RA vinculado | Componente técnico en Linux System Companion |
|---|---|---|---|
| Sistemas Informáticos | 0483 | RA4, RA5, RA6 | Agente como servicio de usuario de systemd (RA4: cuentas, servicios y procesos); redes locales con mDNS y acceso remoto por iroh (RA5, RA6) |
| Bases de Datos | 0484 | RA2, RA3, RA4, RA6 | Diseño del esquema relacional (`schema.sql`): creación de tablas (RA2), consultas y modificación vía repositorios (RA3, RA4), modelo normalizado con diagrama E/R (RA6) |
| Programación | 0485 | RA2, RA4, RA5, RA9 | Programación orientada a objetos en Python y Dart (RA2, RA4), E/S con ficheros (log de comandos, config TOML) (RA5), integridad de datos en SQLite (RA9) |
| Lenguajes de Marcas | 0373 | RA6, RA7 | Intercambio de información en JSON entre la app y el agente (RA6); exportación de datos y estructura de la BD desde la TUI (RA7) |
| Entornos de Desarrollo | 0487 | RA3, RA4, RA6 | Pruebas automáticas con pytest y flutter_test (RA3); Git, refactorización e integración continua (RA4); diagrama de casos de uso de la memoria (RA6) |
| Acceso a Datos | 0486 | RA1, RA2, RA6 | Acceso a ficheros (log de comandos, configuración) (RA1); conexión a SQLite sin ORM (RA2, explícitamente sin usar la herramienta de mapeo del RA3); componentes de acceso a datos con patrón repository (RA6) |
| Desarrollo de Interfaces | 0488 | RA3, RA4, RA7 | Componentes visuales propios de la app (RA3); diseño con criterios de usabilidad (RA4); distribución del APK en releases (RA7). No aplica RA2 (interfaces naturales por voz/gestos/realidad aumentada): el proyecto no las usa |
| Programación Multimedia y Dispositivos Móviles | 0489 | RA1, RA2 | Tecnologías de desarrollo móvil (Flutter) evaluadas y aplicadas (RA1); app con sensores (cámara para el QR), conexiones HTTP/HTTPS y persistencia (RA2). No aplica RA3-RA5 (contenido multimedia y motores de videojuegos): fuera del alcance |
| Programación de Servicios y Procesos | 0490 | RA1, RA3, RA4, RA5 | Ejecución de acciones rápidas en procesos propios con control de grupo (RA1); socket Unix de `companion notify` (RA3); servicios REST/WebSocket con FastAPI (RA4); TLS, Argon2 y tokens de sesión (RA5) |
| Sistemas de Gestión Empresarial | 0491 | — | Sin aplicación directa: el proyecto no implanta ni adapta sistemas ERP-CRM (herramienta personal de administración de sistemas, no de gestión empresarial) |
| Proyecto de Desarrollo de Aplicaciones Multiplataforma | 0492 | RA1, RA2, RA3, RA4 | Esta memoria técnica (RA1), la planificación por fases (RA2, RA3) y el seguimiento de cambios en `08-historial-de-cambios.md` (RA4) |
