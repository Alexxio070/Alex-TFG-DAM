# Referencias y Proyectos de Inspiración: Linux System Companion

Proyectos existentes que resuelven partes del problema. Para cada uno se indica qué aporta al TFG, en qué fase es útil y si se puede aprovechar su código o solo inspirarse en él.

---

## ⚠️ Aviso sobre licencias

- **Leer código para inspirarse siempre está permitido.**
- **Copiar código** obliga a respetar su licencia:
  - **Permisivas (MIT, BSD, Apache-2.0):** se puede reutilizar código manteniendo el aviso de copyright y la licencia original.
  - **Copyleft (GPL, LGPL, AGPL):** si copias código a tu proyecto, tu proyecto debe distribuirse bajo la misma licencia (o compatible). Con **AGPL** la obligación se extiende incluso al uso a través de red.
- Las licencias indicadas se comprobaron en cada repositorio el 02/10/2026. **Vuelve a comprobarlas antes de copiar nada**, porque pueden cambiar entre versiones.
- **Sin licencia declarada = no se puede reutilizar código.** Por defecto, todos los derechos son del autor.
- Documenta en la memoria qué código de terceros se ha usado y bajo qué licencia.

---

## 1. App móvil (Flutter)

### xterm.dart
- **Qué es:** emulador de terminal para Flutter, para móvil y escritorio.
- **Te aporta:** es directamente la pieza de la terminal en la app (fase 5). Incluye un ejemplo de terminal en ~100 líneas y un cliente SSH en ~100 líneas con `dartssh2`, que es casi el Módulo A del lado móvil.
- **Uso:** dependencia directa y código de ejemplo reutilizable.
- **Licencia:** MIT.
- **Repositorio:** github.com/TerminalStudio/xterm.dart

### LocalSend
- **Qué es:** app Flutter de código abierto para enviar archivos entre dispositivos de la misma red, sin servidores externos. Usa una API REST sobre HTTPS con certificados generados al vuelo en cada dispositivo.
- **Te aporta:** probablemente **la mejor referencia para la app**:
  - descubrimiento en red local;
  - HTTPS con certificados autofirmados desde Flutter;
  - transferencia de archivos;
  - organización de un proyecto Flutter real y grande.

  Útil en las fases 3, 9 y 10.
- **Uso:** inspiración y posible reutilización de fragmentos.
- **Licencia:** Apache-2.0.
- **Repositorio:** github.com/localsend/localsend

### iroh-ssh-android
- **Qué es:** cliente SSH para Android construido con Flutter que conecta a través de iroh (vía flutter_rust_bridge), con sesiones en un servicio en primer plano para sobrevivir en segundo plano.
- **Te aporta:** **el caso más parecido a tu proyecto**: Flutter + iroh + terminal remota + servicio en segundo plano en Android. Referencia clave para la fase 2 (prueba de concepto e integración de iroh, noviembre) y la fase 8 (servicio en primer plano).
- **Uso:** solo inspiración (usa flutter_rust_bridge; la arquitectura del servicio y la terminal es aplicable sea cual sea la vía elegida para iroh).
- **Licencia:** GPL-3.0. **No copiar código.**
- **Repositorio:** github.com/futpib/iroh-ssh-android

### iroh_flutter / iroh_quic
- **Qué es:** plugin de Flutter comunitario (no de n0) para iroh 1.0. Compila el núcleo Rust con cargokit y expone la API de iroh en Dart. Versión 1.0.3 (07/08/2026).
- **Te aporta:** alternativa al módulo Kotlin para la fase 2 *(pendiente de revisión)*.
- **Uso:** posible dependencia directa si se elige esa vía. Comprobar su licencia antes de usarlo.
- **Repositorio:** github.com/snowpinelabs/iroh_dart · pub.dev/packages/iroh_flutter

