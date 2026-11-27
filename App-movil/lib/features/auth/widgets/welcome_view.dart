// Pantalla de bienvenida: conectar con el agente o elegir entre iniciar sesión y registrar la
// cuenta.

import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/repositories/agent_exceptions.dart';
import '../auth_viewmodel.dart';
import 'info_dialog.dart';

/// «Sysmote» arriba y los botones abajo: sin emparejar, «Conectar con el agente»; emparejada,
/// «Iniciar sesión» y «Registrar cuenta». Debajo, en gris, por qué no responde el PC. Si la sesión
/// ha caducado o ya no es válida, lo dice un popup. Vuelve a comprobar el agente cada vez que la
/// app vuelve a primer plano.
class WelcomeView extends StatefulWidget {
  const WelcomeView({
    super.key,
    required this.vm,
    required this.onConnect,
    required this.onLogin,
    required this.onRegister,
  });

  final AuthViewModel vm;
  final VoidCallback onConnect;
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: widget.vm.refresh);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _showNotice() {
    if (!mounted) return;
    final message = widget.vm.takeSessionNotice();
    if (message != null) showInfoDialog(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final vm = widget.vm;
    final busy = vm.checking;
    if (vm.hasSessionNotice) WidgetsBinding.instance.addPostFrameCallback((_) => _showNotice());
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          const SizedBox(height: 96),
          Text(
            'Sysmote',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: t.ink),
          ),
          const Spacer(),
          if (vm.paired) ...[
            AppButton(
              label: 'Iniciar sesión',
              fill: t.accent,
              onPressed: busy ? null : widget.onLogin,
            ),
            AppButton(label: 'Registrar cuenta', onPressed: busy ? null : widget.onRegister),
          ] else
            AppButton(
              label: 'Conectar con el agente',
              fill: t.accent,
              onPressed: busy ? null : widget.onConnect,
            ),
          SizedBox(
            height: 48,
            child: busy
                ? Center(
                    child: SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: t.muted),
                    ),
                  )
                : Text(
                    vm.unreachableCause == null ? '' : _unreachableMessage(vm.unreachableCause!),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: t.muted),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Texto del aviso en gris para cada causa de que el PC no responda.
String _unreachableMessage(AgentUnavailableCause cause) => switch (cause) {
  AgentUnavailableCause.timeout => 'El PC no responde. ¿Está encendido y en la misma red?',
  AgentUnavailableCause.unreachable => 'No se puede llegar al PC. Revisa la dirección.',
  AgentUnavailableCause.fingerprint => 'La huella no coincide con la de este PC.',
  AgentUnavailableCause.invalidIrohId => 'El identificador del PC no es válido.',
  AgentUnavailableCause.unexpected => 'El agente respondió algo inesperado.',
};
