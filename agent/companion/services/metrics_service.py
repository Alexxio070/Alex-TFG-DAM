"""Compone la respuesta de métricas a partir del repositorio."""

from companion.models.metrics import Metrics
from companion.repositories import metrics_repository


def get_metrics() -> Metrics:
    ram_used_gb, ram_total_gb = metrics_repository.read_ram_gb()
    return Metrics(
        cpu_percent=metrics_repository.read_cpu_percent(),
        cpu_temp_c=metrics_repository.read_cpu_temp_c(),
        ram_used_gb=ram_used_gb,
        ram_total_gb=ram_total_gb,
        partitions=metrics_repository.read_partitions(),
    )
