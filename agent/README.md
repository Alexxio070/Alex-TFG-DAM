# Agente (Python)

Estado: fase 1 en marcha. Diseño completo en [`../doc/agente/`](../doc/agente/).

## Entorno de desarrollo

```bash
cd agent
python3 -m venv .venv
.venv/bin/pip install -e ".[dev]"
```

## Arrancar a mano

TUI (`companion`, sin empaquetar todavía):

```bash
.venv/bin/python -m companion.tui.app
```

Servidor FastAPI (sin rutas todavía: endpoint `/metrics` pendiente):

```bash
.venv/bin/uvicorn companion.main:app --reload --port 8443
```

## Pruebas

```bash
.venv/bin/pytest
```

Por ahora solo cubren que la TUI monta y que se puede navegar por sus secciones
y subpestañas (`tests/test_tui.py`). Faltan los del servicio de métricas, en
cuanto exista.
