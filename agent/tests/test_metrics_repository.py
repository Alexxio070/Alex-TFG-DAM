"""Tests unitarios del repositorio de métricas, con psutil simulado."""

from types import SimpleNamespace

import pytest

from sysmote.repositories import metrics_repository as repo


def partition(device, mount, fstype="ext4"):
    return SimpleNamespace(device=device, mountpoint=mount, fstype=fstype, opts="")


def usage(total, used):
    return SimpleNamespace(total=total, used=used, free=total - used, percent=used / total * 100)


def test_read_cpu_temp_c_sin_sensores_devuelve_none(monkeypatch):
    monkeypatch.setattr(repo.psutil, "sensors_temperatures", dict)
    assert repo.read_cpu_temp_c() is None


def test_read_cpu_temp_c_usa_el_primer_sensor_conocido(monkeypatch):
    temps = {"k10temp": [SimpleNamespace(label="Tctl", current=57.5, high=None, critical=None)]}
    monkeypatch.setattr(repo.psutil, "sensors_temperatures", lambda: temps)
    assert repo.read_cpu_temp_c() == 57.5


def test_read_partitions_salta_montajes_sin_permiso(monkeypatch):
    monkeypatch.setattr(
        repo.psutil, "disk_partitions", lambda: [partition("/dev/sda1", "/mnt/sin-permiso")]
    )

    def fake_disk_usage(path):
        raise PermissionError

    monkeypatch.setattr(repo.psutil, "disk_usage", fake_disk_usage)
    assert repo.read_partitions() == []


def test_read_partitions_descarta_snaps_y_montajes_loop(monkeypatch):
    monkeypatch.setattr(
        repo.psutil,
        "disk_partitions",
        lambda: [
            partition("/dev/sda1", "/", fstype="ext4"),
            partition("/dev/loop12", "/snap/firefox/123", fstype="squashfs"),
            partition("/dev/loop13", "/snap/core/456", fstype="ext4"),
        ],
    )
    monkeypatch.setattr(repo.psutil, "disk_usage", lambda path: usage(100 * repo.GB, 50 * repo.GB))

    partitions = repo.read_partitions()
    assert [p.mount for p in partitions] == ["/"]


def test_read_partitions_descarta_duplicados_por_dispositivo(monkeypatch):
    monkeypatch.setattr(
        repo.psutil,
        "disk_partitions",
        lambda: [
            partition("/dev/sda1", "/home/sub/largo"),
            partition("/dev/sda1", "/"),
            partition("/dev/sdb1", "/datos"),
        ],
    )
    monkeypatch.setattr(repo.psutil, "disk_usage", lambda path: usage(100 * repo.GB, 50 * repo.GB))

    partitions = repo.read_partitions()
    assert {p.mount for p in partitions} == {"/", "/datos"}


def test_read_partitions_usa_gb_decimales(monkeypatch):
    monkeypatch.setattr(repo.psutil, "disk_partitions", lambda: [partition("/dev/sda1", "/")])
    monkeypatch.setattr(repo.psutil, "disk_usage", lambda path: usage(1000**3, 500**3 * 2))

    partitions = repo.read_partitions()
    assert partitions[0].total_gb == pytest.approx(1.0)
