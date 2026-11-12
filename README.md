# Sysmote

Proyecto final de DAM: administrar un PC con GNU/Linux desde el móvil, estando o no en casa, sin configurar el router ni instalar una VPN.

El sistema tiene dos piezas que se desarrollan juntas pero por separado:

- **Una app Android** (Flutter) que es el cliente: muestra el estado del PC y manda órdenes.
- **Un agente en el PC** (Python) que hace todo el trabajo real: abre terminales, mide el sistema, ejecuta acciones y guarda los datos.

Funciones principales (solo las que tienen sentido estando lejos del PC): terminal remota con la shell real del usuario, monitorización del sistema en vivo, energía y sesión, acciones rápidas (comandos guardados, con historial), un espacio compartido de notas entre el móvil y el PC, y notificaciones con reglas de alerta configurables.

## Componentes

| Carpeta | Qué es | Stack |
|---|---|---|
| [`App-movil/`](App-movil/) | Cliente Android | Flutter/Dart, MVVM + `provider`, `xterm.dart` para la terminal |
| [`agent/`](agent/) | Agente del PC | Python 3.11+, FastAPI + Uvicorn, Textual (TUI `sysmote`), `psutil` |

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
│   └── sysmote/
│       ├── api/            Rutas de FastAPI
│       ├── services/       Lógica de negocio
│       ├── repositories/   Acceso a datos (psutil, SQLite cuando exista)
│       ├── models/         Modelos Pydantic
│       └── tui/            Interfaz de terminal `sysmote` (Textual)
│
└── doc/                     Documentación del proyecto
    ├── documentos-generales-del-proyecto/   Memoria técnica, plan de fases, decisiones…
    ├── ui/                                  Especificación y prototipos de la interfaz
    ├── agente/                              Especificación del agente y su TUI
    └── iroh/                                Qué es iroh, implementación, problemas y pruebas
```

## Estado actual

El estado por fase, con lo hecho y lo pendiente, está en [`doc/documentos-generales-del-proyecto/04-plan-de-fases.md`](doc/documentos-generales-del-proyecto/04-plan-de-fases.md).

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
.venv/bin/sysmote                                          # TUI
.venv/bin/uvicorn sysmote.main:app --reload --port 8443    # API REST
```

Por defecto escucha solo en `127.0.0.1:8443`. **No usar `--host 0.0.0.0` todavía:** dejaría `/metrics` y `/docs` abiertos a toda la red local sin TLS ni login (llegan en la fase 3). Todavía no hay servicio systemd (llega en la fase 5).

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
- `doc/iroh/` — qué es iroh, cómo está implementado, problemas encontrados y pruebas.

Ramas: `main` (estable) y una `feature/<nombre>` por tarea o fase; sin `develop`; las etiquetas de versión solo para publicar el APK en las releases.
