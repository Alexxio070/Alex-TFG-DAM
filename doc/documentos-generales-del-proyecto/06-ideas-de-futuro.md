# Ideas de Futuro: Linux System Companion (después del TFG)

Este documento recoge las funciones descartadas del alcance del TFG y las ideas para seguir desarrollando la app una vez presentado. No forma parte de la planificación del TFG.

**Por qué se descartaron:** el TFG se centra en la administración remota ("funciones que tienen sentido cuando no estás delante del PC"). Muchas de las ideas de aquí solo tienen sentido estando cerca del equipo, y encajarían en un futuro **modo cercanía**.

**Dificultad estimada:** 🟢 fácil · 🟡 media · 🔴 difícil

---

## 1. Modo cercanía (LAN, estando cerca del PC)

Un modo adicional de la app, pensado para cuando estás en la misma habitación o la misma red. Convierte la app en un mando para el PC, y solo se muestra cuando el PC está en la red local.

### Control multimedia 🟢
- Play/pausa, pista anterior y siguiente, volumen general, título, artista y carátula de lo que suena.
- Funciona con cualquier reproductor compatible con **MPRIS2** (Spotify, VLC, navegadores…) a través de D-Bus.
- Nota técnica: la especificación da la carátula como una URL (`mpris:artUrl`), que puede ser un archivo local (`file://`) o una dirección http(s). Si es local, el agente tendría que servirla por HTTP.

### Mezclador de volumen por aplicación 🟡
- Ajustar el volumen de cada aplicación por separado (por ejemplo, bajar la música sin tocar la llamada).
- Cambiar la salida de audio (altavoces o auriculares).
- Vía PipeWire (librería `pulsectl` o comando `pactl`).

### Batería de periféricos 🟢
- Nivel de batería de ratones, teclados y auriculares inalámbricos vía **UPower** por D-Bus.
- Limitación: no todos los dispositivos Bluetooth informan de su batería.

### Abrir enlaces en el PC 🟢
- Enviar una URL o una búsqueda desde el móvil y abrirla en el navegador del PC (`xdg-open`).
- Requiere que el agente conozca las variables de la sesión gráfica (`WAYLAND_DISPLAY`/`DISPLAY`).

### Notificaciones del móvil al escritorio 🟢
- Enviar avisos desde el móvil que aparezcan en el escritorio del PC (especificación Desktop Notifications por D-Bus).

---

## 2. Archivos y ampliaciones del espacio compartido

*(El espacio compartido de notas de texto y enlaces entre el móvil y el PC sí forma parte del TFG, fase 9, desde el 12/10/2026. Aquí queda lo que se dejó fuera.)*

### Explorador y transferencia de archivos 🟡
- Navegar por el sistema de archivos del PC desde el móvil, descargar archivos al móvil y subirlos al PC (por ejemplo, a la carpeta de descargas del usuario).
- Los permisos los aplica el sistema operativo; si algo requiere root, la app avisa de que hay que usar la terminal (el agente nunca usa `sudo`).
- Hay que normalizar y validar cada ruta para evitar accesos fuera de lo permitido.
- Referencia: LocalSend (transferencia de archivos en Flutter).

### Imágenes en el espacio compartido 🟡 *(aún pensándolo)*
- Subir imágenes desde el móvil y verlas en el PC (y al revés), con un tamaño máximo.
- **Retos:** almacenamiento en el agente, previsualización y límites de tamaño.
- Si se decide incluirlas en el TFG, irían en la fase 9 junto al resto del espacio compartido.

### Otras ampliaciones del espacio compartido 🟢🟡
- Opción "Compartir con…" de Android para enviar texto o enlaces al espacio compartido desde otras apps.
- Fijar notas y caducidad automática. *(Copiar una nota al portapapeles de un toque ya está en el TFG.)*
- Fusión de cambios cuando los dos lados editan la misma nota (en el TFG se guarda el último cambio).
- Actualización al momento de las notas por el canal de eventos (en el TFG se actualizan al abrir la pantalla o al recargar).

---

## 3. Personalización del escritorio (ricing) 🟡

- Cambiar fondo de pantalla, esquema de color, tema global y cursor de KDE Plasma desde el móvil (`plasma-apply-wallpaperimage`, `plasma-apply-colorscheme`, `plasma-apply-lookandfeel`, scripting de plasmashell por D-Bus).
- Galería de temas con previsualización.
- Generación de paletas a partir del fondo (Pywal, Matugen) y aplicación en caliente.

---

## 4. Más entornos y plataformas

### Otros escritorios y gestores de ventanas 🟡
- GNOME (`gsettings`), Hyprland, Sway, i3 (swww, Waybar, Polybar, feh).
- Diseño recomendado: detectar el entorno con `$XDG_CURRENT_DESKTOP` y usar un "adaptador" por entorno (patrón estrategia).

### iOS 🔴
- Flutter permite compilar para iOS con la misma base de código.
- Requiere Mac con Xcode. Para probar en un iPhone propio basta un Apple ID gratuito, con límites: los perfiles caducan a los 7 días (hay que recompilar y reinstalar), como máximo 3 apps por dispositivo y 3 dispositivos. La cuenta de desarrollador de pago es necesaria para distribuir la app y para las capacidades avanzadas.
- iOS es muy restrictivo con las conexiones en segundo plano, lo que afecta a las notificaciones.

