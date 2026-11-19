"""Modelos de respuesta del endpoint de métricas."""

from pydantic import BaseModel


class Partition(BaseModel):
    """Una partición montada, con su uso en GB decimales (1 GB = 1000³ bytes)."""

    id: str
    mount: str
    device: str
    used_gb: float
    total_gb: float


class Metrics(BaseModel):
    """Respuesta de `GET /metrics`. `cpu_temp_c` es `None` si el equipo no expone la temperatura."""

    cpu_percent: float
    cpu_temp_c: float | None
    ram_used_gb: float
    ram_total_gb: float
    partitions: list[Partition]
