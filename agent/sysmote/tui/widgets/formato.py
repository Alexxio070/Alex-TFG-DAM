from datetime import datetime

ETIQUETAS_SERVIDORES = {"https": "HTTPS (USB/LAN)", "interno": "HTTP interno", "iroh": "iroh"}


def fecha_local(iso: str) -> str:
    return datetime.fromisoformat(iso).astimezone().strftime("%d/%m/%Y %H:%M:%S")


def hora_local(iso: str) -> str:
    return datetime.fromisoformat(iso).astimezone().strftime("%H:%M:%S")
