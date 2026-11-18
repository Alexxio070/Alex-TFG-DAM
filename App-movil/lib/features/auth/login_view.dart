import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/field_label.dart';
import '../settings/widgets/connection_sheet.dart';
import 'auth_viewmodel.dart';

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
          AuthStage.unreachable => _Unreachable(vm: vm, onConnection: () => _openConnection(vm)),
          AuthStage.noAccount => _NoAccount(onConnection: () => _openConnection(vm)),
          AuthStage.needsRegistration || AuthStage.registering => _RegistrationForm(
              vm: vm,
              onConnection: () => _openConnection(vm),
            ),
          AuthStage.pendingConfirmation => _PendingConfirmation(vm: vm),
          AuthStage.loggedIn => const SizedBox.shrink(),
          _ => _LoginForm(
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

class _NoAccount extends StatelessWidget {
  const _NoAccount({required this.onConnection});

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

class _Unreachable extends StatelessWidget {
  const _Unreachable({required this.vm, required this.onConnection});

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

class _RegistrationForm extends StatefulWidget {
  const _RegistrationForm({required this.vm, required this.onConnection});

  final AuthViewModel vm;
  final VoidCallback onConnection;

  @override
  State<_RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<_RegistrationForm> {
  final _codigo = TextEditingController();
  final _usuario = TextEditingController();
  final _contrasena = TextEditingController();
  final _dispositivo = TextEditingController();

  @override
  void dispose() {
    _codigo.dispose();
    _usuario.dispose();
    _contrasena.dispose();
    _dispositivo.dispose();
    super.dispose();
  }

  void _submit() {
    if (_codigo.text.trim().isEmpty ||
        _usuario.text.trim().isEmpty ||
        _contrasena.text.isEmpty ||
        _dispositivo.text.trim().isEmpty) {
      return;
    }
    widget.vm.register(
      codigo: _codigo.text.trim(),
      usuario: _usuario.text.trim(),
      contrasena: _contrasena.text,
      dispositivo: _dispositivo.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final vm = widget.vm;
    final busy = vm.stage == AuthStage.registering;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          Text(
            'Crear la cuenta',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: t.ink),
          ),
          _Banner(
            text: 'Pulsa configuración inicial en la TUI del PC para ver el código de registro.',
            color: t.muted2,
          ),
          FieldLabel(
            label: 'Código de registro',
            child: AppTextField(
              controller: _codigo,
              focusColor: t.accent,
              mono: true,
              autofocus: true,
              hint: 'K7QX-M2PD-9WTR-4HNB',
            ),
          ),
          FieldLabel(
            label: 'Usuario',
            child: AppTextField(controller: _usuario, focusColor: t.accent),
          ),
          FieldLabel(
            label: 'Contraseña',
            child: AppTextField(controller: _contrasena, focusColor: t.accent, obscureText: true),
          ),
          FieldLabel(
            label: 'Nombre de este dispositivo',
            child: AppTextField(controller: _dispositivo, focusColor: t.accent, hint: 'Pixel 8'),
          ),
          if (vm.error != null)
            Text(vm.error!, style: const TextStyle(fontSize: 13, color: kRed)),
          AppButton(
            label: busy ? 'Creando…' : 'Crear cuenta',
            fill: t.accent,
            onPressed: busy ? null : _submit,
          ),
          AppButton(label: 'Conexión con el PC', onPressed: widget.onConnection),
        ],
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.vm,
    required this.usuario,
    required this.contrasena,
    required this.dispositivo,
    required this.onSubmit,
    required this.onConnection,
  });

  final AuthViewModel vm;
  final TextEditingController usuario;
  final TextEditingController contrasena;
  final TextEditingController dispositivo;
  final VoidCallback onSubmit;
  final VoidCallback onConnection;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final busy = vm.stage == AuthStage.submitting;
    final blocked = vm.stage == AuthStage.blocked;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          Text(
            'Iniciar sesión',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: t.ink),
          ),
          if (vm.sesionActivaAviso)
            _Banner(
              text: 'Hay una sesión activa en otro dispositivo. Para iniciar una nueva '
                  'tendrás que confirmarlo en la TUI del PC.',
              color: t.muted2,
            ),
          FieldLabel(
            label: 'Usuario',
            child: AppTextField(controller: usuario, focusColor: t.accent, autofocus: true),
          ),
          FieldLabel(
            label: 'Contraseña',
            child: AppTextField(controller: contrasena, focusColor: t.accent, obscureText: true),
          ),
          FieldLabel(
            label: 'Nombre de este dispositivo',
            child: AppTextField(controller: dispositivo, focusColor: t.accent, hint: 'Pixel 8'),
          ),
          if (blocked)
            _Banner(text: 'Demasiados intentos. Espera ${vm.blockedSecondsLeft} s.', color: kRed)
          else if (vm.error != null)
            Text(vm.error!, style: const TextStyle(fontSize: 13, color: kRed)),
          AppButton(
            label: busy ? 'Entrando…' : 'Entrar',
            fill: t.accent,
            onPressed: busy || blocked ? null : onSubmit,
          ),
          AppButton(label: 'Conexión con el PC', onPressed: onConnection),
        ],
      ),
    );
  }
}

class _PendingConfirmation extends StatelessWidget {
  const _PendingConfirmation({required this.vm});

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

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.field,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.border),
      ),
      child: Text(text, style: TextStyle(fontSize: 13, color: color)),
    );
  }
}
