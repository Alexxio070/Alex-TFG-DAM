// ============================================================================
// LABORATORIO UI — piezas sueltas de interfaz con Flutter
// ============================================================================
// Esta es una app mínima y ejecutable hecha de PIEZAS INDEPENDIENTES.
// Cada pieza lleva su cabecera: QUÉ ES, CÓMO FUNCIONA y CÓMO MODIFICARLA.
// Está pensada para que la cambies, borres y rompas: no hay nada intocable.
// Dart no exige ningún orden entre las piezas; el orden del archivo da igual.
//
// CÓMO EJECUTARLO
//   1. flutter create laboratorio_ui     (crea un proyecto vacío)
//   2. Sustituye el contenido de laboratorio_ui/lib/main.dart por este archivo.
//   3. flutter run                       (en el emulador o en el móvil por USB)
//
// CÓMO VER LOS CAMBIOS
//   Con la app corriendo, cambia algo, guarda el archivo y, en la terminal
//   donde corre "flutter run", pulsa  r  (hot reload: se actualiza en un segundo).
//   Si el cambio afecta al arranque (main, initialRoute), pulsa  R  (hot restart).
//   Si algo falla, el error aparece en esa terminal: léelo, es parte de aprender.
// ============================================================================

import 'package:flutter/material.dart';

// ============================================================================
// PIEZA 1 — ARRANQUE DE LA APP Y TABLA DE RUTAS
// ============================================================================
// QUÉ ES
//   El punto de entrada. Decide qué widget es la raíz de la app y qué pantallas
//   existen, cada una con un NOMBRE (una "ruta", como '/metricas').
//
// CÓMO FUNCIONA
//   - main() es lo primero que Dart ejecuta. runApp() le dice a Flutter
//     "dibuja este widget como raíz de la app".
//   - MaterialApp da el estilo Material a toda la app y gestiona la navegación.
//   - "routes" es una tabla: nombre de ruta -> función que construye la pantalla.
//     Cuando navegas a '/metricas', Flutter busca esa clave y construye lo que
//     devuelve su función.
//   - "initialRoute" es la ruta con la que arranca la app.
//
// CÓMO MODIFICARLA
//   - Cambia seedColor a Colors.deepOrange: cambian los colores de toda la app.
//   - Cambia initialRoute a '/procesos' y pulsa R (hot restart): arrancará ahí.
//   - Borra la línea de '/energia' y pulsa esa opción en el menú: verás el
//     error de ruta no encontrada (la opción sigue en la lista de la PIEZA 2).
//   - Añade una ruta nueva '/ajustes'. Para que funcione de verdad necesitas
//     tocar también la PIEZA 2 (la opción del menú).
void main() {
  runApp(const MiApp());
}

class MiApp extends StatelessWidget {
  const MiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Laboratorio UI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      initialRoute: '/',
      routes: {
        // Cada pantalla es una PantallaEjemplo (PIEZA 4) con datos distintos.
        '/': (context) => const PantallaEjemplo(
              titulo: 'Inicio',
              ruta: '/',
              icono: Icons.home,
              color: Colors.teal,
              // Un widget extra bajo el título: aquí, un botón (PIEZA 6).
              extra: BotonIr(texto: 'Ir a Métricas', ruta: '/metricas'),
            ),
        '/metricas': (context) => const PantallaEjemplo(
              titulo: 'Métricas',
              ruta: '/metricas',
              icono: Icons.show_chart,
              color: Colors.indigo,
            ),
        '/procesos': (context) => const PantallaEjemplo(
              titulo: 'Procesos',
              ruta: '/procesos',
              icono: Icons.list_alt,
              color: Colors.orange,
            ),
        '/energia': (context) => const PantallaEjemplo(
              titulo: 'Energía',
              ruta: '/energia',
              icono: Icons.power_settings_new,
              color: Colors.red,
            ),
      },
    );
  }
}

