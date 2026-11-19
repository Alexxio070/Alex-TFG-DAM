// Diálogo al soltar en la papelera una carpeta con macros.

import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/modal_card.dart';
import '../../../data/models/home_item.dart';

/// Pregunta si mover las macros de [folder] a «Sin grupo» ([onUngroup]) o borrarlo todo
/// ([onDelete]).
Future<void> showFolderTrashDialog(
  BuildContext context, {
  required Folder folder,
  required VoidCallback onUngroup,
  required VoidCallback onDelete,
}) {
  return showTopCard(
    context,
    top: 260,
    side: 28,
    builder: (dialogContext) {
      final t = dialogContext.tokens;
      return Semantics(
        label: 'Eliminar carpeta',
        child: ModalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              Text(
                '¿Qué hacer con «${folder.name}»?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: t.ink),
              ),
              Text(
                'Tiene ${folder.children.length} macros dentro.',
                style: TextStyle(fontSize: 14, height: 1.45, color: t.muted2),
              ),
              const SizedBox(height: 6),
              AppButton(
                label: 'Mover a Sin grupo',
                fill: t.accent,
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  onUngroup();
                },
              ),
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Cancelar',
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ),
                  Expanded(
                    child: AppButton(
                      label: 'Borrar',
                      textColor: kRed,
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        onDelete();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
