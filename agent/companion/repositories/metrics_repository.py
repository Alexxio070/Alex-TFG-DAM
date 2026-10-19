"""Lee las métricas del sistema con psutil."""

import psutil

GB = 1024**3

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


def read_partitions() -> list[dict]:
    partitions = []
    for part in psutil.disk_partitions():
        if not part.device.startswith("/dev/"):
            continue  # descarta tmpfs, overlay, snap y similares
        try:
            usage = psutil.disk_usage(part.mountpoint)
        except OSError:
            continue  # montaje sin permiso de lectura o no disponible
        partitions.append(
            {
                "id": part.mountpoint,
                "mount": part.mountpoint,
                "device": part.device,
                "used_gb": usage.used / GB,
                "total_gb": usage.total / GB,
            }
        )
    return partitions
