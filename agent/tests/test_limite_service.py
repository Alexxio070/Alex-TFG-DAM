"""Cálculo del bloqueo por intentos fallidos y su duración configurable."""

from datetime import UTC, datetime, timedelta

from sysmote import rutas
from sysmote.models.auth import IntentoLogin
from sysmote.services import config_service, limite_service

DIEZ_MINUTOS = timedelta(minutes=10)
AHORA = datetime(2026, 1, 1, 12, 0, tzinfo=UTC)


def _intentos(*resultados: bool, hace: timedelta = timedelta(minutes=1)) -> list[IntentoLogin]:
    return [
        IntentoLogin(
            id=i,
            usuario_id=None,
            nombre_usuario="alex",
            origen="local",
            fecha=(AHORA - hace + timedelta(seconds=i)).isoformat(),
            exito=exito,
        )
        for i, exito in enumerate(resultados)
    ]


def test_cuatro_fallos_no_bloquean():
    assert (
        limite_service.espera_restante(_intentos(False, False, False, False), AHORA, DIEZ_MINUTOS)
        == 0
    )


def test_cinco_fallos_seguidos_bloquean_el_tiempo_restante():
    espera = limite_service.espera_restante(_intentos(*[False] * 5), AHORA, DIEZ_MINUTOS)
    assert 0 < espera <= 600
    assert espera == 600 - 60 + 4


def test_un_acierto_pone_el_contador_a_cero():
    assert (
        limite_service.espera_restante(
            _intentos(False, False, False, False, True, False), AHORA, DIEZ_MINUTOS
        )
        == 0
    )


def test_al_terminar_el_bloqueo_el_contador_vuelve_a_cero():
    antiguos = _intentos(*[False] * 5, hace=timedelta(minutes=11))
    assert limite_service.espera_restante(antiguos, AHORA, DIEZ_MINUTOS) == 0


def test_tras_un_bloqueo_terminado_hacen_falta_cinco_fallos_nuevos():
    intentos = _intentos(*[False] * 5, hace=timedelta(minutes=11)) + [
        IntentoLogin(
            id=99 + i,
            usuario_id=None,
            nombre_usuario="alex",
            origen="local",
            fecha=(AHORA - timedelta(seconds=30 - i)).isoformat(),
            exito=False,
        )
        for i in range(4)
    ]
    assert limite_service.espera_restante(intentos, AHORA, DIEZ_MINUTOS) == 0


def test_la_duracion_cambia_el_tiempo_de_espera():
    espera = limite_service.espera_restante(_intentos(*[False] * 5), AHORA, timedelta(minutes=2))
    assert 0 < espera <= 120


def test_comprobar_no_afecta_a_otra_cuenta(connection):
    for _ in range(5):
        limite_service.registrar(connection, "alex", None, "local", exito=False)
    limite_service.comprobar(connection, "otro")


def test_duracion_por_defecto_son_10_minutos():
    assert config_service.duracion_bloqueo() == timedelta(minutes=10)


def test_duracion_se_lee_de_config_toml():
    rutas.CONFIG_PATH.write_text("[seguridad]\nbloqueo_minutos = 2\n")
    assert config_service.duracion_bloqueo() == timedelta(minutes=2)


def test_config_sin_la_clave_usa_el_valor_por_defecto():
    rutas.CONFIG_PATH.write_text("[otra]\nclave = 1\n")
    assert config_service.duracion_bloqueo() == timedelta(minutes=10)
