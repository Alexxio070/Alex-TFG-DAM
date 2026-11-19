// Diálogo de confirmación único de la app.

import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'app_button.dart';
import 'modal_card.dart';

/// Pide confirmar una acción con «Cancelar» y [confirmLabel]; solo llama a [onConfirm] si se
/// confirma. [extra] permite añadir contenido entre el texto y los botones.
Future<void> showConfirmCard(
  BuildContext context, {
  required String title,
  String? body,
  required String confirmLabel,
  required VoidCallback onConfirm,
  Color? confirmColor,
  String? semanticsLabel,
  Widget? extra,
  double top = 280,
}) {
  return showTopCard(
    context,
    top: top,
    side: 28,
    builder: (dialogContext) {
      final t = dialogContext.tokens;
      return Semantics(
        label: semanticsLabel ?? title,
        child: ModalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: t.ink),
              ),
              if (body != null)
                Text(body, style: TextStyle(fontSize: 14, height: 1.45, color: t.muted2)),
              ?extra,
              const SizedBox(height: 6),
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
                      label: confirmLabel,
                      fill: confirmColor ?? kRed,
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        onConfirm();
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
