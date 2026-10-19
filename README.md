# Linux System Companion

Proyecto final de DAM: administrar un PC con GNU/Linux desde el móvil, estando o no en casa, sin configurar el router ni instalar una VPN.

El sistema tiene dos piezas que se desarrollan juntas pero por separado:

- **Una app Android** (Flutter) que es el cliente: muestra el estado del PC y manda órdenes.
- **Un agente en el PC** (Python) que hace todo el trabajo real: abre terminales, mide el sistema, ejecuta acciones y guarda los datos.

Funciones principales (solo las que tienen sentido estando lejos del PC): terminal remota con la shell real del usuario, monitorización del sistema en vivo, gestión de procesos, energía y sesión, acciones rápidas (comandos guardados, con historial), un espacio compartido de notas entre el móvil y el PC, y notificaciones con reglas de alerta configurables.

## Componentes

| Carpeta | Qué es | Stack |
|---|---|---|
| [`App-movil/`](App-movil/) | Cliente Android | Flutter/Dart, MVVM + `provider`, `xterm.dart` para la terminal |
| [`agent/`](agent/) | Agente del PC | Python 3.11+, FastAPI + Uvicorn, Textual (TUI `companion`), `psutil` |

## Estructura de carpetas

```
.
├── App-movil/              Cliente Flutter
│   ├── lib/
│   │   ├── core/           Tema, widgets y utilidades compartidas
│   │   ├── data/           Modelos y repositorios (uno real + uno simulado por dato)
│   │   │   ├── fake/       Repositorios simulados (desarrollar sin el agente)
│   │   │   ├── http/       Repositorios reales (llaman al agente)
│   │   │   └── local/      Persistencia local (ajustes)
│   │   └── features/       Una carpeta por pantalla: home, metrics, notes, settings,
│   │                       shell (navegación), terminal
│   └── test/
│
├── agent/                  Agente Python
│   └── companion/
│       ├── api/            Rutas de FastAPI
│       ├── services/       Lógica de negocio
│       ├── repositories/   Acceso a datos (psutil, SQLite cuando exista)
│       ├── models/         Modelos Pydantic
│       └── tui/            Interfaz de terminal `companion` (Textual)
│
└── doc/                     Documentación del proyecto
    ├── documentos-generales-del-proyecto/   Memoria técnica, plan de fases, decisiones…
    ├── ui/                                  Especificación y prototipos de la interfaz
    └── agente/                              Especificación del agente y su TUI
```

## Estado actual

- **App:** interfaz completa y navegable (las seis pantallas). La pantalla de métricas ya usa un repositorio real contra el agente; el resto sigue con datos simulados hasta que el agente los ofrezca.
- **Agente:** estructura en capas creada; endpoint `GET /metrics` (CPU, RAM, discos, temperatura) implementado y probado; esqueleto de la TUI `companion` con sus cuatro secciones (la mayoría deshabilitadas a la espera de fases posteriores). Sin base de datos, login ni conexión remota todavía.

El detalle completo, fase a fase, está en [`doc/documentos-generales-del-proyecto/04-plan-de-fases.md`](doc/documentos-generales-del-proyecto/04-plan-de-fases.md).

## Manual de instalación

### Requisitos

- **App:** Flutter (SDK de Dart `^3.13.4`, ver `App-movil/pubspec.yaml`) y un dispositivo o emulador Android.
- **Agente:** Python 3.11 o superior.

### App (Flutter)

```bash
cd App-movil
flutter pub get
flutter run
```

Por defecto la app busca el agente en `127.0.0.1:8443` (pensado para depurar por USB con `adb reverse tcp:8443 tcp:8443`); la dirección se cambia desde Ajustes.

### Agente (Python)

```bash
cd agent
python3 -m venv .venv
.venv/bin/pip install -e ".[dev]"
```

Arrancar a mano (todavía no hay servicio systemd ni comando `companion` empaquetado):

```bash
.venv/bin/uvicorn companion.main:app --reload --port 8443   # API REST
.venv/bin/python -m companion.tui.app                       # TUI
```

Pruebas:

```bash
.venv/bin/pytest
```

## Documentación

Toda la documentación de diseño está en [`doc/`](doc/):

- [`doc/documentos-generales-del-proyecto/01-memoria-tecnica.md`](doc/documentos-generales-del-proyecto/01-memoria-tecnica.md) — diseño completo del sistema.
- [`doc/documentos-generales-del-proyecto/04-plan-de-fases.md`](doc/documentos-generales-del-proyecto/04-plan-de-fases.md) — plan de fases y calendario.
- [`doc/documentos-generales-del-proyecto/07-resumen-decisiones-y-contexto.md`](doc/documentos-generales-del-proyecto/07-resumen-decisiones-y-contexto.md) — decisiones tomadas y pendientes.
- [`doc/ui/`](doc/ui/) — especificación de la interfaz de la app.
- [`doc/agente/`](doc/agente/) — especificación del agente y de su TUI.

Ramas: `main` (estable, con todo el proyecto), `feature/interfaz` (app) y `feature/agent` (agente).
