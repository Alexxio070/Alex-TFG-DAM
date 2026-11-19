// Construye el ThemeData de la app a partir del tema y el color de acento de Ajustes.

import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// Tema claro u oscuro con el acento elegido; añade los [AppTokens] como extensión.
ThemeData buildTheme({required bool dark, required Color accent}) {
  final resolvedAccent = dark ? _forDark(accent) : accent;
  final tokens = (dark ? AppTokens.dark : AppTokens.light).copyWith(accent: resolvedAccent);
  final brightness = dark ? Brightness.dark : Brightness.light;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: 'PlusJakartaSans',
    scaffoldBackgroundColor: tokens.bg,
    colorScheme: ColorScheme.fromSeed(seedColor: resolvedAccent, brightness: brightness)
        .copyWith(primary: resolvedAccent, surface: tokens.surface, onSurface: tokens.ink),
    extensions: [tokens],
  );
}

Color _forDark(Color accent) {
  final index = kAccentColors.indexOf(accent);
  return index >= 0 ? kAccentColorsDark[index] : accent;
}
