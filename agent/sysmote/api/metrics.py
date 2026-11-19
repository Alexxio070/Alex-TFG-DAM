"""Ruta HTTP de métricas del sistema. Exige sesión: la protección se añade en `main.py`."""

from fastapi import APIRouter

from sysmote.models.metrics import Metrics
from sysmote.services import metrics_service

router = APIRouter()


@router.get("/metrics", response_model=Metrics)
def get_metrics() -> Metrics:
    """Devuelve el uso de CPU, la temperatura, la RAM y las particiones del PC en este momento."""
    return metrics_service.get_metrics()
