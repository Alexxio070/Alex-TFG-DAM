import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../auth_viewmodel.dart';

class PendingConfirmation extends StatelessWidget {
  const PendingConfirmation({super.key, required this.vm});

  final AuthViewModel vm;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final minutes = vm.pendingSecondsLeft ~/ 60;
    final seconds = vm.pendingSecondsLeft % 60;
    final countdown = '$minutes:${seconds.toString().padLeft(2, '0')}';
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            Text(
              'Hay una sesión activa en ${vm.pendingSesionActivaEn}. '
              'Confirma en la TUI del PC que quieres cerrarla.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: t.ink),
            ),
            Text(
              countdown,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: t.muted2),
            ),
            AppButton(label: 'Cancelar', onPressed: vm.cancelPending),
          ],
        ),
      ),
    );
  }
}
