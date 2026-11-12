# Índice de funciones y partes del proyecto

Para cada función o parte del proyecto: su estado y todos los documentos donde se habla de ella. Sirve para saber qué tocar al añadir, descartar o aplazar una función.

**Estados:** *en el proyecto* (prevista) · *pendiente de decidir* · *idea futura* (`06`) · *descartada* (`07` §4). Ninguna se da por terminada: el avance por fase está en `04`.

Abreviaturas: `01` [memoria técnica](01-memoria-tecnica.md), `02` [necesidades tecnológicas](02-necesidades-tecnologicas.md), `03` [visión general](03-vision-general-del-proyecto.md), `04` [plan de fases](04-plan-de-fases.md), `06` [ideas de futuro](06-ideas-de-futuro.md), `07` [decisiones](07-resumen-decisiones-y-contexto.md), `08` [historial](08-historial-de-cambios.md).

---

## 1. Funciones

| Función | Estado | Dónde se habla de ella |
|---|---|---|
| **Terminal remota** (sesiones persistentes con tmux) | En el proyecto | `01` §3 Módulo A · `02` §1.2, §2.2, §2.2.1 · `03` §2 «Terminal remota» · `04` fase 4 · `07` §3.3 · [terminal-sesiones-tmux](../agente/terminal-sesiones-tmux.md) · [interfaz-app](../ui/interfaz-app.md) §5 · [XTERM_DART](../ui/XTERM_DART.md) · [ESTRUCTURA agente](../agente/ESTRUCTURA.md) |
| ↳ Pestañas de terminal | En el proyecto | [terminal-sesiones-tmux](../agente/terminal-sesiones-tmux.md) §10 · [interfaz-app](../ui/interfaz-app.md) §5 · `04` fase 4 |
| ↳ Historial de comandos de terminal | En el proyecto | [tui](../agente/tui.md) «Historial de comandos de terminal» · `07` §3.2 |
| **Monitorización** (CPU, temperatura, RAM, discos) | En el proyecto | `01` §3 Módulo B · `02` §2.3 · `03` §2 «Monitorización» · `04` fase 1 · [interfaz-app](../ui/interfaz-app.md) §4 · [ESTRUCTURA agente](../agente/ESTRUCTURA.md) |
| **Procesos** (lista, búsqueda por nombre o PID, finalizar y congelar) | En el proyecto | `01` §3 Módulo D, navegación, §7 · `03` §1 y §2 «Procesos» · `04` fase 6 · `08` entradas del 21/10/2026 |
| **Energía** (apagar, reiniciar, suspender, hibernar, bloquear) | Pendiente de decidir | `07` §3.8 · `01` §3 Módulo C, §10 · `02` §2.4 · `03` §2 «Energía» · `04` fase 6 y demo · `06` §6 (modo sin sesión, biométrico) · [ESTRUCTURA agente](../agente/ESTRUCTURA.md) |
| **Acciones rápidas** (grupos, cuadrícula, historial de ejecuciones) | En el proyecto | `01` §3 Módulo E, §6.2 · `02` §2.5 · `03` §2 · `04` fase 7 · `07` §3.6 · [interfaz-app](../ui/interfaz-app.md) §3 · [ESTRUCTURA agente](../agente/ESTRUCTURA.md) · `06` §8 (avanzadas) |
| **Espacio compartido** (notas de texto y enlaces) | En el proyecto | `01` §3 Módulo F, §6.2 · `03` §2 · `04` fase 9 · `07` §3.5 · [interfaz-app](../ui/interfaz-app.md) §6 · [ui-v2 (histórico)](../ui/historico/ui-v2/DESIGN.md) · [tui](../agente/tui.md) «Notas» · `06` §2 |
| ↳ Imágenes en las notas | Idea futura (aún pensándolo) | `06` §2 · `07` §3.8 |
| **Notificaciones y reglas de alerta** | En el proyecto | `01` §3 Módulo G · `02` §4.1 · `03` §2 · `04` fase 8 · `07` §3.4 · [ESTRUCTURA agente](../agente/ESTRUCTURA.md) · `06` §7 (alertas más completas) |
| ↳ `sysmote notify` | En el proyecto | `01` §3 Módulo G, §8.1 · `02` §2.6 |
| ↳ Servicio en primer plano de Android | En el proyecto (tipo por decidir) | `01` §3 Módulo G · `02` §4.1 · `04` fase 8 · `07` §3.8 |
| **Descubrimiento en red local** (mDNS) | En el proyecto | `01` §3 Módulo H, §10 · `02` §3.2 · `04` fase 9 y recortes |
| **Acceso remoto P2P** (iroh) | En el proyecto | `01` §4.4, §10 · `02` §3.3, §4.2 · `03` §2 «Cómo se conectan» · `04` fase 2 · `07` §3.1, §3.8 · `06` §6 (relé propio) |
| **Emparejamiento y registro por QR** | En el proyecto | `01` §5.1 · `03` §2 «Primera configuración» · `04` fases 3 y 9 · [tui](../agente/tui.md) «Emparejamiento» · `07` §3.2 |
| **Login, sesiones y seguridad** (TLS, Argon2, tokens, límite de intentos) | En el proyecto | `01` §5.2, §5.3 · `02` §5 · `03` §2 «Iniciar sesión» · `04` fase 3 · `07` §3.2 · `06` §6 (2FA, biométrico) |
| **Ajustes de la app** | En el proyecto | `01` §3 «Navegación y pantallas» · [interfaz-app](../ui/interfaz-app.md) §7 |
| **Exportación de datos y estructura de la BD** | En el proyecto | `01` §6.3 · `04` fase 7 · `07` §3.7 · [tui](../agente/tui.md) «Base de datos» |
| **TUI `sysmote`** (Emparejamiento, Historial, Base de datos, Notas) | En el proyecto | `01` §8.1 · `02` §2.6 · `04` fase 1 · `07` §3.1 · [tui](../agente/tui.md) · [ESTRUCTURA agente](../agente/ESTRUCTURA.md) |

