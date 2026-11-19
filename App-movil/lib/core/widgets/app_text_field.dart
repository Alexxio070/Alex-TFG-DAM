// Campo de texto común a todos los formularios.

import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Campo de una línea o de varias ([multiline]), con fuente monoespaciada opcional ([mono]) y texto
/// oculto para contraseñas ([obscureText]).
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.focusColor,
    this.hint,
    this.mono = false,
    this.multiline = false,
    this.autofocus = false,
    this.obscureText = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final Color focusColor;
  final String? hint;
  final bool mono;
  final bool multiline;
  final bool autofocus;
  final bool obscureText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final fontSize = mono ? 14.0 : 16.0;
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );
    return TextField(
      controller: controller,
      onChanged: onChanged,
      cursorColor: focusColor,
      autofocus: autofocus,
      obscureText: obscureText,
      minLines: multiline ? 6 : 1,
      maxLines: multiline ? null : 1,
      keyboardType: multiline ? TextInputType.multiline : null,
      autocorrect: !mono,
      enableSuggestions: !mono,
      textCapitalization: TextCapitalization.none,
      style: TextStyle(
        fontFamily: mono ? kMonoFont : null,
        fontSize: fontSize,
        height: multiline ? 1.5 : 1,
        color: t.ink,
      ),
      decoration: InputDecoration(
        isCollapsed: true,
        filled: true,
        fillColor: mono ? t.field : t.surface,
        hintText: hint,
        hintStyle: TextStyle(color: t.muted, fontWeight: FontWeight.w400),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: multiline ? 14 : (48 - fontSize) / 2,
        ),
        enabledBorder: border(t.borderStrong, 1),
        focusedBorder: border(focusColor, 2),
      ),
    );
  }
}
