// Formulario de inicio de sesión.

import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/field_label.dart';
import '../auth_viewmodel.dart';
import 'auth_banner.dart';

/// Usuario, contraseña y nombre del dispositivo; avisa si hay otra sesión activa y muestra la
/// cuenta atrás si el agente bloquea por intentos.
class LoginForm extends StatelessWidget {
  const LoginForm({
    super.key,
    required this.vm,
    required this.usuario,
    required this.contrasena,
    required this.dispositivo,
    required this.aviso,
    required this.onSubmit,
    required this.onConnection,
  });

  final AuthViewModel vm;
  final TextEditingController usuario;
  final TextEditingController contrasena;
  final TextEditingController dispositivo;
  final String? aviso;
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
            AuthBanner(
              text:
                  'Hay una sesión activa en otro dispositivo. Para iniciar una nueva '
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
            label: 'Nombre de este dispositivo (opcional)',
            child: AppTextField(controller: dispositivo, focusColor: t.accent, hint: 'Pixel 8'),
          ),
          if (blocked)
            AuthBanner(text: 'Demasiados intentos. Espera ${vm.blockedSecondsLeft} s.', color: kRed)
          else if (aviso ?? vm.error case final message?)
            Text(message, style: const TextStyle(fontSize: 13, color: kRed)),
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