### Multi-dispositivo 🟡
- Varios móviles emparejados con el mismo PC, y un móvil con varios PCs.
- Lista de dispositivos con nombre, fecha de emparejamiento, último acceso y botón de revocar.

### Publicación en tiendas 🟢🟡
- Google Play (cuenta de desarrollador y revisión) y F-Droid.
- En Google Play, las cuentas personales nuevas deben hacer antes una prueba cerrada con al menos 12 testers durante 14 días seguidos.
- Verificación de desarrolladores de Android: en 2027 se extiende a todo el mundo y a todas las apps instaladas en dispositivos Android certificados, también las que se distribuyen fuera de Google Play. Para publicar en F-Droid o repartir el APK de las releases habrá que registrar al desarrollador y la app (Android Developer Console). Para estudiantes existe una cuenta de distribución limitada: hasta 20 dispositivos, sin documento de identidad ni tasa de registro.
- *Pendiente de revisión: cómo afecta a la distribución del APK del TFG.*
- Paquetes nativos del agente: AUR, `.deb`, `.rpm`.

---

## 5. Terminal

### Temas de la terminal 🟢
*(Si no se completa en el TFG.)*
- Paletas configurables, importación de los colores del esquema del PC y varias fuentes.

### Integración con la shell (*shell integration*) 🟡
- Saber en qué carpeta está la terminal, dónde empieza y termina cada comando y si terminó bien o mal (secuencias OSC 7 y OSC 133).
- Permitiría, por ejemplo, abrir el explorador de archivos (si se llega a hacer, ver sección 2) en la carpeta actual o notificar automáticamente cuando termine un comando largo sin escribir `companion notify`.
- Requiere configuración específica por shell.

### Alternativas al multiplexor de terminal 🟡
*(tmux ya forma parte del TFG, fase 4. Las pestañas de terminal ya tienen maqueta de UI, fase 0; conectarlas a sesiones reales es parte de la fase 4, ver `04-plan-de-fases.md`.)*
- Zellij como alternativa a tmux.

### Cliente de sesiones propio, sin tmux 🟢 *(muy largo plazo)*
- Sustituir tmux por un gestor de sesiones propio en el agente: PTY propio por sesión, buffer circular de salida y un cliente (`companion attach`) que ejecuta la ventana del PC.
- Objetivo: **eliminar la dependencia de tmux** en el PC.
- Contrapartida: más código y mantenimiento; hay que reimplementar lo que tmux ya ofrece, y las sesiones no sobrevivirían a un reinicio del agente salvo que se diseñe expresamente.
- Detalle en `../agente/terminal-sesiones-tmux.md`, sección 11.

---

## 6. Acceso y seguridad

### Desbloqueo biométrico de la app 🟢
- Pedir huella o PIN del móvil al abrir la app o antes de acciones peligrosas (terminal, apagar).
- Reduce el riesgo residual de robo del móvil desbloqueado identificado en el modelo de amenazas.

### 2FA opcional (TOTP) 🟢
- Segunda capa opcional para quien la quiera, sin hacerla obligatoria.

### Modo sin sesión mejorado 🟡
- Con *linger*, ofrecer desde la TUI la instalación guiada de la regla de polkit para permitir apagar y reiniciar sin sesión activa, explicando el riesgo.

### Wake-on-LAN 🔴
- Encender el PC apagado desde el móvil.
- Solo funciona desde la misma red, salvo que otro dispositivo encendido (router, Raspberry Pi) reenvíe el paquete. Requiere activarlo en la BIOS y también en la tarjeta de red desde el sistema (por ejemplo, `WakeOnLan=magic` en systemd.link).

### Relé iroh propio 🟡
- Guía y configuración para usar un relé propio en lugar de los públicos, para quien quiera independencia total o más ancho de banda. La documentación de iroh indica que los relés públicos son para desarrollo y pruebas, no para producción.

---

## 7. Monitorización avanzada

### Historial de métricas 🟡
- Guardar métricas en el tiempo (SQLite) y mostrar gráficas de horas o días.

### Más fuentes de datos 🟡
- GPU (uso y VRAM, NVIDIA y AMD), red (tráfico por interfaz), estado de servicios systemd, contenedores Docker/Podman.

### Alertas más completas 🟢🟡
*(Las reglas de alerta básicas con CRUD desde la app ya forman parte del TFG, fase 8.)*
- Silenciar alertas por horario ("no molestar").
- Alertas cuando un servicio systemd falla.
- Reglas combinadas (por ejemplo, CPU alta **y** temperatura alta).

---

## 8. Otras ideas

### Capturas de pantalla remotas 🟡
- Ver qué hay en la pantalla del PC sin control remoto completo. En Wayland requiere pasar por el portal de capturas.

### Widgets de Android 🟡
- Widget en la pantalla de inicio con el estado del PC y botones rápidos.

### Acciones rápidas avanzadas 🟡
*(Las acciones rápidas con grupos, ejecuciones e historial ya forman parte del TFG, fase 7.)*
- Parámetros al ejecutar (por ejemplo, pedir un nombre de rama antes de lanzar `git checkout`).
- Programar ejecuciones (a una hora o de forma periódica, con temporizadores de systemd).
- Encadenar acciones (ejecutar B solo si A termina bien).
- Exportar e importar acciones para compartirlas entre equipos.