### iroh-android-native
- **Qué es:** no es una librería genérica, sino el transporte P2P de un proyecto concreto de 1337farm: un motor iroh (Rust, iroh 1.1) expuesto a Kotlin mediante JNI, más un servicio en primer plano de tipo `dataSync`.
- **Te aporta:** ejemplo de cómo empaquetar iroh y un servicio en primer plano en Android (fases 2 y 8). Ojo: su tipo `dataSync` se detiene tras 6 h cada 24 desde Android 15, así que ese detalle no se debe copiar.
- **Uso:** solo inspiración.
- **Licencia:** no declara ninguna. **No se puede reutilizar código.**
- **Repositorio:** github.com/1337farm/iroh-android-native

---

## 2. Agente en el PC (Python)

### terminado
- **Qué es:** el backend de las terminales de Jupyter: PTY servido por WebSocket (Tornado).
- **Te aporta:** implementación probada de PTY + WebSocket en Python: gestión de sesiones, redimensionado y cierre limpio (fase 5). También útil para la ejecución de acciones rápidas en segundo plano (fase 7).
- **Uso:** inspiración y posible reutilización de lógica (adaptada de Tornado a FastAPI).
- **Licencia:** BSD-2-Clause.
- **Repositorio:** github.com/jupyter/terminado

### pyxtermjs
- **Qué es:** proyecto mínimo que conecta una shell en un PTY de Python con xterm.js en el navegador. Usa Flask + flask-socketio (no FastAPI), así que la parte del servidor hay que adaptarla.
- **Te aporta:** el ejemplo **más corto y legible** para entender cómo funciona un PTY por WebSocket. Ideal para leer antes de empezar la fase 5.
- **Uso:** inspiración.
- **Licencia:** MIT.
- **Repositorio:** github.com/cs01/pyxtermjs

### Glances
- **Qué es:** monitor de sistema en Python basado en psutil, con modo servidor web que expone una API REST.
- **Te aporta:**
  - qué métricas recoger y cómo estructurarlas en JSON;
  - cómo manejar sensores que no existen en todos los equipos (fase 1).
- **Uso:** inspiración.
- **Licencia:** LGPL-3.0.
- **Repositorio:** github.com/nicolargo/glances

### psutil
- **Qué es:** la librería de métricas que usarás directamente.
- **Te aporta:** su documentación tiene ejemplos listos para CPU, memoria, discos, sensores y procesos (fases 1 y 6).
- **Uso:** dependencia directa.
- **Licencia:** BSD-3-Clause.
- **Repositorio:** github.com/giampaolo/psutil

---

## 3. Acceso remoto (iroh)

### iroh
- **Qué es:** librería P2P que conecta dispositivos por clave pública, con travesía de NAT y relés. Versión 1.0 estable publicada el 15 de junio de 2026; a 02/10/2026 el núcleo va por la 1.3.0 (28/09/2026) y los bindings por la 1.1.0 (16/07/2026).
- **Te aporta:** la base del acceso remoto (fase 2). Bindings oficiales para Python y Kotlin. El paquete de Kotlin publicado no incluye Android: para Android (solo ARM: aarch64 y armv7) hay que compilarlo desde el código fuente con Rust y el NDK.
- **Uso:** dependencia directa.
- **Licencia:** MIT / Apache-2.0.
- **Repositorios:** github.com/n0-computer/iroh (núcleo) · github.com/n0-computer/iroh-ffi (bindings)

### dumbpipe
- **Qué es:** herramienta del equipo de iroh que funciona como un "netcat" P2P: reenvía un puerto TCP de un equipo a otro a través de iroh.
- **Te aporta:** **exactamente el patrón del túnel local** que usa tu diseño. Es corto y muy legible. Además, puedes usar el propio binario para probar el concepto antes de escribir código (prueba de concepto de la fase 2).
- **Uso:** inspiración directa del diseño; herramienta de pruebas.
- **Licencia:** MIT / Apache-2.0.
- **Repositorio:** github.com/n0-computer/dumbpipe

