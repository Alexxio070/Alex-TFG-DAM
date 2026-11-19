"""Los servidores del agente, arrancados de verdad en puertos libres."""

import hashlib
import http.client
import json
import socket
import ssl
import time

import pytest

from sysmote import database
from sysmote.server import Servidores
from sysmote.services import auth_service, tls_service
from sysmote.tui.app import SysmoteApp


def _puerto_libre() -> int:
    with socket.socket() as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


def _esperar_a_que_esten_activos(servidores: Servidores) -> None:
    for _ in range(100):
        if all(estado == "activo" for estado in servidores.estado().values()):
            return
        time.sleep(0.05)
    pytest.fail(f"Los servidores no arrancaron: {servidores.estado()}")


@pytest.fixture
def servidores():
    https, interno = _puerto_libre(), _puerto_libre()
    servidores = Servidores(puerto_https=https, puerto_interno=interno, con_iroh=False)
    servidores.puertos = (https, interno)
    servidores.iniciar()
    yield servidores
    servidores.detener()


def _pedir(puerto: int, metodo: str, ruta: str, https: bool, token: str | None = None, cuerpo: dict | None = None):
    if https:
        conexion = http.client.HTTPSConnection("127.0.0.1", puerto, context=ssl._create_unverified_context())
    else:
        conexion = http.client.HTTPConnection("127.0.0.1", puerto)
    cabeceras = {"Authorization": f"Bearer {token}"} if token else {}
    if cuerpo is not None:
        cabeceras["Content-Type"] = "application/json"
    conexion.request(metodo, ruta, body=json.dumps(cuerpo) if cuerpo is not None else None, headers=cabeceras)
    respuesta = conexion.getresponse()
    datos = respuesta.read()
    conexion.close()
    return respuesta.status, datos


def _get(puerto: int, ruta: str, https: bool, token: str | None = None):
    return _pedir(puerto, "GET", ruta, https, token)


def test_https_responde_y_el_certificado_tiene_la_huella_de_tls_service(servidores):
    _esperar_a_que_esten_activos(servidores)
    https, _ = servidores.puertos

    contexto = ssl._create_unverified_context()
    with socket.create_connection(("127.0.0.1", https)) as crudo, contexto.wrap_socket(crudo) as seguro:
        der = seguro.getpeercert(binary_form=True)

    assert hashlib.sha256(der).hexdigest() == tls_service.huella_sha256()
    assert _get(https, "/estado", https=True)[0] == 200


def test_el_https_no_habla_http_plano(servidores):
    _esperar_a_que_esten_activos(servidores)
    https, _ = servidores.puertos
    with pytest.raises((http.client.HTTPException, ConnectionError, OSError)):
        _get(https, "/estado", https=False)


def test_registro_login_y_metricas_de_extremo_a_extremo_por_https_y_por_el_puerto_interno(servidores):
    _esperar_a_que_esten_activos(servidores)
    https, interno = servidores.puertos
    assert _get(https, "/metrics", https=True)[0] == 401
    assert _get(interno, "/metrics", https=False)[0] == 401
    with database.connect() as conexion:
        codigo, _ = auth_service.abrir_registro(conexion)

    estado, cuerpo = _pedir(
        https, "POST", "/registro", True, cuerpo={"codigo": codigo, "usuario": "alex", "contrasena": "Clave1"}
    )
    assert estado == 201
    token = json.loads(cuerpo)["token"]

    assert _get(https, "/metrics", https=True, token=token)[0] == 200
    assert _get(interno, "/metrics", https=False, token=token)[0] == 200

    login = {"usuario": "alex", "contrasena": "Clave1", "dispositivo": "Tablet"}
    estado, cuerpo = _pedir(interno, "POST", "/login", False, cuerpo=login)
    assert estado == 202
    assert json.loads(cuerpo)["sesion_activa_en"] == "Móvil"

    mala = {"usuario": "alex", "contrasena": "mala", "dispositivo": "Tablet"}
    estados = [_pedir(https, "POST", "/login", True, cuerpo=mala)[0] for _ in range(6)]
    assert estados == [401, 401, 401, 401, 401, 429]


def test_detener_libera_los_puertos():
    https, interno = _puerto_libre(), _puerto_libre()
    servidores = Servidores(puerto_https=https, puerto_interno=interno, con_iroh=False)
    servidores.iniciar()
    _esperar_a_que_esten_activos(servidores)

    servidores.detener()

    for puerto in (https, interno):
        with pytest.raises(ConnectionRefusedError), socket.create_connection(("127.0.0.1", puerto), timeout=1):
            pass


async def test_salir_de_la_tui_con_q_para_los_servidores_reales():
    https, interno = _puerto_libre(), _puerto_libre()
    servidores = Servidores(puerto_https=https, puerto_interno=interno, con_iroh=False)
    app = SysmoteApp(servidores=servidores)
    async with app.run_test(size=(120, 40)) as pilot:
        for _ in range(100):
            if all(estado == "activo" for estado in servidores.estado().values()):
                break
            await pilot.pause(0.05)
        assert _get(interno, "/estado", https=False)[0] == 200

        await pilot.press("q")
        await pilot.pause(0.5)

    for puerto in (https, interno):
        with pytest.raises(ConnectionRefusedError), socket.create_connection(("127.0.0.1", puerto), timeout=1):
            pass


def test_un_puerto_ocupado_se_notifica_sin_tumbar_el_otro():
    with socket.socket() as ocupado:
        ocupado.bind(("0.0.0.0", 0))
        ocupado.listen()
        servidores = Servidores(puerto_https=ocupado.getsockname()[1], puerto_interno=_puerto_libre(), con_iroh=False)
        servidores.iniciar()
        try:
            for _ in range(100):
                if servidores.estado()["https"].startswith("error") and servidores.estado()["interno"] == "activo":
                    break
                time.sleep(0.05)
            estado = servidores.estado()
            assert estado["https"].startswith("error")
            assert estado["interno"] == "activo"
        finally:
            servidores.detener()


def test_con_iroh_el_estado_incluye_el_tunel_y_detener_no_se_cuelga():
    servidores = Servidores(puerto_https=_puerto_libre(), puerto_interno=_puerto_libre(), con_iroh=True)
    servidores.iniciar()
    time.sleep(1)
    assert "iroh" in servidores.estado()

    inicio = time.monotonic()
    servidores.detener()

    assert time.monotonic() - inicio < 5
