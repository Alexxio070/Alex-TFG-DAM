"""Ruta GET /metrics."""

from fastapi import APIRouter

from companion.models.metrics import Metrics
from companion.services import metrics_service

router = APIRouter()


@router.get("/metrics", response_model=Metrics)
def get_metrics() -> Metrics:
    return metrics_service.get_metrics()