// ============================================================================
// PIEZA 2 — LAS OPCIONES DEL MENÚ (los datos)
// ============================================================================
// QUÉ ES
//   La lista de opciones que aparecen en el menú lateral, guardada como DATOS,
//   separada del código que dibuja el menú (PIEZA 3).
//
// CÓMO FUNCIONA
//   - OpcionMenu es una clase: agrupa un texto, un icono y una ruta.
//     Su constructor usa parámetros nombrados (lo verás en todo Flutter).
//   - "ruta" debe coincidir EXACTAMENTE con una clave de la tabla de la PIEZA 1.
//   - opcionesMenu es la lista. El orden aquí es el orden del menú.
//
// CÓMO MODIFICARLA
//   - Cambia el orden de dos opciones: cambia el orden del menú.
//   - Añade una opción nueva con otro icono (Icons.settings, Icons.terminal...)
//     y una ruta nueva; luego añade esa ruta en la PIEZA 1.
//   - Pon una ruta mal escrita ('/metrica' en vez de '/metricas'): al pulsarla
//     verás el error. Así se entiende por qué deben coincidir.
class OpcionMenu {
  final String titulo;
  final IconData icono;
  final String ruta;

  const OpcionMenu({
    required this.titulo,
    required this.icono,
    required this.ruta,
  });
}

const List<OpcionMenu> opcionesMenu = [
  OpcionMenu(titulo: 'Inicio', icono: Icons.home, ruta: '/'),
  OpcionMenu(titulo: 'Métricas', icono: Icons.show_chart, ruta: '/metricas'),
  OpcionMenu(titulo: 'Procesos', icono: Icons.list_alt, ruta: '/procesos'),
  OpcionMenu(
    titulo: 'Energía',
    icono: Icons.power_settings_new,
    ruta: '/energia',
  ),
];

// ============================================================================
// PIEZA 3 — EL MENÚ LATERAL (Drawer)
// ============================================================================
// QUÉ ES
//   El panel que se desliza desde la izquierda con las opciones.
//
// CÓMO FUNCIONA
//   - Drawer es el panel. Dentro, un ListView (lista vertical con scroll).
//   - DrawerHeader es la cabecera decorativa de arriba.
//   - El "for" dentro de la lista crea un ListTile (una fila pulsable) por cada
//     elemento de opcionesMenu (PIEZA 2). Si añades una opción allí, aparece aquí.
//   - "selected" resalta la fila de la pantalla actual. Recibe rutaActual
//     desde fuera (el menú no recuerda nada por su cuenta: es StatelessWidget).
//   - onTap es lo que ocurre al pulsar una fila:
//       1) Navigator.pop(context): mientras el menú está abierto, esto lo cierra.
//       2) Si pulsaste la pantalla en la que ya estás, no hace nada más.
//       3) Si no, irA(...) (PIEZA 5) cambia de pantalla.
//
// CÓMO MODIFICARLA
//   - Cambia el color de la cabecera (Colors.teal) o el texto.
//   - Quita la línea "Navigator.pop(context);" y observa con atención qué le
//     pasa al menú durante el cambio de pantalla. Piensa por qué.
//   - Quita la línea "selected: ...": desaparece el resaltado.
//   - Cambia el icono de una fila a otro de Icons.*.
class MenuLateral extends StatelessWidget {
  const MenuLateral({super.key, required this.rutaActual});

