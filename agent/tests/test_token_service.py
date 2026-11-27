"""Tokens de sesión: formato, aleatoriedad, hash y caducidad absoluta a los 7 días."""

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


CREADA = datetime(2026, 12, 1, 10, 0, tzinfo=UTC)


def test_la_caducidad_es_7_dias_despues_de_crearse():
    assert token_service.calcular_caducidad(CREADA) == CREADA + timedelta(days=7)


def test_no_caduca_antes_de_su_caduca_en():
    caduca_en = token_service.calcular_caducidad(CREADA).isoformat()
    un_segundo_antes = CREADA + timedelta(days=7) - timedelta(seconds=1)
    assert token_service.esta_caducada(caduca_en, un_segundo_antes) is False


def test_caduca_al_llegar_su_caduca_en_y_despues():
    caduca_en = token_service.calcular_caducidad(CREADA).isoformat()
    assert token_service.esta_caducada(caduca_en, CREADA + timedelta(days=7)) is True
    assert token_service.esta_caducada(caduca_en, CREADA + timedelta(days=8)) is True
