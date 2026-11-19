"""Datos de emparejamiento que muestra la TUI: dirección, identificador iroh, URI y código QR."""

import socket
from urllib.parse import urlencode

import qrcode

from sysmote import rutas

# La clave de iroh la crea y la lee `iroh_tunnel.py` (módulo de la sesión de iroh). Se reutiliza
# su función, aunque sea privada, para que la clave se cargue igual en los dos sitios.
from sysmote.iroh_tunnel import _load_or_create_secret_key

PUERTO_HTTPS = 8443
_BLOQUES = {(True, True): "█", (True, False): "▀", (False, True): "▄", (False, False): " "}


def direccion_lan() -> str:
    """Devuelve `ip:8443` con la IP del PC en la red local, o `127.0.0.1` si no hay red.

    Conectar un socket UDP no envía ningún paquete: solo sirve para que el sistema elija la
    interfaz de salida y así saber la IP local.
    """
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as conexion:
        try:
            conexion.connect(("10.254.254.254", 1))
            host = conexion.getsockname()[0]
        except OSError:
            host = "127.0.0.1"
    return f"{host}:{PUERTO_HTTPS}"


def identificador_iroh() -> str:
    """Devuelve el identificador iroh del agente, creando su clave si todavía no existe."""
    return str(_load_or_create_secret_key(rutas.IROH_KEY_PATH).public())


def uri_emparejamiento(direccion: str, huella: str, codigo: str | None = None, iroh: str | None = None) -> str:
    """Construye el URI del QR (contrato, §6): `sysmote://emparejar?v=1&dir=…&huella=…[&iroh=…][&codigo=…]`.

    Sin `codigo` es el QR de volver a emparejar.
    """
    parametros = {"v": 1, "dir": direccion, "huella": huella}
    if iroh:
        parametros["iroh"] = iroh
    if codigo:
        parametros["codigo"] = codigo
    return "sysmote://emparejar?" + urlencode(parametros, safe=":")


def qr_texto(contenido: str) -> str:
    """Dibuja el QR de `contenido` con caracteres de bloque para mostrarlo en la terminal.

    Cada carácter representa dos módulos del QR, uno encima del otro (`▀`, `▄`, `█` o espacio).
    """
    qr = qrcode.QRCode(error_correction=qrcode.constants.ERROR_CORRECT_L, border=2)
    qr.add_data(contenido)
    qr.make(fit=True)
    matriz = qr.get_matrix()
    if len(matriz) % 2:
        matriz.append([False] * len(matriz[0]))
    filas = zip(matriz[::2], matriz[1::2])
    return "\n".join("".join(_BLOQUES[par] for par in zip(arriba, abajo)) for arriba, abajo in filas)
