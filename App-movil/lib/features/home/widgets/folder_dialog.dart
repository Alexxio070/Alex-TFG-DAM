// Diálogo que muestra las macros de una carpeta.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/modal_card.dart';
import '../../../data/models/home_item.dart';
import '../home_viewmodel.dart';
import '../run_macro.dart';
import 'item_tile.dart';

/// Abre [folder] con sus macros en cuadrícula; tocar una la ejecuta.
Future<void> showFolderDialog(BuildContext context, Folder folder) {
  return showTopCard(
    context,
    top: 150,
    side: 20,
    builder: (_) => _FolderCard(folderId: folder.id),
  );
}

class _FolderCard extends StatelessWidget {
  const _FolderCard({required this.folderId});

  final String folderId;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final folder = context
        .watch<HomeViewModel>()
        .items
        .whereType<Folder>()
        .where((f) => f.id == folderId)
        .firstOrNull;
    if (folder == null) return const SizedBox.shrink();
    return Semantics(
      label: folder.name,
      child: ModalCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            Row(
              spacing: 10,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: folder.color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Expanded(
                  child: Text(
                    folder.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: t.ink,
                    ),
                  ),
                ),
              ],
            ),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 84,
              children: [
                for (final macro in folder.children)
                  _ChildButton(macro: macro, color: folder.color),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChildButton extends StatelessWidget {
  const _ChildButton({required this.macro, required this.color});

  final Macro macro;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      label: macro.label,
      excludeSemantics: true,
      child: Material(
        color: t.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: t.border),
        ),
        child: InkWell(
          onTap: () => runMacro(context, macro),
          customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0x1A / 255),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: AppIconView(iconFor(macro.kind), color: color, size: 20),
                  ),
                ),
                Text(
                  macro.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t.ink),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
