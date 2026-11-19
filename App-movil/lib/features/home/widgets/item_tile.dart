// Ficha de la cuadrícula de Inicio (macro o carpeta).

import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../data/models/home_item.dart';

/// Icono que corresponde a cada tipo de macro.
AppIcon iconFor(MacroKind kind) => switch (kind) {
      MacroKind.volume => AppIcon.volume,
      MacroKind.lock => AppIcon.lock,
      MacroKind.moon => AppIcon.moon,
      MacroKind.bolt => AppIcon.bolt,
    };

/// Dibuja una macro o una carpeta; [highlight] la marca como destino al arrastrar y [lifted] como
/// levantada.
class ItemTile extends StatelessWidget {
  const ItemTile({super.key, required this.item, this.highlight = false, this.lifted = false});

  final HomeItem item;
  final bool highlight;
  final bool lifted;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final item = this.item;
    final folder = item is Folder ? item : null;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: folder?.color ?? t.surface,
        borderRadius: BorderRadius.circular(24),
        border: folder == null ? Border.all(color: t.border) : null,
        boxShadow: [
          if (highlight) ...[
            BoxShadow(color: t.accent, spreadRadius: 3),
            BoxShadow(
              color: kShadowColor.withValues(alpha: 0.18),
              offset: const Offset(0, 8),
              blurRadius: 20,
            ),
          ],
          if (lifted)
            BoxShadow(
              color: kShadowColor.withValues(alpha: 0.28),
              offset: const Offset(0, 16),
              blurRadius: 32,
            ),
        ],
      ),
      child: switch (item) {
        Macro() => _MacroContent(macro: item),
        Folder() => _FolderContent(folder: item),
      },
    );
  }
}

class _MacroContent extends StatelessWidget {
  const _MacroContent({required this.macro});

  final Macro macro;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 14,
      children: [
        SizedBox(
          width: 64,
          height: 64,
          child: Center(
            child: AppIconView(
              iconFor(macro.kind),
              color: t.accent,
              size: 64,
              strokeWidth: 1.6,
            ),
          ),
        ),
        Text(
          macro.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: t.ink),
        ),
      ],
    );
  }
}

class _FolderContent extends StatelessWidget {
  const _FolderContent({required this.folder});

  final Folder folder;

  @override
  Widget build(BuildContext context) {
    final minis = folder.children.length.clamp(0, 4);
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          spacing: 6,
          children: [
            for (var i = 0; i < minis; i++)
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(255, 255, 255, 0.9),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 2,
          children: [
            Text(
              folder.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              '${folder.children.length} macros',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color.fromRGBO(255, 255, 255, 0.9),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
