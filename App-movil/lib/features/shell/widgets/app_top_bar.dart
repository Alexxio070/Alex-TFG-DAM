import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_icon.dart';

class AppTopBar extends StatelessWidget {
  const AppTopBar({super.key, required this.title, required this.onMenu});

  final String title;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      height: 64 + MediaQuery.paddingOf(context).top,
      padding: EdgeInsets.fromLTRB(12, MediaQuery.paddingOf(context).top, 12, 0),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Abrir menú',
            child: InkWell(
              onTap: onMenu,
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(child: AppIconView(AppIcon.menu, color: t.ink, size: 24)),
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
