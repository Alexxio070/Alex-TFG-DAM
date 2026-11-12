# Tests del agente

Documentación de los tests de [`agent/tests/`](../../agent/tests/): qué prueba cada archivo y para qué sirve. Hay 16 tests, todos automáticos; ninguno requiere pasos manuales.

```bash
cd agent && .venv/bin/pytest -q
```

## Resumen

| Archivo | Tests | Qué prueba | Tipo |
|---|---|---|---|
| [`test_metrics.py`](../../agent/tests/test_metrics.py) | 1 | El endpoint `GET /metrics` completo | Integración |
| [`test_metrics_repository.py`](../../agent/tests/test_metrics_repository.py) | 6 | El repositorio de métricas, con `psutil` simulado | Unitario |
| [`test_tui.py`](../../agent/tests/test_tui.py) | 6 | La TUI `sysmote`, sin terminal real | Interfaz (arnés de Textual) |
| [`test_iroh_tunnel.py`](../../agent/tests/test_iroh_tunnel.py) | 3 | El túnel iroh del agente (`sysmote/iroh_tunnel.py`) | Integración |

## `test_metrics.py`: endpoint `GET /metrics`

Usa el cliente de pruebas de FastAPI y lee datos reales de `psutil` de la máquina donde corre, sin simulaciones. Por eso depende del entorno: en un contenedor sin `/dev` reales no recorre ninguna partición, pero no falla.

| Test | Qué comprueba | Qué fallo detecta |
|---|---|---|
| `test_get_metrics_returns_real_data` | `cpu_percent` entre 0 y 100; `cpu_temp_c` es `None` o positivo; `ram_used_gb` mayor que 0 y `ram_total_gb` no menor que la usada; cada partición tiene `device` que empieza por `/dev/` y `total_gb` ≥ `used_gb` ≥ 0 | Que el endpoint deje de responder, devuelva campos mal formados o valores sin sentido (RAM negativa, usado mayor que total) |

## `test_metrics_repository.py`: repositorio de métricas

Pruebas unitarias con `psutil` sustituido mediante `monkeypatch`.

| Test | Qué comprueba | Qué fallo detecta |
|---|---|---|
| `test_read_cpu_temp_c_sin_sensores_devuelve_none` | Sin sensores de temperatura devuelve `None` | Un error o un valor inventado cuando el hardware no da temperatura |
| `test_read_cpu_temp_c_usa_el_primer_sensor_conocido` | Con un sensor `k10temp` simulado, devuelve su valor | Que deje de leer los sensores de CPU reales |
| `test_read_partitions_salta_montajes_sin_permiso` | Si `disk_usage` lanza `PermissionError`, descarta esa partición | Que el endpoint falle por un punto de montaje sin permisos |
| `test_read_partitions_descarta_snaps_y_montajes_loop` | Una partición squashfs de snap y un `/dev/loop` quedan fuera; solo pasa `/` | Que los paquetes snap reaparezcan como discos (bug ya corregido) |
| `test_read_partitions_descarta_duplicados_por_dispositivo` | El mismo dispositivo montado en dos puntos se queda solo con la ruta más corta | Que reaparezcan particiones duplicadas (típico de btrfs con subvolúmenes) |
| `test_read_partitions_usa_gb_decimales` | 1000³ bytes dan `total_gb=1.0` | Una regresión a 1024³ (bug de unidades ya corregido: la app espera GB decimales) |

## `test_tui.py`: TUI `sysmote`

Usa el arnés de pruebas sin terminal de Textual.

| Test | Qué comprueba | Qué fallo detecta |
|---|---|---|
| `test_mounts_with_empty_data_area` | Al arrancar, el área de datos está vacía y ningún botón principal aparece marcado | Que una sección se muestre sola al arrancar |
| `test_main_buttons_switch_section` | Cada uno de los 4 botones (Emparejamiento, Historial, Base de datos, Notas) cambia la sección | Botones que no navegan a su sección |
| `test_active_button_is_highlighted` | El botón de la sección activa tiene `variant="primary"` y el resto `default` | Que se pierda el resaltado del botón activo |
| `test_pairing_subtabs_switch` | Las 3 subpestañas de Emparejamiento (Dispositivo, Seguridad, Servicio) cambian el contenido y se resaltan | El mismo fallo en el segundo nivel de navegación |
| `test_banner_falls_back_to_plain_text_when_narrow` | Con terminal ancha se ve el banner ASCII; por debajo de `BANNER_MIN_WIDTH` pasa a texto plano (`BANNER_FALLBACK`) | Que el banner vuelva a romperse en terminales estrechas (bug ya corregido) |
| `test_buttons_stay_clickable_when_narrow` | En terminal estrecha se siguen pudiendo pulsar Emparejamiento y su subpestaña Seguridad | Que la barra de botones se desborde y quede inalcanzable (bug ya corregido) |

## `test_iroh_tunnel.py`: túnel iroh

Prueba de concepto del túnel: cliente y servidor iroh viven en el mismo proceso y se conectan por sus direcciones directas en loopback, sin red ni relés. Los tests dependen del paquete `iroh` instalado en el entorno.

| Test | Qué comprueba | Qué fallo detecta |
|---|---|---|
| `test_tunnel_forwards_bytes_to_local_server` | Los bytes enviados por el túnel llegan a un servidor local de eco y vuelven (`ping`) | Que el túnel no reenvíe datos entre el flujo QUIC y el puerto local |
| `test_tunnel_resets_the_stream_when_the_local_agent_is_down` | Si nada escucha en el puerto local, el flujo se cierra enseguida con un reset, sin quedarse colgado hasta un timeout | Que el cliente espere sin fin cuando el agente real está caído |
| `test_tunnel_forwards_a_real_metrics_request` | Una petición HTTP real a `/metrics` a través del túnel contra el agente en marcha responde `HTTP/1.1 200 OK` con `"cpu_percent"` | Que el túnel rompa el acceso real a las métricas del agente |
