// Pantalla del login: muestra el paso de AuthViewModel en el que se está.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_tokens.dart';
import '../../data/device_name.dart';
import '../settings/widgets/connection_sheet.dart';
import 'auth_viewmodel.dart';
import 'widgets/info_dialog.dart';
import 'widgets/login_form.dart';
import 'widgets/pending_confirmation.dart';
import 'widgets/registration_form.dart';
import 'widgets/welcome_view.dart';

/// Elige la pantalla según [AuthViewModel.stage]: carga, bienvenida, registro, login o espera de
/// confirmación. Guarda los campos del login para no perderlos entre estados.
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _usuario = TextEditingController();
  final _contrasena = TextEditingController();
  final _dispositivo = TextEditingController();
  String? _aviso;

  @override
  void initState() {
    super.initState();
    readDeviceName().then((name) {
      if (mounted && name != null && _dispositivo.text.isEmpty) _dispositivo.text = name;
    });
  }

  @override
  void dispose() {
    _usuario.dispose();
    _contrasena.dispose();
    _dispositivo.dispose();
    super.dispose();
  }

  Future<void> _connect(AuthViewModel vm) async {
    await showConnectionSheet(context);
    if (mounted) vm.connect();
  }

  Future<void> _open(Future<String?> Function() open) async {
    final popup = await open();
    if (popup != null && mounted) _showPopup(popup);
  }

  void _showPopup(String message) => showInfoDialog(context, message);

  void _submit(AuthViewModel vm) {
    if (_usuario.text.trim().isEmpty || _contrasena.text.isEmpty) {
      setState(() => _aviso = 'Escribe el usuario y la contraseña.');
      return;
    }
    setState(() => _aviso = null);
    vm.submit(
      usuario: _usuario.text.trim(),
      contrasena: _contrasena.text,
      dispositivo: deviceNameOrDefault(_dispositivo.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final vm = context.watch<AuthViewModel>();
    final inForm = switch (vm.stage) {
      AuthStage.loading || AuthStage.welcome || AuthStage.loggedIn => false,
      _ => true,
    };
    return PopScope(
      canPop: !inForm,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) vm.backToWelcome();
      },
      child: Scaffold(
        backgroundColor: t.bg,
        body: SafeArea(
          child: switch (vm.stage) {
            AuthStage.loading => const Center(child: CircularProgressIndicator()),
            AuthStage.welcome => WelcomeView(
              vm: vm,
              onConnect: () => _connect(vm),
              onLogin: () => _open(vm.openLogin),
              onRegister: () => _open(vm.openRegistration),
            ),
            AuthStage.needsRegistration ||
            AuthStage.registering => RegistrationForm(vm: vm, onPopup: _showPopup),
            AuthStage.pendingConfirmation => PendingConfirmation(vm: vm),
            AuthStage.loggedIn => const SizedBox.shrink(),
            _ => LoginForm(
              vm: vm,
              usuario: _usuario,
              contrasena: _contrasena,
              dispositivo: _dispositivo,
              aviso: _aviso,
              onSubmit: () => _submit(vm),
            ),
          },
        ),
      ),
    );
  }
}