  final String rutaActual;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero, // quita el hueco que ListView deja arriba
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.teal),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'Laboratorio UI',
                style: TextStyle(color: Colors.white, fontSize: 22),
              ),
            ),
          ),
          for (final opcion in opcionesMenu)
            ListTile(
              leading: Icon(opcion.icono),
              title: Text(opcion.titulo),
              selected: opcion.ruta == rutaActual,
              onTap: () {
                Navigator.pop(context); // cierra el menú
                if (opcion.ruta == rutaActual) return;
                irA(context, opcion.ruta);
              },
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// PIEZA 4 — UNA PANTALLA (Scaffold + barra superior + menú + contenido)
// ============================================================================
// QUÉ ES
//   Una pantalla completa y reutilizable. Las cuatro pantallas de la app son
//   esta misma clase con datos distintos (título, icono, color).
//
// CÓMO FUNCIONA
//   - Scaffold es la plantilla estándar de una pantalla Material, con huecos
//     con nombre: appBar (barra superior), drawer (menú lateral), body (contenido).
//   - AppBar es la barra superior. Como le damos un "drawer" al Scaffold y no
//     le ponemos un "leading" propio, Flutter añade SOLO el icono ☰ que abre
//     el menú. No hay que programarlo.
//   - body: Center + Column pone el icono grande, el título y, si existe, el
//     widget "extra" (el signo "?" en "Widget? extra" significa que puede ser null).
//   - "if (extra != null) ...[ ... ]" añade esos widgets a la columna solo
//     cuando hay "extra".
//
// CÓMO MODIFICARLA
//   - Cambia el tamaño del icono (size: 96) o el espacio (SizedBox height).
//   - Cambia backgroundColor de la AppBar o del Scaffold (shade50, shade200...).
//   - Quita la línea "drawer: ...": desaparece el icono ☰. ¿Por qué?
//   - Cambia Column por Row: los elementos pasan de vertical a horizontal.
//   - Pasa un "extra" a otra pantalla en la PIEZA 1 (por ejemplo un BotonIr
//     con ruta '/') y mira cómo aparece el botón.
class PantallaEjemplo extends StatelessWidget {
  const PantallaEjemplo({
    super.key,
    required this.titulo,
    required this.ruta,
    required this.icono,
    required this.color,
    this.extra,
  });

  final String titulo;
  final String ruta; // se pasa al menú para resaltar la opción actual
  final IconData icono;
  final MaterialColor color; // MaterialColor permite usar color.shade50, etc.
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color.shade50,
      appBar: AppBar(
        title: Text(titulo),
        backgroundColor: color.shade200,
      ),
      drawer: MenuLateral(rutaActual: ruta),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min, // la columna ocupa solo lo necesario
          children: [
            Icon(icono, size: 96, color: color),
            const SizedBox(height: 16), // hueco vertical
            Text(titulo, style: Theme.of(context).textTheme.headlineMedium),
            if (extra != null) ...[
              const SizedBox(height: 24),
              extra!, // "!" = "sé que aquí no es null"
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// PIEZA 5 — CAMBIAR DE PANTALLA
// ============================================================================
// QUÉ ES
//   La función que cambia de pantalla. La usan el menú (PIEZA 3) y el botón
//   (PIEZA 6), así que el "cómo se cambia" vive en un único sitio.
//
// CÓMO FUNCIONA
//   - Navigator mantiene una PILA de pantallas (como una pila de platos: ves la
//     de arriba).
//   - pushReplacementNamed busca la ruta por su nombre en la tabla de la
//     PIEZA 1 y SUSTITUYE la pantalla actual por la nueva, sin apilar.
//   - Para un menú principal conviene sustituir: si apilaras, tras pulsar cinco
//     opciones tendrías cinco pantallas encima unas de otras.
//   - "context" le dice a Navigator desde qué punto del árbol de widgets se
//     pide navegar.
//
// CÓMO MODIFICARLA
//   - Cambia pushReplacementNamed por pushNamed (apila). Ve Inicio -> Métricas
//     -> Procesos y pulsa el botón atrás del móvil varias veces: ¿qué cambia?
//   - Con pushReplacementNamed, el botón atrás desde cualquier pantalla cierra
//     la app (no hay nada debajo en la pila). Compruébalo.
//   - Navigator.pop(context) desde una pantalla apilada (con pushNamed) vuelve
//     a la anterior. Pruébalo con un botón nuevo.
void irA(BuildContext context, String ruta) {
  Navigator.pushReplacementNamed(context, ruta);
}

// ============================================================================
// PIEZA 6 — UN BOTÓN QUE CAMBIA DE PANTALLA
// ============================================================================
// QUÉ ES
//   Un botón normal (sin menú) que lleva a otra pantalla.
//
// CÓMO FUNCIONA
//   - FilledButton es un botón relleno. "child" es lo que se ve dentro y
//     "onPressed" la función que se ejecuta al pulsarlo.
//   - "() => irA(...)" es una función anónima: se define ahí mismo y se
//     ejecuta solo cuando se pulsa, no al construir el botón.
//
// CÓMO MODIFICARLA
//   - Cambia el texto o la ruta.
//   - Cambia FilledButton por OutlinedButton, TextButton o ElevatedButton.
//   - Pon onPressed: null y mira cómo el botón aparece deshabilitado.
//   - Pon onPressed: () { print('pulsado'); } y mira la terminal.
//   - Usa este botón en otra pantalla: pásalo como "extra" en la PIEZA 1.
class BotonIr extends StatelessWidget {
  const BotonIr({super.key, required this.texto, required this.ruta});

  final String texto;
  final String ruta;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () => irA(context, ruta),
      child: Text(texto),
    );
  }
}
