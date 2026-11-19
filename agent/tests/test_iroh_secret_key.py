"""Clave secreta del túnel: fija el identificador iroh del agente y debe ser privada."""

import pytest

from sysmote.iroh_tunnel import load_or_create_secret_key


def test_creates_the_key_with_private_permissions(tmp_path):
    path = tmp_path / "datos" / "clave.bin"

    load_or_create_secret_key(path)

    assert path.stat().st_mode & 0o777 == 0o600


def test_reuses_the_stored_key_so_the_identifier_survives_restarts(tmp_path):
    path = tmp_path / "clave.bin"

    first = load_or_create_secret_key(path)
    second = load_or_create_secret_key(path)

    assert first.public() == second.public()


def test_rejects_a_corrupt_key_file_with_a_clear_message(tmp_path):
    path = tmp_path / "clave.bin"
    path.write_bytes(b"corrupta")

    with pytest.raises(ValueError, match="no es válida"):
        load_or_create_secret_key(path)
