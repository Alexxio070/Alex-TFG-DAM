// Botón de la app, compartido por todas las pantallas.

import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

const _disabled = Color(0xFF9AA0AA);

/// Botón con borde o relleno de [fill]. Con [onPressed] a `null` se muestra deshabilitado.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.fill,
    this.textColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color? fill;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final outlined = fill == null;
    return Material(
      color: outlined ? t.surface : (onPressed == null ? _disabled : fill),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: outlined ? BorderSide(color: t.borderStrong) : BorderSide.none,
      ),
      child: InkWell(
        onTap: onPressed,
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          height: 48,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textColor ?? (outlined ? t.ink : Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