## 2. Partes técnicas

| Parte | Dónde se habla de ella |
|---|---|
| **App Android** (Flutter, MVVM + provider) | `01` §4.2 · `02` §1 · [estructura-app](../ui/estructura-app.md) · [interfaz-app](../ui/interfaz-app.md) |
| **Agente** (FastAPI, capas, servicio systemd de usuario) | `01` §4.2, §8 · `02` §2, §7 · [README agente](../agente/README.md) · [ESTRUCTURA agente](../agente/ESTRUCTURA.md) |
| **API REST y WebSocket** | `01` §3 (resumen de rutas), §4.3 · `02` §3.1 · [terminal-sesiones-tmux](../agente/terminal-sesiones-tmux.md) §3 |
| **Base de datos** (SQLite, `schema.sql`, repositorios) | `01` §6 · `02` §6 · `04` tareas transversales |
| **Instalación y servicio** (pipx, systemd, linger) | `01` §8 · `02` §7 · `04` fase 5 · [README](../../README.md) |
| **Pruebas** | `01` §9.3 · `02` §8.3, §8.4 · `04` entorno de pruebas · [tests del agente](../agente/tests.md) · [tests de la app](../ui/tests.md) |

## 3. Ideas futuras y funciones descartadas

| Elemento | Estado | Dónde |
|---|---|---|
| Multi-dispositivo | Idea futura (pendiente de investigar) | `06` §4 |
| Wake-on-LAN | Descartada (queda como idea) | `07` §4 · `06` §6 |
| «Modo cercanía» (multimedia, volumen, batería, enlaces al PC) | Descartada (queda como idea) | `07` §4 · `06` §1 |
| Explorador y transferencia de archivos | Descartada (queda como idea) | `07` §4 · `06` §2 |
| Alertas con Firebase | Descartada | `07` §4 · `01` §3 Módulo G |
| Temas de terminal | Idea futura («si da tiempo») | `04` resumen · `06` §5 |

## 4. Qué tocar al quitar o aplazar una función

1. Su fila de este índice (estado y, si hace falta, moverla a la tabla 3).
2. `01`: su módulo en §3, las listas de §1 y del valor diferencial de §2, el caso de uso en §7 y la comparativa de §11.
3. `04`: la fase que la contiene (objetivos y «Terminada cuando») y la fila del resumen visual.
4. `03`: su apartado de §2, la lista de §1 y, si cuenta como requisito mínimo, las tablas de §3 y §4.
5. `07`: §4 si se descarta, o §3.8 si pasa a pendiente de decidir.
6. `06` si pasa a idea futura.
7. `08`: una entrada nueva con el cambio (qué era, qué es ahora y por qué).
8. Los documentos específicos de la lista de arriba (`doc/ui/`, `doc/agente/`).
