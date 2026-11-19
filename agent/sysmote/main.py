"""Aplicación FastAPI del agente: reúne las rutas y el formato de errores.

Importarla solo construye el objeto `app`; no arranca ningún servidor. Los servidores que la
sirven están en `server.py`.
"""

from fastapi import Depends, FastAPI

from sysmote.api.auth import protegido, publico
from sysmote.api.deps import requiere_sesion
from sysmote.api.errors import registrar_manejadores
from sysmote.api.metrics import router as metrics_router

# Sin /docs ni /openapi.json: el contrato exige sesión en todo lo que no sea público.
app = FastAPI(title="Sysmote", docs_url=None, redoc_url=None, openapi_url=None)
registrar_manejadores(app)
app.include_router(publico)
app.include_router(protegido)
app.include_router(metrics_router, dependencies=[Depends(requiere_sesion)])
