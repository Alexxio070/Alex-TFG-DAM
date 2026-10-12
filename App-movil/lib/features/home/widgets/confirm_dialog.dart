import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/modal_card.dart';
import '../../../data/models/home_item.dart';

Future<void> showConfirmDialog(
  BuildContext context, {
  required Macro macro,
  required VoidCallback onConfirm,
}) {
  return showTopCard(
    context,
    top: 260,
    side: 28,
    builder: (context) {
      final t = context.tokens;
      return Semantics(
        label: 'Confirmar ejecución',
        child: ModalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              Text(
                '¿Ejecutar «${macro.label}»?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: t.ink),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: t.bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '\$ ${macro.command}',
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 13,
                    color: t.muted2,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Cancelar',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  Expanded(
                    child: AppButton(
                      label: 'Ejecutar',
                      fill: t.accent,
                      onPressed: () {
                        Navigator.of(context).pop();
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
