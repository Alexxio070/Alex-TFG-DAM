import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

class FieldLabel extends StatelessWidget {
  const FieldLabel({
    super.key,
    required this.label,
    required this.child,
    this.error,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  final String label;
  final Widget child;
  final String? error;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      spacing: 8,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.muted2)),
        child,
        if (error != null) Text(error!, style: const TextStyle(fontSize: 12, color: kRed)),
      ],
    );
  }
}
