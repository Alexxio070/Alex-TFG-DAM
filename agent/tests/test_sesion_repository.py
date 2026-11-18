"""Repositorio de sesiones: el caso que el servicio no puede ejercitar porque el agente solo tiene una cuenta."""

from sysmote.repositories import sesion_repository, usuario_repository


def test_revocar_todas_de_usuario_no_toca_las_de_otro(connection):
    alex = usuario_repository.crear(connection, "alex", "hash-falso")
    otro = usuario_repository.crear(connection, "otro", "hash-falso")
    sesion_repository.crear(connection, alex.id, "token-alex", "Pixel 8")
    sesion_repository.crear(connection, otro.id, "token-otro", "iPhone")

    sesion_repository.revocar_todas_de_usuario(connection, alex.id, "cerrar_todas")

    assert sesion_repository.obtener_por_hash_token(connection, "token-alex").revocada is True
    assert sesion_repository.obtener_por_hash_token(connection, "token-otro").revocada is False
