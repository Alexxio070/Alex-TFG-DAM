import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/modal_card.dart';

Future<void> showCloseTabDialog(BuildContext context, {required VoidCallback onClose}) {
  return showTopCard(
    context,
    top: 280,
    side: 28,
    builder: (dialogContext) {
      final t = dialogContext.tokens;
      return Semantics(
        label: 'Cerrar pestaña',
        child: ModalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              Text(
                '¿Cerrar esta pestaña?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: t.ink),
              ),
              Text(
                'Se cerrará la sesión de terminal y la ventana del PC, aunque haya algo en marcha.',
                style: TextStyle(fontSize: 14, height: 1.45, color: t.muted2),
              ),
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
                      label: 'Cerrar',
                      fill: kRed,
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        onClose();
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
