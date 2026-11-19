# Documentación de iroh

Todo lo específico de la conexión remota P2P con **iroh** (fase 2, `../documentos-generales-del-proyecto/04-plan-de-fases.md`): qué es, cómo se ha implementado, qué problemas dio y cómo se solucionaron, y qué pruebas hay.

**Estado:** fase 2 cerrada (12/11/2026). Integrado en la app real (modo iroh de Ajustes) y probado, incluida una red restrictiva real. Matriz de pruebas completa en `04-pruebas.md`. El túnel se endureció el 18/11/2026 (límites de conexiones, *streams* e inactividad; ver `03-problemas-y-soluciones.md` §13).

## Documentos de esta carpeta

| Documento | Contenido |
|---|---|
| [`01-que-es-y-como-funciona.md`](01-que-es-y-como-funciona.md) | Qué es iroh, conceptos básicos (`Endpoint`, `EndpointId`, `Connection`, ALPN, relé), cómo se establece una conexión y el patrón *dumbpipe* usado en Sysmote |
| [`02-implementacion.md`](02-implementacion.md) | El túnel del agente (`iroh_tunnel.py`) y quién lo arranca, la conexión iroh compartida de la app (`IrohConnection`) y sus repositorios, cómo se elige el modo de conexión, y requisitos de compilación en Android |
| [`03-problemas-y-soluciones.md`](03-problemas-y-soluciones.md) | Los fallos reales encontrados (incluidos dos que no eran de iroh: `shared_preferences` y un desbordamiento visual) y cómo se arreglaron |
| [`04-pruebas.md`](04-pruebas.md) | Qué cubre cada test automático, y la matriz de pruebas manuales de la fase 2 |

## Dónde está el resto sobre iroh

Para no duplicar, estas cosas siguen en los documentos generales:

| Tema | Dónde |
|---|---|
| Por qué se eligió iroh y qué alternativas se descartaron | `02-necesidades-tecnologicas.md` §3.3, §4.2 |
| Cómo usarlo desde Flutter (decidido: `iroh_flutter`) | `07-resumen-decisiones-y-contexto.md` §3.1 y `02-necesidades-tecnologicas.md` §4.2 |
| Diseño del túnel transparente (visión general) | `01-memoria-tecnica.md` §4.4 |
| Objetivos y «Terminada cuando» de la fase 2 | `04-plan-de-fases.md` |

(Rutas relativas a `../documentos-generales-del-proyecto/`.)

## Por hacer

- Medir a mano las fugas de recursos nativos de iroh en el móvil (procedimiento en `04-pruebas.md`, «Limitaciones conocidas»).
- Servicio systemd que mantenga el túnel en marcha sin abrir la TUI (fase 5); hoy lo arranca la TUI (`sysmote.server.Servidores`).
- Decidir si vale la pena montar un `Endpoint` iroh real dentro del entorno de test de Flutter: hoy la lógica de `IrohConnection` se prueba con una conexión falsa, y la conexión iroh real solo está probada a mano (ver `04-pruebas.md` §0).
