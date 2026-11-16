# Sysmote

[![Licencia: GPL-3.0](https://img.shields.io/badge/licencia-GPL--3.0-blue.svg)](LICENSE)
![Flutter](https://img.shields.io/badge/app-Flutter-02569B.svg)
![Python 3.11+](https://img.shields.io/badge/agente-Python%203.11%2B-3776AB.svg)
![Estado: en desarrollo](https://img.shields.io/badge/estado-en%20desarrollo-orange.svg)

**Administra tu PC Linux desde el móvil, estés donde estés, sin abrir puertos en el router ni montar una VPN.**

> [!WARNING]
> **Proyecto en desarrollo: todavía no es seguro exponerlo.** Aún no hay login ni cifrado propio. Con el acceso remoto por iroh activado, **cualquiera que conozca el identificador del agente puede conectarse a él**. Hoy solo expone métricas de solo lectura, pero no compartas el identificador y usa el agente solo para probar. No arranques el agente en `0.0.0.0`: dejaría la API abierta a toda tu red local.

Sysmote tiene dos piezas que se desarrollan juntas:

- **Una app Android** (Flutter) que es el cliente: muestra el estado del PC y le manda órdenes.
- **Un agente en el PC** (Python) que hace el trabajo real: mide el sistema, abre terminales, ejecuta acciones y guarda los datos. Incluye una interfaz de terminal (`sysmote`) para configurarlo.

Para llegar al PC desde fuera de casa usa [iroh](https://www.iroh.computer/), una librería de conexión directa entre equipos (P2P) que atraviesa routers y cortafuegos sin configurarlos.

Es un proyecto de fin de grado de Desarrollo de Aplicaciones Multiplataforma (DAM), de código abierto.

## Capturas

### App

<div align="center">

<table>
  <tr>
    <td align="center"><img src="doc/img/app-inicio.png" width="200" alt="Inicio"><br><sub>Inicio (acciones rápidas)</sub></td>
    <td align="center"><img src="doc/img/app-metricas.png" width="200" alt="Métricas"><br><sub>Métricas en vivo</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="doc/img/app-terminal.png" width="200" alt="Terminal"><br><sub>Terminal</sub></td>
    <td align="center"><img src="doc/img/app-notas.png" width="200" alt="Notas"><br><sub>Notas</sub></td>
  </tr>
</table>

</div>

Las pantallas de Inicio, Terminal y Notas muestran hoy datos de ejemplo: todavía no están conectadas al agente. La de Métricas sí funciona con el agente real.

### TUI del PC (`sysmote`)

<div align="center">

<table>
  <tr>
    <td align="center"><img src="doc/img/tui-emparejamiento.png" width="420" alt="Emparejamiento"><br><sub>Emparejamiento (con Seguridad y Servicio)</sub></td>
    <td align="center"><img src="doc/img/tui-historial.png" width="420" alt="Historial"><br><sub>Historial</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="doc/img/tui-base-de-datos.png" width="420" alt="Base de datos"><br><sub>Base de datos</sub></td>
    <td align="center"><img src="doc/img/tui-notas.png" width="420" alt="Notas"><br><sub>Notas</sub></td>
  </tr>
</table>

</div>

La TUI tiene la estructura completa, pero casi todos sus botones están deshabilitados hasta que se implementen sus funciones.

## Funciones

| Función | Estado |
|---|---|
| Métricas del PC en vivo: CPU, temperatura, RAM y discos, con gráficas | Disponible |
| Acceso desde fuera de casa por iroh (relé y conexión directa) | Disponible, sin login |
| Ajustes de la app (unidades, tema, modo de conexión) | Disponible |
| Terminal remota con la shell real del usuario (sesiones persistentes con tmux) | Interfaz hecha, falta conectarla al agente |
| Acciones rápidas (comandos guardados, con historial) | Interfaz hecha, falta conectarla al agente |
| Espacio compartido de notas y enlaces entre móvil y PC | Interfaz hecha, falta conectarla al agente |

## Estado actual

Noviembre de 2026. Se puede compilar la app y arrancar el agente a mano para ver las métricas reales del PC en el móvil, tanto por red local (USB) como desde otra red a través de iroh. Esa conexión se ha probado en casa, con datos móviles y desde una red restrictiva real. El resto de pantallas tienen la interfaz definitiva con datos de ejemplo. Hay un APK de prueba en las [releases](https://github.com/Alexxio070/Alex-TFG-DAM/releases). El agente aún no tiene instalador: se arranca a mano desde el código (ver más abajo).

## Roadmap

- [x] Interfaz de la app completa, con datos de ejemplo
- [x] Agente con métricas reales y TUI
- [x] Acceso remoto por iroh
- [ ] Login, emparejamiento seguro y cifrado (TLS)
- [ ] Terminal remota real
- [ ] Instalación del agente como servicio del sistema
- [ ] Procesos
- [ ] Acciones rápidas
- [ ] Notificaciones y reglas de alerta
- [ ] Notas compartidas entre móvil y PC
- [ ] Descubrimiento automático en red local y emparejamiento por QR

## Instalación y uso

> [!NOTE]
> **Esta no es la instalación final.** Todavía no hay instalador del agente. Esta guía sirve para probar el estado actual del proyecto.

### Instalación rápida

La app se instala desde un APK ya compilado. El agente aún se arranca desde el código fuente.

**Requisitos:** un PC Linux de 64 bits (glibc 2.28 o superior) con Python 3.11 o superior y Git, y un móvil Android 7 o superior (arm64). Para conectarlos por USB, `adb` y la depuración por USB activada.

**1. La app.** Descarga `sysmote-v0.1-beta-arm64.apk` desde [Releases](https://github.com/Alexxio070/Alex-TFG-DAM/releases) e instálalo en el móvil. Android avisará porque el APK está firmado con la clave de depuración y viene de fuera de la tienda: hay que permitir la instalación desde esa fuente.

**2. El agente.** En el PC:

```bash
git clone https://github.com/Alexxio070/Alex-TFG-DAM.git && cd Alex-TFG-DAM/agent
python3 -m venv .venv && .venv/bin/pip install -e ".[dev]"
.venv/bin/uvicorn sysmote.main:app --port 8443
```

> [!IMPORTANT]
> El comando `.venv/bin/uvicorn sysmote.main:app --port 8443` es el que **levanta el servicio del agente**. Debe estar en marcha mientras uses la app.

**3. Conectar la app con el agente.**

- **Por USB (red local):** con el móvil conectado, ejecuta `adb reverse tcp:8443 tcp:8443`. La app busca el agente en `127.0.0.1:8443`, así que las métricas aparecen sin más.
- **Desde otra red, por iroh:** arranca el agente con `.venv/bin/python scripts/iroh_poc.py` en lugar de `uvicorn`. Imprime el identificador del agente: en Ajustes de la app, elige el modo **iroh** y pégalo. Ten presente el aviso de seguridad de arriba.

### Compilar desde el código fuente

Para compilar la app tú mismo, además de lo anterior necesitas [Flutter](https://docs.flutter.dev/get-started/install) (Dart `^3.13.4`), el Android SDK con el NDK `29.0.14206865` y [Rust](https://rustup.rs/), porque el plugin `iroh_flutter` compila su núcleo en Rust la primera vez y tarda unos minutos.

```bash
cd App-movil
flutter pub get
flutter run                                          # móvil conectado o emulador
flutter build apk --release --target-platform android-arm64   # genera el APK
```

El agente se arranca y se conecta igual que en la instalación rápida. Las pruebas se ejecutan con `.venv/bin/pytest` (en `agent/`) y `flutter test` (en `App-movil/`).

> [!NOTE]
> La TUI (`sysmote`) todavía no sirve para nada: sus botones están deshabilitados. Si aun así quieres instalarla, desde la raíz del repositorio:
>
> ```bash
> pipx install ./agent
> sysmote
> ```

## Cómo funciona

```
 Móvil Android            Internet / red local              PC Linux
 (app Flutter)   <---- iroh (QUIC cifrado) ---->   agente Python (FastAPI)
                                                    métricas, terminal, notas...
```

La app no sabe por qué vía llega la información: un mismo repositorio de datos elige entre conexión local (HTTP) y conexión por iroh según los Ajustes. En el PC, el agente expone una API local y un pequeño túnel iroh que reenvía las peticiones recibidas a esa API. iroh empieza usando un relé cifrado y, cuando puede, pasa a una conexión directa entre móvil y PC.

## Documentación

Todo el diseño está en [`doc/`](doc/):

- [`doc/documentos-generales-del-proyecto/`](doc/documentos-generales-del-proyecto/): memoria técnica, necesidades tecnológicas, plan de fases, decisiones tomadas e ideas de futuro.
- [`doc/ui/`](doc/ui/): especificación de la interfaz y estructura de la app.
- [`doc/agente/`](doc/agente/): especificación del agente y de su TUI, y sus tests.
- [`doc/iroh/`](doc/iroh/): qué es iroh, cómo está implementado, los problemas encontrados y las pruebas.

## Estructura del repositorio

| Carpeta | Contenido | Stack |
|---|---|---|
| [`App-movil/`](App-movil/) | Cliente Android | Flutter/Dart, MVVM con `provider`, `xterm.dart` |
| [`agent/`](agent/) | Agente del PC | Python, FastAPI, Textual, `psutil`, iroh |
| [`doc/`](doc/) | Documentación | Markdown |

## Contribuir

Lee la [guía de contribución](CONTRIBUTING.md).

## Licencia

Sysmote se distribuye bajo la licencia [GNU GPL v3.0](LICENSE).
