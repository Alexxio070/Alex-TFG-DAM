"""Hash de contraseñas con Argon2: lo que el resto de tests no comprueba."""

from sysmote.services import password_service


def test_hash_no_contiene_la_contrasena_y_es_argon2():
    hash_contrasena = password_service.hashear("secreta")
    assert "secreta" not in hash_contrasena
    assert hash_contrasena.startswith("$argon2")


def test_verificar_rechaza_un_hash_corrupto():
    assert password_service.verificar("no-es-un-hash", "secreta") is False


def test_dos_hashes_de_la_misma_contrasena_son_distintos():
    assert password_service.hashear("secreta") != password_service.hashear("secreta")
