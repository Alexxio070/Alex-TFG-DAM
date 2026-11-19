// Colores, fuentes y medidas compartidas por toda la app (tokens del diseño).

import 'package:flutter/material.dart';

/// Colores de acento que se pueden elegir en Ajustes (tema claro).
const kAccentColors = [
  Color(0xFF0F6B63),
  Color(0xFF3346C7),
  Color(0xFFB4235A),
  Color(0xFFC2410C),
  Color(0xFF6D28D9),
  Color(0xFF3F4652),
];

/// Nombre visible de cada color de [kAccentColors], en el mismo orden.
const kAccentNames = [
  'Verde azulado',
  'Azul',
  'Frambuesa',
  'Naranja',
  'Violeta',
  'Grafito',
];

/// Misma versión de cada color de kAccentColors, aclarada en luminosidad hasta
/// alcanzar un contraste de ~4,5:1 contra el fondo oscuro (#111316), calculado
/// con la fórmula de contraste WCAG. Solo se usan en tema oscuro.
const kAccentColorsDark = [
  Color(0xFF148C81),
  Color(0xFF6675D8),
  Color(0xFFDA437D),
  Color(0xFFDE4A0E),
  Color(0xFF9462E3),
  Color(0xFF717E92),
];

/// Rojo de errores y acciones destructivas.
const kRed = Color(0xFFB42318);
/// Verde de confirmaciones y del estado «Conectado».
const kGreen = Color(0xFF1F9D55);

/// Color de las sombras de las fichas de Inicio y de los menús flotantes.
const kShadowColor = Color(0xFF16181D);

/// Velo oscuro que va detrás de los diálogos y del menú lateral.
const kScrim = Color.fromRGBO(22, 24, 29, 0.45);

/// Fondo de la terminal. Toda su paleta es fija: no depende del tema claro u oscuro.
const kTerminalBackground = Color(0xFF0D0F12);

/// Color del texto y del cursor de la terminal.
const kTerminalForeground = Color(0xFFE6E8EB);

/// Fondo de la barra de pestañas y de la fila de teclas extra.
const kTerminalBarBackground = Color(0xFF15171A);

/// Borde de la barra de pestañas y de la fila de teclas extra.
const kTerminalBarBorder = Color(0xFF2B2F34);

/// Verde de la terminal: el texto verde de xterm y el usuario del prompt.
const kTerminalGreen = Color(0xFF7EE787);

/// Azul de la terminal: el texto azul de xterm y la ruta del prompt.
const kTerminalBlue = Color(0xFF79C0FF);

/// Fuente monoespaciada de la interfaz (comandos, puntos de montaje).
const kMonoFont = 'JetBrainsMono';

/// Ancho del menú lateral.
const kDrawerWidth = 280.0;

/// Colores que cambian entre tema claro y oscuro. Se leen con `context.tokens`.
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.bg,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.muted2,
    required this.border,
    required this.line,
    required this.borderStrong,
    required this.field,
    required this.off,
    required this.segOn,
    required this.greenText,
    required this.accent,
  });

  final Color bg;
  final Color surface;
  final Color ink;
  final Color muted;
  final Color muted2;
  final Color border;
  final Color line;
  final Color borderStrong;
  final Color field;
  final Color off;
  final Color segOn;
  final Color greenText;
  final Color accent;

  static const light = AppTokens(
    bg: Color(0xFFF3F4F6),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF16181D),
    muted: Color(0xFF5B616E),
    muted2: Color(0xFF4A505C),
    border: Color(0xFFE4E6EA),
    line: Color(0xFFEEF0F2),
    borderStrong: Color(0xFFD5D8DE),
    field: Color(0xFFF7F8FA),
    off: Color(0xFFB9BEC7),
    segOn: Color(0xFFFFFFFF),
    greenText: Color(0xFF146C43),
    accent: Color(0xFF0F6B63),
  );

  static const dark = AppTokens(
    bg: Color(0xFF111316),
    surface: Color(0xFF1B1E23),
    ink: Color(0xFFECEEF1),
    muted: Color(0xFFA3A9B4),
    muted2: Color(0xFFB8BDC6),
    border: Color(0xFF2C3037),
    line: Color(0xFF262A30),
    borderStrong: Color(0xFF3A3F47),
    field: Color(0xFF15181C),
    off: Color(0xFF4A4F58),
    segOn: Color(0xFF3A3F47),
    greenText: Color(0xFF5BD38C),
    accent: Color(0xFF0F6B63),
  );

  @override
  AppTokens copyWith({Color? accent}) => AppTokens(
        bg: bg,
        surface: surface,
        ink: ink,
        muted: muted,
        muted2: muted2,
        border: border,
        line: line,
        borderStrong: borderStrong,
        field: field,
        off: off,
        segOn: segOn,
        greenText: greenText,
        accent: accent ?? this.accent,
      );

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) =>
      other is AppTokens && t >= 0.5 ? other : this;
}

/// Atajo `context.tokens` para leer los [AppTokens] del tema actual.
extension AppTokensContext on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
}
