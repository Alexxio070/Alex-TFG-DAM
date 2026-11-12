# Documentación de iroh

Todo lo específico de la conexión remota P2P con **iroh** (fase 2, `../documentos-generales-del-proyecto/04-plan-de-fases.md`): qué es, cómo se ha implementado, qué problemas dio y cómo se solucionaron, y qué pruebas hay.

**Estado:** prueba de concepto hecha e integrada en la app real (modo iroh de Ajustes). Matriz de pruebas de la fase 2 casi completa — ver `04-pruebas.md`.

## Documentos de esta carpeta

| Documento | Contenido |
|---|---|
| [`01-que-es-y-como-funciona.md`](01-que-es-y-como-funciona.md) | Qué es iroh, conceptos básicos (`Endpoint`, `EndpointId`, `Connection`, ALPN, relé), cómo se establece una conexión y el patrón *dumbpipe* usado en Sysmote |
| [`02-implementacion.md`](02-implementacion.md) | El túnel del agente (`iroh_tunnel.py`), el repositorio de métricas de la app (`IrohMetricsRepository`), cómo se elige el modo de conexión, y requisitos de compilación en Android |
| [`03-problemas-y-soluciones.md`](03-problemas-y-soluciones.md) | Los fallos reales encontrados (incluidos dos que no eran de iroh: `shared_preferences` y un desbordamiento visual) y cómo se arreglaron |
| [`04-pruebas.md`](04-pruebas.md) | Qué cubre cada test automático, y la matriz de pruebas manuales de la fase 2 |

## Dónde está el resto sobre iroh

Para no duplicar, estas cosas siguen en los documentos generales:

| Tema | Dónde |
|---|---|
| Por qué se eligió iroh y qué alternativas se descartaron | `02-necesidades-tecnologicas.md` §3.3, §4.2 |
| Decisión abierta sobre cómo usarlo desde Flutter (ya resuelta: `iroh_flutter`) | `07-resumen-decisiones-y-contexto.md` §3.1, §3.8 |
| Diseño del túnel transparente (visión general) | `01-memoria-tecnica.md` §4.4 |
| Objetivos y «Terminada cuando» de la fase 2 | `04-plan-de-fases.md` |

(Rutas relativas a `../documentos-generales-del-proyecto/`.)

## Por hacer

- Completar la prueba 5 de la matriz (`04-pruebas.md`) con un reinicio real del PC, no solo del proceso del agente.
- Arranque automático del túnel junto a `sysmote serve` — correctamente aplazado a la fase 5, no es una carencia de esta fase.
- Decidir si vale la pena montar un `Endpoint` iroh real dentro del entorno de test de Flutter para cubrir con tests automáticos lo que hoy solo está probado a mano (ver `04-pruebas.md` §0).
