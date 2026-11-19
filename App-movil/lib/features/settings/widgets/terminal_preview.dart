// Vista previa del tamaño de fuente de la terminal.

import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';

/// Una línea de prompt con los colores de la terminal y [fontSize].
class TerminalPreview extends StatelessWidget {
  const TerminalPreview({super.key, required this.fontSize});

  final int fontSize;

  @override
  Widget build(BuildContext context) {
    final size = fontSize.toDouble();
    return Semantics(
      label: 'Vista previa de la terminal',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kTerminalBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text.rich(
          TextSpan(
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: size,
              height: 1.5,
              color: kTerminalForeground,
            ),
            children: [
              const TextSpan(text: 'usuario@pc', style: TextStyle(color: kTerminalGreen)),
              const TextSpan(text: ':'),
              const TextSpan(text: '~', style: TextStyle(color: kTerminalBlue)),
              const TextSpan(text: r'$ ls'),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Container(
                  width: size * 0.6,
                  height: size * 1.2,
                  margin: const EdgeInsets.only(left: 1),
                  color: kTerminalForeground,
                ),
              ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.clip,
        ),
      ),
    );
  }
}
