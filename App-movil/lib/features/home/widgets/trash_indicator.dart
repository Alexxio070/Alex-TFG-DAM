import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_icon.dart';

class TrashIndicator extends StatelessWidget {
  const TrashIndicator({super.key, required this.center, required this.hot});

  final Offset center;
  final bool hot;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Positioned(
      left: center.dx - 32,
      top: center.dy - 32,
      width: 64,
      height: 64,
      child: IgnorePointer(
        child: AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: hot ? 1.18 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hot ? kRed : t.surface,
              boxShadow: [
                BoxShadow(
                  color: kShadowColor.withValues(alpha: 0.2),
                  offset: const Offset(0, 8),
                  blurRadius: 24,
                ),
              ],
            ),
            child: Center(
              child: AppIconView(AppIcon.trash, color: hot ? Colors.white : kRed, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}
