// Barra superior de las pantallas: título y un botón a la izquierda (menú, cerrar o volver).

import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'app_icon.dart';

/// Barra con [title] y un botón [icon] que llama a [onIcon]; por defecto, el de abrir el menú.
class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    required this.title,
    required this.onIcon,
    this.icon = AppIcon.menu,
    this.iconLabel = 'Abrir menú',
    this.borderColor,
  });

  final String title;
  final VoidCallback onIcon;
  final AppIcon icon;
  final String iconLabel;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final topPadding = MediaQuery.paddingOf(context).top;
    return Container(
      height: 64 + topPadding,
      padding: EdgeInsets.fromLTRB(12, topPadding, 12, 0),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(bottom: BorderSide(color: borderColor ?? t.border)),
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: iconLabel,
            child: InkWell(
              onTap: onIcon,
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(child: AppIconView(icon, color: t.ink, size: 24)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.18,
              color: t.ink,
            ),
          ),
        ],
      ),
    );
  }
}
