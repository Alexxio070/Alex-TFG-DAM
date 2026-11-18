class AuthError(Exception):
    def __init__(self, codigo: str, mensaje: str, **extra):
        super().__init__(mensaje)
        self.codigo = codigo
        self.mensaje = mensaje
        self.extra = extra
