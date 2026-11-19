// Pantalla del login: muestra el paso de AuthViewModel en el que se está.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_tokens.dart';
import '../settings/widgets/connection_sheet.dart';
import 'auth_viewmodel.dart';
import 'widgets/auth_status_messages.dart';
import 'widgets/login_form.dart';
import 'widgets/pending_confirmation.dart';
import 'widgets/registration_form.dart';

/// Elige la pantalla según [AuthViewModel.stage]: carga, agente inalcanzable, sin cuenta, registro,
/// login o espera de confirmación. Guarda los campos del login para no perderlos entre estados.
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _usuario = TextEditingController();
  final _contrasena = TextEditingController();
  final _dispositivo = TextEditingController();

  @override
  void dispose() {
    _usuario.dispose();
    _contrasena.dispose();
    _dispositivo.dispose();
    super.dispose();
  }

  Future<void> _openConnection(AuthViewModel vm) async {
    await showConnectionSheet(context);
    if (mounted) vm.retry();
  }

  void _submit(AuthViewModel vm) {
    if (_usuario.text.trim().isEmpty ||
        _contrasena.text.isEmpty ||
        _dispositivo.text.trim().isEmpty) {
      return;
    }
    vm.submit(
      usuario: _usuario.text.trim(),
      contrasena: _contrasena.text,
      dispositivo: _dispositivo.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final vm = context.watch<AuthViewModel>();
    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: switch (vm.stage) {
          AuthStage.loading => const Center(child: CircularProgressIndicator()),
          AuthStage.unreachable => UnreachableMessage(
              vm: vm,
              onConnection: () => _openConnection(vm),
            ),
          AuthStage.noAccount => NoAccountMessage(onConnection: () => _openConnection(vm)),
          AuthStage.needsRegistration || AuthStage.registering => RegistrationForm(
              vm: vm,
              onConnection: () => _openConnection(vm),
            ),
          AuthStage.pendingConfirmation => PendingConfirmation(vm: vm),
          AuthStage.loggedIn => const SizedBox.shrink(),
          _ => LoginForm(
              vm: vm,
              usuario: _usuario,
              contrasena: _contrasena,
              dispositivo: _dispositivo,
              onSubmit: () => _submit(vm),
              onConnection: () => _openConnection(vm),
            ),
        },
      ),
    );
  }
}
