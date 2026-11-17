import re
from datetime import UTC, datetime, timedelta

from sysmote.services import token_service


def test_token_tiene_43_caracteres_base64url():
    assert re.fullmatch(r"[A-Za-z0-9_-]{43}", token_service.generar())


def test_dos_tokens_son_distintos():
    assert token_service.generar() != token_service.generar()


def test_hash_es_sha256_hexadecimal_y_no_contiene_el_token():
    token = token_service.generar()
    hash_token = token_service.hashear(token)
    assert re.fullmatch(r"[0-9a-f]{64}", hash_token)
    assert token not in hash_token


def test_mismo_token_mismo_hash():
    assert token_service.hashear("abc") == token_service.hashear("abc")


def test_no_caduca_con_acceso_reciente():
    hace_29_dias = (datetime.now(UTC) - timedelta(days=29)).isoformat()
    assert token_service.esta_caducada(hace_29_dias) is False


def test_caduca_tras_30_dias_sin_uso():
    hace_31_dias = (datetime.now(UTC) - timedelta(days=31)).isoformat()
    assert token_service.esta_caducada(hace_31_dias) is True
