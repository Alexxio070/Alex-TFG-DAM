import hashlib
import sqlite3
from datetime import UTC, datetime, timedelta
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

from sysmote.api.deps import get_connection
from sysmote.main import app
from sysmote.repositories import codigo_registro_repository

SCHEMA = (Path(__file__).resolve().parent.parent / "schema.sql").read_text()
CODIGO = "K7QX-M2PD-9WTR-4HNB"


@pytest.fixture
def connection():
    connection = sqlite3.connect(":memory:", check_same_thread=False)
    connection.execute("PRAGMA foreign_keys = ON")
    connection.executescript(SCHEMA)
    app.dependency_overrides[get_connection] = lambda: connection
    yield connection
    app.dependency_overrides.clear()
    connection.close()


@pytest.fixture
def client(connection):
    return TestClient(app)


def _abrir_registro(connection):
    caduca_en = (datetime.now(UTC) + timedelta(minutes=10)).isoformat()
    codigo_registro_repository.crear(connection, hashlib.sha256(CODIGO.encode()).hexdigest(), caduca_en)


def _registrar(client, connection, contrasena="Clave1"):
    _abrir_registro(connection)
    return client.post(
        "/registro", json={"codigo": CODIGO, "usuario": "alex", "contrasena": contrasena, "dispositivo": "Pixel 8"}
    )


