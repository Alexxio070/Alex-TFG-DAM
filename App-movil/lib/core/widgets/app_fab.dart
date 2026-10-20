import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'app_icon.dart';

class AppFab extends StatelessWidget {
  const AppFab({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: context.tokens.accent,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(22, 24, 29, 0.25),
                offset: Offset(0, 10),
                blurRadius: 24,
              ),
            ],
          ),
          child: const Center(
            child: AppIconView(AppIcon.plus, color: Colors.white, size: 26, strokeWidth: 2.2),
          ),
        ),
      ),
    );
  }
}
