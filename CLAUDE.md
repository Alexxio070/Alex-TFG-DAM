# Linux System Companion (TFG)

TFG de DAM de alex: app Android + agente Python en el PC Linux del usuario para administrar ese PC en remoto desde el móvil (LAN o WAN), sin configurar router ni VPN.

**Alcance de este repo:** solo el trabajo del PROYECTO (el entregable que se presenta al tribunal). El aprendizaje personal (hilos "APRENDIZAJE:") vive en claude.ai, no aquí; su estilo docente no aplica en este repo.

## Regla de confirmación previa (sin automatismos)

Aplica a cualquier sesión de Claude/Claude Code que trabaje en este repo:

1. **Antes de generar o crear nada**, explicar cómo se ha entendido la petición. Decir qué se está suponiendo; si algo es ambiguo o falta un dato, preguntar en vez de rellenarlo.
2. Explicar el **plan de acción**: qué se va a hacer, cómo, con qué y **por qué esa opción y no otra**.
3. **Esperar confirmación explícita antes de ejecutar ninguna acción.** Ninguna decisión es automática.
4. **No crear/generar nada** que no se haya pedido explícitamente; ceñirse literalmente a lo pedido.
5. **No tocar el repositorio salvo que el usuario lo especifique.**
6. Si se crea algo sin que se pidiera, borrarlo en cuanto se detecte.

## Forma de trabajar

- **Cambios quirúrgicos:** dentro de una tarea aprobada, tocar solo lo necesario. No refactorizar, renombrar ni "mejorar" código ajeno a la tarea.
- **Verificado vs. deducido:** comprobar cada dato técnico (versión, API, comportamiento) en la fuente oficial más reciente e indicar su fecha. Si algo no se ha comprobado, decirlo.
- **Pruebas, no afirmaciones:** dar algo por hecho solo con la salida del test o comando que lo demuestra. Ejecutar esas comprobaciones forma parte del plan aprobado.
- **Nunca secretos** (claves, tokens, contraseñas, certificados privados) en código, commits ni logs.

## Calidad del código

- **Simple y que funcione:** la solución más sencilla que cumpla lo pedido. Nada de código complejo o enrevesado si hay una forma directa.
- **Orden y organización:** cada pieza va en su capa (MVVM en la app; capas + patrón repository en el agente). Una función, una responsabilidad. No duplicar lógica que ya existe.
- **Legible:** nombres claros, funciones cortas, seguir el estilo y los nombres que ya hay en el código.
- **Sin código superfluo:** nada de comentarios que repiten lo que dice el código, ni docstrings de relleno, ni emojis. Sin abstracciones, capas o manejo de errores "por si acaso" que la tarea no necesita.

## Stack

**Cliente (Android) — confirmado:**
- Flutter/Dart, arquitectura MVVM + provider
- xterm.dart para la terminal remota
- shared_preferences para persistir los ajustes en el móvil
- Componentes nativos del SO que lo requieran (servicio en primer plano, etc.) se envuelven con *platform channel* a Kotlin; el stack multilenguaje es normal cuando se justifica, no exclusivo de pasar todo a Kotlin

**Agente (PC Linux) — confirmado:**
- Python 3.11+, FastAPI + Uvicorn, asyncio
- Se ejecuta como servicio **systemd de usuario** (nunca root/sudo)
- SQLite con patrón repository, sin ORM (schema.sql)
- dbus-fast para integración con D-Bus/systemd-logind
- psutil para métricas del sistema
- Textual para la TUI `companion`; Typer solo para `companion serve`/`companion notify` (fases posteriores); qrcode para el QR de la TUI
- tmux para las sesiones de terminal (fase 4)
- iroh para el acceso P2P en WAN (NAT traversal, sin Firebase ni VPN)

**Seguridad:**
- TLS con certificate pinning
- Hashing de contraseñas con Argon2
- Tokens de sesión opacos y revocables
- Rate limiting en login
- Deliberadamente sin 2FA ni JWT

## Repo, commits y PRs

- `App-movil/`: cliente Flutter. `agent/`: agente Python (sin `schema.sql` todavía; llega en la fase 3).
- Ramas: `main` (estable) y `feature/<nombre>` (una por tarea o fase). Sin `develop`; las etiquetas de versión (`v0.1-beta`, `v0.2`…) solo para publicar el APK en las releases.
- Commits con formato convencional (`feat:`, `fix:`, `docs:`, `test:`, `refactor:`, `build:`, `chore:`, `merge:`), cortos y descriptivos. Nada de cambios enormes de una vez: dividir en piezas pequeñas y lógicas.
- Todo commit y PR se propone a alex **antes** de hacerse, incluida la forma de dividir un cambio grande.
- Autoría siempre de alex, nunca de Claude (salvo indicación expresa para un commit concreto). Motivo: será open source y no debe parecer "vibecodeado".

## Uso de IA, librerías y código de terceros

Usar librerías/paquetes como infraestructura normal está permitido, incluso para una funcionalidad core (p. ej. xterm.dart). No reimplementar nada desde cero solo por evitar "código ajeno". Evitar copiar un fragmento concreto encontrado online sin entenderlo ni adaptarlo al proyecto. El proyecto puede estar asistido por IA siempre que alex entienda y pueda explicar o modificar en directo cualquier parte, también en la defensa del TFG.

## Documentación

La documentación está en [`doc/`](doc/): los documentos generales del proyecto, en `doc/documentos-generales-del-proyecto/`; la interfaz, en `doc/ui/` — referencia vigente: `doc/ui/interfaz-app.md` y `doc/ui/estructura-app.md` (`doc/ui/historico/` son las versiones descartadas); y la documentación específica del agente de Python, en [`doc/agente/`](doc/agente/) (`doc/agente/tui.md` para la TUI). El plan de fases y el calendario, en `04-plan-de-fases.md`; las decisiones tomadas y pendientes, en `07-resumen-decisiones-y-contexto.md`; el historial de cambios de diseño, en `08-historial-de-cambios.md`.
- `01-memoria-tecnica.md`
- `02-necesidades-tecnologicas.md`
- `03-vision-general-del-proyecto.md`
- `04-plan-de-fases.md`
- `05-referencias-y-proyectos.md`
- `06-ideas-de-futuro.md`
- `07-resumen-decisiones-y-contexto.md`
- `08-historial-de-cambios.md`
- `09-indice-de-funciones.md` (qué funciones hay y dónde se documenta cada una)
