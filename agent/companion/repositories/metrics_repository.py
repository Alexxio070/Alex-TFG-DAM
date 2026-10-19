import psutil

from companion.models.metrics import Partition

GB = 1000**3

# Nombres de sensor habituales para la temperatura de CPU, por fabricante.
CPU_TEMP_SENSORS = ("k10temp", "coretemp", "cpu_thermal", "zenpower")


def read_cpu_percent() -> float:
    return psutil.cpu_percent(interval=0.1)


def read_cpu_temp_c() -> float | None:
    temps = psutil.sensors_temperatures()
    for sensor_name in CPU_TEMP_SENSORS:
        entries = temps.get(sensor_name)
        if entries:
            return entries[0].current
    return None


def read_ram_gb() -> tuple[float, float]:
    mem = psutil.virtual_memory()
    return mem.used / GB, mem.total / GB


def read_partitions() -> list[Partition]:
    partitions = []
    for part in psutil.disk_partitions():
        if not part.device.startswith("/dev/"):
            continue  # descarta tmpfs, overlay y similares
        if part.fstype == "squashfs" or part.device.startswith("/dev/loop"):
            continue  # descarta los paquetes snap
        try:
            usage = psutil.disk_usage(part.mountpoint)
        except OSError:
            continue  # montaje sin permiso de lectura o no disponible
        partitions.append(
            Partition(
                id=part.mountpoint,
                mount=part.mountpoint,
                device=part.device,
                used_gb=usage.used / GB,
                total_gb=usage.total / GB,
            )
        )
    return _dedupe_by_device(partitions)


def _dedupe_by_device(partitions: list[Partition]) -> list[Partition]:
    """El mismo dispositivo puede montarse en varios puntos (p. ej. subvolúmenes
    btrfs): se queda uno por dispositivo, el del punto de montaje más corto."""
    shortest: dict[str, Partition] = {}
    for partition in partitions:
        current = shortest.get(partition.device)
        if current is None or len(partition.mount) < len(current.mount):
            shortest[partition.device] = partition
    return list(shortest.values())