### RustDesk
- **Qué es:** escritorio remoto de código abierto con cliente en Flutter y servidores propios de encuentro (hbbs) y relé (hbbr). Desde la versión 1.4.1 incluye también una función de terminal.
- **Te aporta:** referencia para entender cómo se resuelve la conexión a través de NAT con servidores de encuentro y relé, y un ejemplo de app Flutter grande. Útil para la memoria (estado del arte y justificación de iroh).
- **Uso:** solo inspiración.
- **Licencia:** AGPL-3.0. **No copiar código.**
- **Repositorio:** github.com/rustdesk/rustdesk

---

## 4. Estado del arte (para la memoria)

### KDE Connect
- **Qué es:** integración entre móvil y escritorio: control multimedia, portapapeles, notificaciones, archivos, batería y comandos predefinidos. Funciona en la red local.
- **Te aporta:** el principal punto de comparación. Útil para ver cómo organiza su sistema de *plugins* y cómo resuelve el emparejamiento seguro.
- **Uso:** solo inspiración.
- **Licencia:** GPL. **No copiar código.**
- **Repositorios:** invent.kde.org/network/kdeconnect-kde (escritorio) · invent.kde.org/network/kdeconnect-android (Android)

### Cockpit
- **Qué es:** panel web de administración de servidores Linux: métricas, terminal, servicios, registros, almacenamiento.
- **Te aporta:** referencia de qué funciones de administración considera importantes una herramienta profesional y cómo se integra con systemd y polkit.
- **Uso:** solo inspiración.
- **Licencia:** LGPL-2.1 o posterior (algunos archivos están bajo otras licencias).
- **Repositorio:** github.com/cockpit-project/cockpit

### Clientes SSH móviles (Termius, ConnectBot, JuiceSSH)
- **Qué son:** clientes SSH para Android.
- **Te aportan:** referencia de diseño de la barra de teclas especiales y de la experiencia de terminal en pantalla táctil (fase 5).
- **Uso:** inspiración de interfaz. ConnectBot es de código abierto (Apache-2.0); Termius y JuiceSSH son privativos.

---

## 5. Herramientas para el entorno de pruebas

- **adb (Android Debug Bridge):** incluido en Android Studio. El comando `adb reverse tcp:8443 tcp:8443` permite que la app del móvil conectado por USB llegue al agente del portátil sin usar ninguna red. Es el método principal de pruebas (ver 04-plan-de-fases.md).
- **Emulador de Android (Android Studio):** desde el emulador, `10.0.2.2` apunta al portátil anfitrión.
- **pytest** y **flutter_test:** documentación oficial para las pruebas automáticas del agente y de la app.

---

## 6. Resumen por fase

| Fase | Referencias principales |
|---|---|
| 0 (Preparación y Flutter) | Tutorial oficial de Flutter, documentación de adb y del emulador |
| 1 (Métricas) | psutil, Glances |
| 2 (Conexión remota con iroh) | iroh, iroh-ffi, dumbpipe, iroh-ssh-android, iroh-android-native |
| 3 (Seguridad) | LocalSend (HTTPS con certificados autofirmados en Flutter) |
| 4 (Instalación y servicio) | Documentación de pipx y systemd |
| 5 (Terminal) | xterm.dart, pyxtermjs, terminado, ConnectBot |
| 6 (Energía y procesos) | psutil, Cockpit |
| 7 (CRUD de acciones rápidas) | terminado (procesos en segundo plano), documentación de asyncio y sqlite3 |
| 8 (Notificaciones, reglas de alerta y servicio en primer plano) | iroh-ssh-android (servicio en primer plano), KDE Connect |
| 9 (mDNS, QR, registro y archivos) | LocalSend |
| 10 (Subida y pulido) | LocalSend |
| Memoria | KDE Connect, Cockpit, RustDesk, clientes SSH |
