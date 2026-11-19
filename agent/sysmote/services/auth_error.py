"""Excepción común de los servicios de seguridad.

Está en su propio módulo para que `auth_service` y `limite_service` puedan usarla sin
importarse el uno al otro.
"""


class AuthError(Exception):
    """Error con el código del contrato (por ejemplo `credenciales_invalidas`) y un mensaje legible.

    Los campos de `extra` (como `motivos` o `espera_s`) se añaden tal cual a la respuesta JSON.
    """

    def __init__(self, codigo: str, mensaje: str, **extra):
        super().__init__(mensaje)
        self.codigo = codigo
        self.mensaje = mensaje
        self.extra = extra
