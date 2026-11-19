// Pantallas del login sin formulario: agente sin cuenta y agente inalcanzable.

import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../auth_viewmodel.dart';

/// El agente no tiene cuenta ni registro abierto: indica cómo crearla desde la TUI.
class NoAccountMessage extends StatelessWidget {
  const NoAccountMessage({super.key, required this.onConnection});

  final VoidCallback onConnection;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            Text(
              'El agente todavía no tiene ninguna cuenta. Créala desde la TUI del PC '
              '(sysmote → Emparejamiento).',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: t.muted2),
            ),
            AppButton(label: 'Conexión con el PC', onPressed: onConnection),
          ],
        ),
      ),
    );
  }
}

/// No se puede hablar con el agente: muestra el error y deja reintentar o revisar la conexión.
class UnreachableMessage extends StatelessWidget {
  const UnreachableMessage({super.key, required this.vm, required this.onConnection});

  final AuthViewModel vm;
  final VoidCallback onConnection;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            Text(
              'No se puede conectar con el agente',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: t.ink),
            ),
            if (vm.error != null)
              Text(
                vm.error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: t.muted),
              ),
            const SizedBox(height: 6),
            AppButton(label: 'Reintentar', fill: t.accent, onPressed: vm.retry),
            AppButton(label: 'Conexión con el PC', onPressed: onConnection),
          ],
        ),
      ),
    );
  }
}
