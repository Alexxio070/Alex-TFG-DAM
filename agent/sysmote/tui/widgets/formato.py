from datetime import UTC, datetime


def fecha_local(iso: str) -> str:
    return datetime.fromisoformat(iso).astimezone().strftime("%d/%m/%Y %H:%M:%S")


def hora_local(iso: str) -> str:
    return datetime.fromisoformat(iso).astimezone().strftime("%H:%M:%S")


def codigo_vigente(app) -> tuple[str, str] | None:
    abierto = app.registro_abierto
    if abierto and abierto[1] > datetime.now(UTC).isoformat():
        return abierto
    return None
