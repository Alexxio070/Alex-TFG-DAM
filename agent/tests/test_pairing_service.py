"""Datos de emparejamiento: dirección, URI del contrato y QR en texto (comprobado con un lector real)."""

import re
import shutil
import subprocess
from urllib.parse import parse_qs, urlparse

import pytest
import qrcode

from sysmote.services import pairing_service

HUELLA = "ab" * 32
CODIGO = "K7QX-M2PD-9WTR-4HNB"


def _matriz_desde_texto(texto: str) -> list[list[bool]]:
    matriz = []
    for linea in texto.split("\n"):
        matriz.append([c in "█▀" for c in linea])
        matriz.append([c in "█▄" for c in linea])
    return matriz


def test_direccion_lan_tiene_formato_ip_y_puerto():
    assert re.fullmatch(r"\d+\.\d+\.\d+\.\d+:8443", pairing_service.direccion_lan())


def test_uri_con_codigo_sigue_el_formato_del_contrato():
    uri = pairing_service.uri_emparejamiento("192.168.1.20:8443", HUELLA, codigo=CODIGO)

    assert uri == f"sysmote://emparejar?v=1&dir=192.168.1.20:8443&huella={HUELLA}&codigo={CODIGO}"


def test_uri_sin_codigo_es_el_de_volver_a_emparejar():
    uri = pairing_service.uri_emparejamiento("192.168.1.20:8443", HUELLA)
    assert "codigo" not in parse_qs(urlparse(uri).query)


def test_uri_incluye_iroh_antes_del_codigo_cuando_existe():
    uri = pairing_service.uri_emparejamiento(
        "192.168.1.20:8443", HUELLA, codigo=CODIGO, iroh="abc123"
    )
    assert list(parse_qs(urlparse(uri).query)) == ["v", "dir", "huella", "iroh", "codigo"]


def test_qr_texto_reproduce_exactamente_la_matriz_del_qr():
    uri = pairing_service.uri_emparejamiento("192.168.1.20:8443", HUELLA, codigo=CODIGO)
    qr = qrcode.QRCode(error_correction=qrcode.constants.ERROR_CORRECT_L, border=2)
    qr.add_data(uri)
    qr.make(fit=True)
    esperada = qr.get_matrix()

    obtenida = _matriz_desde_texto(pairing_service.qr_texto(uri))

    assert obtenida[: len(esperada)] == esperada
    assert all(not any(fila) for fila in obtenida[len(esperada) :])


@pytest.mark.skipif(shutil.which("zbarimg") is None, reason="zbarimg no está instalado")
def test_el_qr_renderizado_se_decodifica_con_un_lector_real(tmp_path):
    uri = pairing_service.uri_emparejamiento("192.168.1.20:8443", HUELLA, codigo=CODIGO)
    matriz = _matriz_desde_texto(pairing_service.qr_texto(uri))
    escala = 6
    ancho = len(matriz[0]) * escala
    filas = []
    for fila in matriz:
        linea = " ".join("1" if oscuro else "0" for oscuro in fila for _ in range(escala))
        filas.extend([linea] * escala)
    imagen = tmp_path / "qr.pbm"
    imagen.write_text(f"P1\n{ancho} {len(filas)}\n" + "\n".join(filas) + "\n")

    salida = subprocess.run(
        ["zbarimg", "--quiet", "--raw", str(imagen)], capture_output=True, text=True, check=False
    )

    assert salida.stdout.strip() == uri
