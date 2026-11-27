// Formulario para crear la cuenta del agente la primera vez.

import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/field_label.dart';
import '../../../data/device_name.dart';
import '../auth_viewmodel.dart';
import 'auth_banner.dart';

/// Código de registro de la TUI, usuario, contraseña y nombre del dispositivo, y «Volver» a la
/// bienvenida.
class RegistrationForm extends StatefulWidget {
  const RegistrationForm({super.key, required this.vm, required this.onPopup});

  final AuthViewModel vm;

  /// Muestra el popup que devuelve el registro cuando otro móvil se ha adelantado.
  final void Function(String message) onPopup;

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _codigo = TextEditingController();
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
    _codigo.dispose();
    _usuario.dispose();
    _contrasena.dispose();
    _dispositivo.dispose();
    super.dispose();
  }

  void _submit() {
    if (_codigo.text.trim().isEmpty || _usuario.text.trim().isEmpty || _contrasena.text.isEmpty) {
      setState(() => _aviso = 'Escribe el código, el usuario y la contraseña.');
      return;
    }
    setState(() => _aviso = null);
    widget.vm
        .register(
          codigo: _codigo.text.trim(),
          usuario: _usuario.text.trim(),
          contrasena: _contrasena.text,
          dispositivo: deviceNameOrDefault(_dispositivo.text),
        )
        .then((popup) {
          if (popup != null) widget.onPopup(popup);
        });
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
            label: 'Nombre de este dispositivo (opcional)',
            child: AppTextField(controller: _dispositivo, focusColor: t.accent, hint: 'Pixel 8'),
          ),
          if (_aviso ?? vm.error case final message?)
            Text(message, style: const TextStyle(fontSize: 13, color: kRed)),
          AppButton(
            label: busy ? 'Creando…' : 'Crear cuenta',
            fill: t.accent,
            onPressed: busy ? null : _submit,
          ),
          AppButton(label: 'Volver', onPressed: widget.vm.backToWelcome),
        ],
      ),
    );
  }
}
