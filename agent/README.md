# Sysmote (agente)

Agente de [Sysmote](https://github.com/Alexxio070/Alex-TFG-DAM) para tu PC Linux: mide el sistema, expone una API protegida con login y trae una interfaz de terminal (`sysmote`) para configurarlo. Se maneja desde la app Android de Sysmote, por la red local, por USB o, desde fuera de casa, por un túnel [iroh](https://www.iroh.computer/) sin abrir puertos en el router.

> **Proyecto en desarrollo (beta).** Todavía no se ha auditado y solo se ha probado en un móvil físico (Xiaomi Redmi 13C, Android 15). Úsalo solo para probar.

## Requisitos

- Linux de 64 bits (glibc 2.28 o superior) y Python 3.11 o superior. El binding de iroh solo publica paquetes para Linux.
- La app Android de Sysmote. Por ahora se compila desde el repositorio; las instrucciones están en el [README del proyecto](https://github.com/Alexxio070/Alex-TFG-DAM#readme).

## Instalación

Con `pipx` (recomendado):

```bash
pipx install sysmote
sysmote
```

Con `pip`, dentro de un entorno virtual (las distribuciones modernas no permiten `pip install` fuera de uno):

```bash
python3 -m venv ~/.local/share/sysmote/venv
~/.local/share/sysmote/venv/bin/pip install sysmote
~/.local/share/sysmote/venv/bin/sysmote
```

## Uso

`sysmote` abre la interfaz de terminal y **levanta el servicio del agente**: HTTPS en el puerto 8443 (toda la red local, para USB y LAN), un HTTP interno solo en `127.0.0.1:8444` y el túnel iroh. Debe estar abierto mientras uses la app; al salir se paran los servidores.

1. En la TUI, ve a **Emparejamiento → Seguridad** y pulsa **Configuración inicial**: muestra un código de registro de un solo uso que caduca a los 10 minutos.
2. En la app, indica la dirección, la huella del certificado y, si te conectas desde fuera de casa, el identificador de iroh (los dos últimos aparecen en la pestaña **Dispositivo**).
3. Regístrate en la app con el código, un usuario y una contraseña (mínimo 5 caracteres, un número y una mayúscula).

## Seguridad

- Sin sesión solo responden `/estado`, `/registro`, `/login` y `/login/solicitud/{id}`; `/docs` y `/openapi.json` están desactivados.
- Por red local y USB la conexión va por HTTPS con la huella del certificado fijada en la app. Por iroh va cifrada con el propio cifrado de iroh.
- Contraseñas con Argon2, tokens de sesión opacos y revocables, y límite de intentos de login por cuenta.

## Más información

El diseño completo, el contrato de la API y la documentación de la TUI están en la [carpeta `doc/`](https://github.com/Alexxio070/Alex-TFG-DAM/tree/main/doc) del repositorio.

## Licencia

[GNU GPL v3.0](https://www.gnu.org/licenses/gpl-3.0.html) (solo esa versión).
