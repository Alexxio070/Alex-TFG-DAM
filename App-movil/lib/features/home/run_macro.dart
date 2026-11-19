// Ejecución de una macro desde cualquier sitio de Inicio.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/confirm_card.dart';
import '../../data/models/home_item.dart';
import 'home_viewmodel.dart';

/// Ejecuta [macro] con una vibración ligera, pidiendo antes confirmación si la macro lo requiere.
void runMacro(BuildContext context, Macro macro) {
  final vm = context.read<HomeViewModel>();
  void execute() {
    HapticFeedback.lightImpact();
    vm.execute(macro);
  }

  if (macro.confirm) {
    final t = context.tokens;
    showConfirmCard(
      context,
      title: '¿Ejecutar «${macro.label}»?',
      confirmLabel: 'Ejecutar',
      confirmColor: t.accent,
      semanticsLabel: 'Confirmar ejecución',
      top: 260,
      extra: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: t.bg, borderRadius: BorderRadius.circular(10)),
        child: Text(
          '\$ ${macro.command}',
          style: TextStyle(fontFamily: kMonoFont, fontSize: 13, color: t.muted2),
        ),
      ),
      onConfirm: execute,
    );
  } else {
    execute();
  }
}
