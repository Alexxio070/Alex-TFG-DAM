# Resumen de la conversación de diseño: decisiones y contexto

Este documento complementa a los archivos 01–06. Aquellos describen **qué** es el proyecto; este recoge **por qué** se ha llegado a cada decisión, qué se descartó y con qué motivo, qué queda pendiente y cómo quiere trabajar el autor. Sirve como contexto para cualquier conversación futura sobre el proyecto.

---

## 1. Quién soy y qué es esto

- Estudiante de **DAM (Desarrollo de Aplicaciones Multiplataforma)**. Este es mi proyecto final.
- **No tengo experiencia en desarrollo Android ni en Flutter.** En clase he visto Kotlin a un nivel muy básico que apenas aporta a este proyecto. Voy a aprender sobre la marcha, así que necesito metas pequeñas y asequibles y explicaciones claras.
- Mi entorno personal es **KDE Plasma** sobre Linux.
- El punto de partida fueron tres documentos generados con otra IA (memoria técnica, justificación del stack y un "system context" en inglés). Los revisamos, tenían incoherencias entre sí y errores técnicos, y se rehicieron por completo en los documentos 01–06.

---

## 2. La idea central (lo más importante)

**Linux System Companion es una app para administrar mi PC Linux desde el móvil cuando NO estoy delante de él**, desde casa o desde cualquier sitio.

**Criterio de alcance:** si una función solo tiene sentido estando delante o cerca del PC, **queda fuera del TFG**. Este criterio decidió qué se mantenía y qué se descartaba.

**Frase para la defensa:** *KDE Connect es una herramienta para cuando estás cerca del PC; Linux System Companion es para cuando no lo estás.*

**Requisito de experiencia de usuario:**
- En el móvil, **solo descargar la app**; nada de instalar VPNs ni otras apps.
- En el PC se aceptan dependencias.
- **Nunca configurar el router.**
- Flujo deseado: instalar agente → configurar credenciales → instalar app → iniciar sesión → conectar desde cualquier parte.

**Filosofía de desarrollo:** la primera versión (beta) debe tener **pocas funciones, pero todas funcionando**: una base sólida sobre la que ampliar. Esto debe reflejarse en toda la documentación.

---

## 3. Registro de decisiones

### 3.1 Tecnología

| Decisión | Elegido | Motivo | Descartado |
|---|---|---|---|
| Framework móvil | **Flutter** | Se valora usar tecnología no vista en clase; xterm.dart resuelve la terminal (la pieza más difícil); *hot reload* ayuda a aprender | Kotlin + Compose: más fácil para iroh (binding oficial), pero sin emulador de terminal equivalente. **Queda como plan B** si el centro no acepta Flutter |
| Agente PC | Python 3.11 + FastAPI | Mejores librerías de sistema; asíncrono | Go, Rust (curva), Flask (síncrono) |
| Acceso remoto | **iroh**, túnel local (patrón dumbpipe), **última fase técnica** | Cero configuración para el usuario, sin servidores propios, y si falla se cae automáticamente a "solo LAN" | Tailscale (obliga a app VPN en el móvil), WebRTC con STUN/TURN (servidores propios), relé propio (el peor: cifrado propio y servidor que pagar), Cloudflare Tunnel |
| Puente Flutter ↔ iroh | Platform channel mínimo en Kotlin: `openTunnel` / `closeTunnel` | Flutter no sabe que iroh existe; usa el mismo código que en LAN | flutter_rust_bridge (exige compilar Rust y el NDK) |
| Tokens | Opacos, con hash en SQLite | Revocables al instante (`logout-all`) | JWT (no revocables; innecesarios con un solo dispositivo) |
| BD | SQLite con `sqlite3` + patrón repositorio + `schema.sql` | Sencillo, sin servidor, cumple la normativa | SQLAlchemy (excesivo), MySQL, Firebase |
| Instalación del agente | **pipx** | Usa el Python de la distro; evita problemas de glibc (me recomendaron alejarme de glibc) | PyInstaller (atado a la glibc de compilación), pip directo (bloqueado en distros modernas), Flatpak (su aislamiento impide PTY y D-Bus) |
| Servicio | systemd de usuario con `default.target` + linger opcional | Al quitar lo gráfico, no hace falta la sesión gráfica | `graphical-session.target` (propuesta inicial, se cambió) |
| CLI | Typer | Sencillo | argparse |
| Arquitectura app | MVVM con provider + repositorios simulados | Capas claras (requisito); permite trabajar sin el agente | BLoC (demasiado para quien empieza) |

