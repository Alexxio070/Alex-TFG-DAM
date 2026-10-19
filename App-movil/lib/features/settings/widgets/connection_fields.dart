import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_segmented.dart';
import '../../../core/widgets/app_text_field.dart';
import '../settings_viewmodel.dart';

final _addressFormat = RegExp(r'^[\w.-]+:\d+$');

class ConnectionFields extends StatefulWidget {
  const ConnectionFields({super.key});

  @override
  State<ConnectionFields> createState() => _ConnectionFieldsState();
}

class _ConnectionFieldsState extends State<ConnectionFields> {
  late final _controller = TextEditingController();
  String? _error;
  ConnectionMode? _lastMode;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save(SettingsViewModel s) {
    final value = _controller.text.trim();
    if (s.connectionMode == ConnectionMode.local) {
      if (!_addressFormat.hasMatch(value)) {
        setState(() => _error = 'Formato esperado: host:puerto');
        return;
      }
      s.setAgentAddress(value);
    } else {
      if (value.isEmpty) {
        setState(() => _error = 'Introduce el identificador iroh');
        return;
      }
      s.setIrohId(value);
    }
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final s = context.watch<SettingsViewModel>();
    if (_lastMode != s.connectionMode) {
      _lastMode = s.connectionMode;
      _controller.text = s.connectionMode == ConnectionMode.local ? s.agentAddress : s.irohId;
      _error = null;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        Text(
          'Conexión con el PC',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.muted2),
        ),
        AppSegmented<ConnectionMode>(
          label: 'Modo de conexión',
          value: s.connectionMode,
          onChanged: s.setConnectionMode,
          options: const [(ConnectionMode.local, 'Local'), (ConnectionMode.iroh, 'iroh')],
        ),
        AppTextField(
          controller: _controller,
          focusColor: t.accent,
          mono: true,
          hint: s.connectionMode == ConnectionMode.local ? '127.0.0.1:8443' : 'Identificador iroh',
          onChanged: (_) => setState(() => _error = null),
        ),
        if (_error != null) Text(_error!, style: const TextStyle(fontSize: 12, color: kRed)),
        Align(
          alignment: Alignment.centerRight,
          child: AppButton(label: 'Guardar', onPressed: () => _save(s)),
        ),
      ],
    );
  }
}
