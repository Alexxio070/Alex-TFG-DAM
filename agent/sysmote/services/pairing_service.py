import socket
from urllib.parse import urlencode

import qrcode

PUERTO_HTTPS = 8443
_BLOQUES = {(True, True): "█", (True, False): "▀", (False, True): "▄", (False, False): " "}


def direccion_lan() -> str:
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as conexion:
        try:
            conexion.connect(("10.254.254.254", 1))
            host = conexion.getsockname()[0]
        except OSError:
            host = "127.0.0.1"
    return f"{host}:{PUERTO_HTTPS}"


def uri_emparejamiento(direccion: str, huella: str, codigo: str | None = None, iroh: str | None = None) -> str:
    parametros = {"v": 1, "dir": direccion, "huella": huella}
    if iroh:
        parametros["iroh"] = iroh
    if codigo:
        parametros["codigo"] = codigo
    return "sysmote://emparejar?" + urlencode(parametros, safe=":")


def qr_texto(contenido: str) -> str:
    qr = qrcode.QRCode(error_correction=qrcode.constants.ERROR_CORRECT_L, border=2)
    qr.add_data(contenido)
    qr.make(fit=True)
    matriz = qr.get_matrix()
    if len(matriz) % 2:
        matriz.append([False] * len(matriz[0]))
    filas = zip(matriz[::2], matriz[1::2])
    return "\n".join("".join(_BLOQUES[par] for par in zip(arriba, abajo)) for arriba, abajo in filas)