### 3.2 Seguridad
- **Login con credenciales creadas por CLI** (`companion setup`). Prefiero CLI antes que TUI.
- **Registro desde la app:** **pendiente de revisión**. La alternativa es un código de un solo uso generado por la CLI y un formulario de registro en la app. Colocado provisionalmente en la fase 7.
- **TLS autofirmado con certificate pinning.** En la beta la huella se compara a ojo; más tarde, por QR.
- **2FA descartado** porque choca con la configuración mínima. Se compensa con contraseña robusta, límite de intentos y revocación.
- **Un solo dispositivo.** Multi-dispositivo como idea futura.
- **El agente nunca usa root ni sudo.** Para operaciones de root sobre archivos, la app avisa de que hay que usar la terminal.

### 3.3 Terminal
- Se lanza `$SHELL -l` de forma genérica. **No hay que programar soporte por shell**: el PTY funciona igual con Bash, Zsh y Fish. **Shell probada oficialmente: Zsh.**
- La paleta y la fuente las pone el móvil, no la shell. Hay que incluir una Nerd Font.
- Temas de terminal: "si da tiempo".

### 3.4 Notificaciones (dentro del TFG)
- Quiero recibir en el móvil avisos del PC, por ejemplo cuando **Claude Code termine de trabajar**, cuando un proceso de terminal termine o arranque bien, o si hay **CPU o RAM elevadas**.
- Diseño:
  - `companion notify "mensaje"` por socket Unix (sirve para scripts y *hooks* de Claude Code);
  - reglas de alerta por umbral;
  - servicio en primer plano en Android que reutiliza el del túnel iroh.
- **Sin Firebase.** Funciona también en LAN, sin iroh.

### 3.5 Requisitos mínimos de DAM
Se evaluó el proyecto contra la normativa del centro. Huecos detectados y cómo se resolvieron:
- **CRUD de 2 entidades relacionadas:** no existía. Se añadieron las **acciones rápidas**: `grupo` 1:N `accion_rapida` 1:N `ejecucion`, con CRUD completo de grupos y acciones. Refuerzo con `regla_alerta` 1:N `notificacion`.
- **BD de 3–4 tablas:** ahora son 8 tablas, con `schema.sql` y repositorios.
- **Diseño de BD, casos de uso, pruebas y capturas en la memoria:** añadidos a la documentación y al plan.
- **Elemento diferenciador:** cubierto de sobra (cámara/QR, servicio en segundo plano con notificaciones, P2P, PTY).
- **Riesgo abierto:** la normativa cita "Android Studio, Kotlin, Java" y **Flutter no aparece**. Hay que preguntar al tutor por escrito antes de empezar.

---

## 4. Lo descartado y por qué

**Descartado por no tener sentido estando lejos del PC** (va a *06-ideas-de-futuro.md* como posible "modo cercanía"):
- control multimedia (MPRIS);
- mezclador de volumen por aplicación y cambio de salida de audio. Mi motivo: "¿para qué querría modificar el volumen de una app si no estoy delante del PC?";
- batería de periféricos;
- abrir URLs en el PC;
- notificaciones del móvil al escritorio;
- ricing de KDE y personalización en general;
- portapapeles compartido. Se reconvierte en idea futura de **notas compartidas**: texto, enlaces, archivos e imágenes entre PC y móvil.

**Descartado por complejidad o por chocar con otros requisitos:**
- Wake-on-LAN;
- 2FA;
- alertas con Firebase;
- soporte para otros escritorios o gestores de ventanas (solo KDE; expandir en el futuro);
- iOS (muy a futuro, fuera del alcance).

---

## 5. Planificación (resumen; detalle en 04)

**Criterios:**
- lo obligatorio y lo de más impacto en la nota, primero;
- fases difíciles intercaladas con fáciles para no dejar lo importante al final;
- lo de menor impacto, al final como "si da tiempo";
- beta funcional a **mediados de diciembre**.

**Beta v0.1:**
- Fase 0: preparación y aprender Flutter.
- Fase 1: métricas.
- Fase 2: seguridad.
- Fase 3: energía y procesos.
- Fase 4: instalación con pipx y servicio.
- **La beta NO necesita cumplir todos los mínimos de DAM.** El CRUD se sacó de la beta a propósito.

