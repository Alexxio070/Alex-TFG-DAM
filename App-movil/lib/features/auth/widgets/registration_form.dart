import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/field_label.dart';
import '../auth_viewmodel.dart';
import 'auth_banner.dart';

class RegistrationForm extends StatefulWidget {
  const RegistrationForm({super.key, required this.vm, required this.onConnection});

  final AuthViewModel vm;
  final VoidCallback onConnection;

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
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
          AuthBanner(
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
