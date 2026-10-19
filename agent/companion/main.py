"""Punto de entrada del servidor FastAPI del agente."""

from fastapi import FastAPI

from companion.api.metrics import router as metrics_router

app = FastAPI(title="Linux System Companion")
app.include_router(metrics_router)
