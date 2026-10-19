# Agente (Python)

Estado: fase 1 en marcha. Diseño completo en [`../doc/agente/`](../doc/agente/).

## Entorno de desarrollo

```bash
cd agent
python3 -m venv .venv
.venv/bin/pip install -e ".[dev]"
```

## Arrancar a mano

TUI:

```bash
.venv/bin/companion
```

Servidor FastAPI (endpoint `GET /metrics`):

```bash
.venv/bin/uvicorn companion.main:app --reload --port 8443
```

Por defecto escucha solo en `127.0.0.1:8443`. Para probar desde el móvil por
USB: `adb reverse tcp:8443 tcp:8443` (o usar el emulador, con `10.0.2.2`).

**No usar `--host 0.0.0.0`** todavía: dejaría `/metrics` y `/docs` abiertos a
toda la red local sin TLS ni login (llegan en la fase 3).

## Pruebas

```bash
.venv/bin/pytest
```

Cubren que la TUI monta y se puede navegar por sus secciones y subpestañas
(`tests/test_tui.py`), que `GET /metrics` responde con datos reales
(`tests/test_metrics.py`) y la lógica del repositorio de métricas con psutil
simulado (`tests/test_metrics_repository.py`).
