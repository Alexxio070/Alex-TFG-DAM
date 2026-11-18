# Agente (Python)

Estado: ver [`../doc/documentos-generales-del-proyecto/04-plan-de-fases.md`](../doc/documentos-generales-del-proyecto/04-plan-de-fases.md) (fases 1 y 2 cerradas; la 3, de seguridad, implementada y pendiente de probar en un móvil físico). Diseño completo en [`../doc/agente/`](../doc/agente/).

Instalación, arranque y pruebas: ver el [README raíz](../README.md).

**Seguridad:** el HTTPS escucha en `0.0.0.0:8443` y el HTTP interno solo en `127.0.0.1:8444` (para el túnel iroh). Sin sesión solo responden `/estado`, `/registro` y `/login`; `/docs` y `/openapi.json` están desactivados.
