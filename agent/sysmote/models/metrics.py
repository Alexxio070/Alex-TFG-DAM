"""Modelos de respuesta del endpoint de métricas."""

from pydantic import BaseModel


class Partition(BaseModel):
    id: str
    mount: str
    device: str
    used_gb: float
    total_gb: float


class Metrics(BaseModel):
    cpu_percent: float
    cpu_temp_c: float | None
    ram_used_gb: float
    ram_total_gb: float
    partitions: list[Partition]
