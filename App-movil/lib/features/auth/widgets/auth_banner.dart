// Aviso en caja usado por los formularios del login.

import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';

/// Caja con [text] en el color indicado.
class AuthBanner extends StatelessWidget {
  const AuthBanner({super.key, required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.field,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.border),
      ),
      child: Text(text, style: TextStyle(fontSize: 13, color: color)),
    );
  }
}
