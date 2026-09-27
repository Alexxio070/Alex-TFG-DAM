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
- Nota técnica: la carátula suele venir como ruta de archivo local, así que el agente tendría que servirla por HTTP.

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

## 2. Notas compartidas 🟡🔴

Sustituye a la idea original de portapapeles compartido.

- Un **espacio común entre PC y móvil** donde dejar texto, enlaces, archivos e imágenes, accesible desde ambos lados.
- A diferencia de un portapapeles, **tiene sentido tanto de cerca como de lejos**: guardar un enlace en el móvil para abrirlo luego en el PC, o dejar un archivo en el PC para recogerlo desde fuera.
- **En el PC:** acceso desde la CLI (`companion note add "texto"`, `companion note add archivo.pdf`) y opcionalmente desde el escritorio.
- **En el móvil:** pantalla de notas, y la opción "Compartir con…" de Android para enviar cualquier cosa desde otras apps.
- **Posibles extras:** fijar notas, caducidad automática, búsqueda, copiar al portapapeles del sistema de un toque.
- **Retos:** sincronización cuando ambos lados modifican a la vez, almacenamiento de archivos grandes y previsualización de imágenes.

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
- Requiere Mac con Xcode y cuenta de desarrollador de Apple de pago.
- iOS es muy restrictivo con las conexiones en segundo plano, lo que afecta a las notificaciones.

### Multi-dispositivo 🟡
- Varios móviles emparejados con el mismo PC, y un móvil con varios PCs.
- Lista de dispositivos con nombre, fecha de emparejamiento, último acceso y botón de revocar.

### Publicación en tiendas 🟢🟡
- Google Play (cuenta de desarrollador y revisión) y F-Droid.
- Paquetes nativos del agente: AUR, `.deb`, `.rpm`.

---

## 5. Terminal

### Temas de la terminal 🟢
*(Si no se completa en el TFG.)*
- Paletas configurables, importación de los colores del esquema del PC y varias fuentes.

### Integración con la shell (*shell integration*) 🟡
- Saber en qué carpeta está la terminal, dónde empieza y termina cada comando y si terminó bien o mal (secuencias OSC 7 y OSC 133).
- Permitiría, por ejemplo, abrir el explorador de archivos en la carpeta actual o notificar automáticamente cuando termine un comando largo sin escribir `companion notify`.
- Requiere configuración específica por shell.

### Varias sesiones y persistencia 🟡
- Varias pestañas de terminal.
- Sesiones que sobreviven a la desconexión del móvil (integración con tmux o Zellij).

---

## 6. Acceso y seguridad

### Desbloqueo biométrico de la app 🟢
- Pedir huella o PIN del móvil al abrir la app o antes de acciones peligrosas (terminal, apagar).
- Reduce el riesgo residual de robo del móvil desbloqueado identificado en el modelo de amenazas.

### 2FA opcional (TOTP) 🟢
- Segunda capa opcional para quien la quiera, sin hacerla obligatoria.

### Modo sin sesión mejorado 🟡
- Con *linger*, ofrecer desde la CLI la instalación guiada de la regla de polkit para permitir apagar y reiniciar sin sesión activa, explicando el riesgo.

### Wake-on-LAN 🔴
- Encender el PC apagado desde el móvil.
- Solo funciona desde la misma red, salvo que otro dispositivo encendido (router, Raspberry Pi) reenvíe el paquete. Requiere activarlo en la BIOS.

### Relé iroh propio 🟡
- Guía y configuración para usar un relé propio en lugar de los públicos, para quien quiera independencia total o más ancho de banda.

---

## 7. Monitorización avanzada

### Historial de métricas 🟡
- Guardar métricas en el tiempo (SQLite) y mostrar gráficas de horas o días.

### Más fuentes de datos 🟡
- GPU (uso y VRAM, NVIDIA y AMD), red (tráfico por interfaz), estado de servicios systemd, contenedores Docker/Podman.

### Alertas más completas 🟢🟡
*(Las reglas de alerta básicas con CRUD desde la app ya forman parte del TFG, fase 9.)*
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
*(Las acciones rápidas con grupos, ejecuciones e historial ya forman parte del TFG, fase 5.)*
- Parámetros al ejecutar (por ejemplo, pedir un nombre de rama antes de lanzar `git checkout`).
- Programar ejecuciones (a una hora o de forma periódica, con temporizadores de systemd).
- Encadenar acciones (ejecutar B solo si A termina bien).
- Exportar e importar acciones para compartirlas entre equipos.