**Después de la beta:**
- Prueba de concepto de iroh (enero, 2–3 días, también desde la red del centro).
- Fase 5: CRUD de acciones rápidas (va primera por ser obligatoria).
- Fase 6: terminal.
- Fase 7: mDNS, QR, registro (pendiente) y archivos.
- Fase 8: iroh.
- Fase 9: notificaciones y reglas.
- Fase 10: subida de archivos y pulido.

**Orden de recorte si voy con retraso:** subida de archivos → reglas de alerta → mDNS → iroh (plan B). **Nunca se recortan:** CRUD, terminal, login y TLS.

**Fecha de entrega real:** desconocida todavía. Las fechas del plan suponen mayo; hay que ajustarlas cuando la sepa.

---

## 6. Entorno de pruebas

La red del centro está muy blindada y probablemente el móvil no pueda llegar al PC por ella. Solución sin depender de ninguna red:
- **USB + `adb reverse tcp:8443 tcp:8443`** como método principal (la app se conecta a `127.0.0.1:8443`, la misma dirección que usará el túnel de iroh);
- emulador de Android Studio (`10.0.2.2` = anfitrión);
- punto de acceso del móvil para probar como LAN real;
- repositorios simulados en la app.

Para la defensa: USB o punto de acceso, más un vídeo de respaldo.

---

## 7. Forma de trabajar con Claude

- **Proyecto de Claude:** subir los documentos 01–07 al conocimiento del proyecto. Opcionalmente, conectar el repositorio de GitHub mediante la integración oficial, seleccionando solo archivos de referencia (`schema.sql`, modelos, rutas de la API). **Sincronizar manualmente con "Sync"** antes de cada sesión, porque no es automático.
- **No usar el conocimiento del proyecto como repositorio manual** del código: se queda desactualizado. El repositorio real es Git/GitHub.
- **Reparto de herramientas:**
  - chat o proyecto para planificar, entender conceptos y redactar la memoria;
  - Claude Code para escribir y depurar código.
- **Aprendizaje:** usar Claude como profesor y revisor más que como autor. Tengo que entender y poder defender todo el código.
- **Preferencia de trabajo:** antes de generar documentos, quiero que se me diga **cuántos y qué contendrá cada uno**, y que las propuestas vengan **numeradas** para que yo decida qué se añade y qué no.

---

## 8. Open source y uso de IA

- Cuando termine el TFG, **la app se publicará como open source**.
- Preocupación: a mucha gente le echan para atrás las apps "vibecodeadas".
- **Commits:** en Claude Code, desactivar la firma con `"attribution": {"commit": "", "pr": ""}` en `settings.json`, o hacer yo los commits. Los commits antiguos con firma se pueden limpiar con `git filter-repo` **después de la evaluación**.
- **Lo que genera confianza de verdad:**
  - commits pequeños y concretos;
  - tests y CI;
  - un README honesto escrito por mí;
  - código coherente que sé mantener;
  - responder a issues con criterio.
- Postura recomendada: declarar el uso de IA de forma breve ("asistido por IA, revisado y mantenido por el autor") en vez de ocultarlo.
- **Para el TFG:** revisar la política del centro sobre IA y, si está permitida, declararla en la memoria.

---

## 9. Pendientes inmediatos

1. **Preguntar al tutor por escrito:**
   - ¿se acepta Flutter?
   - ¿cuenta el agente en Python como parte del proyecto?
   - ¿qué política hay sobre el uso de IA?
2. Averiguar la **fecha de entrega** y ajustar el plan.
3. Decidir sobre el **registro desde la app** (antes de la fase 7).
4. Revisar las **licencias** marcadas como "verificar" en el documento 05 antes de reutilizar código.

---

## 10. Qué NO está en estos documentos

- **La normativa oficial de requisitos mínimos del proyecto de DAM.** Aquí solo está resumida (03, sección 2) y cruzada con el plan (04, tabla final). **Súbela también al proyecto** tal cual la da el centro.
- **Los tres documentos originales generados con otra IA.** Están obsoletos y sustituidos por los 01–03; no hace falta conservarlos.
- **Explicaciones didácticas** que se dieron en la conversación (qué es un platform channel, cómo funciona un PTY, etc.). Son conocimiento general que se puede volver a preguntar.
