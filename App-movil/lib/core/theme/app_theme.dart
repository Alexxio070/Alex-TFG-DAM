import 'package:flutter/material.dart';

import 'app_tokens.dart';

ThemeData buildTheme({required bool dark, required Color accent}) {
  final tokens = (dark ? AppTokens.dark : AppTokens.light).copyWith(accent: accent);
  final brightness = dark ? Brightness.dark : Brightness.light;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: 'PlusJakartaSans',
    scaffoldBackgroundColor: tokens.bg,
    colorScheme: ColorScheme.fromSeed(seedColor: accent, brightness: brightness)
        .copyWith(primary: accent, surface: tokens.surface, onSurface: tokens.ink),
    extensions: [tokens],
  );
}
