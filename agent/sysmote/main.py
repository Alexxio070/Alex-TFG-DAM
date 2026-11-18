"""Punto de entrada del servidor FastAPI del agente."""

from fastapi import FastAPI

from sysmote.api.metrics import router as metrics_router

app = FastAPI(title="Sysmote")
app.include_router(metrics_router)