def _con_token(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


def test_rutas_protegidas_sin_token_dan_401_no_autenticado(client):
    for metodo, ruta in [
        ("get", "/metrics"),
        ("get", "/sesion"),
        ("get", "/capacidades"),
        ("post", "/logout"),
        ("post", "/desemparejar"),
    ]:
        respuesta = getattr(client, metodo)(ruta)
        assert respuesta.status_code == 401, ruta
        assert respuesta.json()["error"] == "no_autenticado", ruta
        assert respuesta.json()["mensaje"], ruta


def test_cabecera_con_esquema_distinto_de_bearer_da_401(client):
    assert client.get("/sesion", headers={"Authorization": "Basic abc"}).status_code == 401


def test_estado_es_publico(client):
    respuesta = client.get("/estado")
    assert respuesta.status_code == 200
    assert respuesta.json() == {"api": 1, "configurado": False, "registro_abierto": False, "sesion_activa": False}


def test_registro_devuelve_201_con_token_y_el_token_abre_las_rutas_protegidas(client, connection):
    respuesta = _registrar(client, connection)
    assert respuesta.status_code == 201
    assert respuesta.json()["usuario"] == "alex"

    token = respuesta.json()["token"]
    assert client.get("/capacidades", headers=_con_token(token)).json() == {"modulos": ["metricas"]}
    assert client.get("/metrics", headers=_con_token(token)).status_code == 200


def test_registro_con_contrasena_debil_da_422_con_motivos(client, connection):
    respuesta = _registrar(client, connection, contrasena="abc")
    assert respuesta.status_code == 422
    assert respuesta.json()["error"] == "contrasena_debil"
    assert len(respuesta.json()["motivos"]) == 3


def test_registro_con_codigo_equivocado_da_403_codigo_invalido(client, connection):
    _abrir_registro(connection)
    respuesta = client.post("/registro", json={"codigo": "OTRO", "usuario": "alex", "contrasena": "Clave1"})
    assert respuesta.status_code == 403
    assert respuesta.json()["error"] == "codigo_invalido"


def test_registro_cerrado_da_403(client):
    respuesta = client.post("/registro", json={"codigo": CODIGO, "usuario": "alex", "contrasena": "Clave1"})
    assert respuesta.status_code == 403
    assert respuesta.json()["error"] == "registro_cerrado"


def test_cuerpo_mal_formado_da_422_peticion_invalida(client):
    respuesta = client.post("/login", json={"usuario": "alex"})
    assert respuesta.status_code == 422
    assert respuesta.json()["error"] == "peticion_invalida"


def test_login_con_credenciales_malas_da_401(client, connection):
    _registrar(client, connection)
    respuesta = client.post("/login", json={"usuario": "alex", "contrasena": "mala", "dispositivo": "Tablet"})
    assert respuesta.status_code == 401
    assert respuesta.json()["error"] == "credenciales_invalidas"


def test_login_con_sesion_activa_da_202_y_el_flujo_de_solicitud_completo(client, connection):
    primero = _registrar(client, connection).json()["token"]

    login = client.post("/login", json={"usuario": "alex", "contrasena": "Clave1", "dispositivo": "Tablet"})
    assert login.status_code == 202
    assert login.json()["estado"] == "pendiente"
    assert login.json()["sesion_activa_en"] == "Pixel 8"
    solicitud = login.json()["solicitud"]
    assert client.get(f"/login/solicitud/{solicitud}").json() == {"estado": "pendiente"}

    from sysmote.services import auth_service

    auth_service.responder_solicitud(connection, solicitud, aprobar=True)
    aprobada = client.get(f"/login/solicitud/{solicitud}").json()
    assert aprobada["estado"] == "aprobada"

    assert client.get("/sesion", headers=_con_token(primero)).status_code == 401
    assert client.get("/sesion", headers=_con_token(aprobada["token"])).json()["dispositivo"] == "Tablet"
    assert client.get(f"/login/solicitud/{solicitud}").status_code == 404


def test_login_sin_sesion_activa_da_200_con_token(client, connection):
    token = _registrar(client, connection).json()["token"]
    client.post("/logout", headers=_con_token(token))

    respuesta = client.post("/login", json={"usuario": "alex", "contrasena": "Clave1", "dispositivo": "Tablet"})
    assert respuesta.status_code == 200
    assert "token" in respuesta.json()


def test_sesion_devuelve_usuario_dispositivo_y_fecha(client, connection):
    token = _registrar(client, connection).json()["token"]
    cuerpo = client.get("/sesion", headers=_con_token(token)).json()
    assert cuerpo["usuario"] == "alex"
    assert cuerpo["dispositivo"] == "Pixel 8"
    assert datetime.fromisoformat(cuerpo["creada"]).tzinfo is not None


def test_logout_da_204_y_el_token_deja_de_valer(client, connection):
    token = _registrar(client, connection).json()["token"]
    assert client.post("/logout", headers=_con_token(token)).status_code == 204
    respuesta = client.get("/sesion", headers=_con_token(token))
    assert respuesta.status_code == 401
    assert respuesta.json()["error"] == "no_autenticado"


def test_desemparejar_da_204_y_luego_401_desemparejado(client, connection):
    token = _registrar(client, connection).json()["token"]
    assert client.post("/desemparejar", headers=_con_token(token)).status_code == 204
    respuesta = client.get("/sesion", headers=_con_token(token))
    assert respuesta.status_code == 401
    assert respuesta.json()["error"] == "desemparejado"


def test_ruta_inexistente_usa_el_formato_de_error(client):
    respuesta = client.get("/no-existe")
    assert respuesta.status_code == 404
    assert respuesta.json()["error"] == "no_encontrado"


def test_documentacion_automatica_desactivada(client):
    assert client.get("/docs").status_code == 404
    assert client.get("/openapi.json").status_code == 404


def test_cinco_fallos_dan_429_con_retry_after_y_espera(client, connection):
    _registrar(client, connection)
    for _ in range(5):
        client.post("/login", json={"usuario": "alex", "contrasena": "mala", "dispositivo": "Tablet"})

    respuesta = client.post("/login", json={"usuario": "alex", "contrasena": "Clave1", "dispositivo": "Tablet"})

    assert respuesta.status_code == 429
    assert respuesta.json()["error"] == "demasiados_intentos"
    assert 0 < respuesta.json()["espera_s"] <= 600
    assert respuesta.headers["Retry-After"] == str(respuesta.json()["espera_s"])


def test_el_origen_del_intento_se_guarda(client, connection):
    _registrar(client, connection)
    client.post("/login", json={"usuario": "alex", "contrasena": "mala", "dispositivo": "Tablet"})
    assert connection.execute("SELECT origen FROM intento_login").fetchone()[0]
