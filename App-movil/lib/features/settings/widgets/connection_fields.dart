// Campos de conexión con el PC (modo, dirección, huella o identificador iroh).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_segmented.dart';
import '../../../core/widgets/app_text_field.dart';
import '../settings_viewmodel.dart';

final _addressFormat = RegExp(r'^[\w.-]+:\d+$');

/// Valida y guarda en Ajustes los datos del modo elegido. Se usa en Ajustes y en el login.
class ConnectionFields extends StatefulWidget {
  const ConnectionFields({super.key});

  @override
  State<ConnectionFields> createState() => _ConnectionFieldsState();
}

class _ConnectionFieldsState extends State<ConnectionFields> {
  late final _controller = TextEditingController();
  late final _fingerprintController = TextEditingController();
  String? _error;
  String? _saved;
  Timer? _savedTimer;
  ConnectionMode? _lastMode;

  @override
  void dispose() {
    _controller.dispose();
    _fingerprintController.dispose();
    _savedTimer?.cancel();
    super.dispose();
  }

  Future<void> _save(SettingsViewModel s) async {
    final value = _controller.text.trim();
    if (s.connectionMode == ConnectionMode.local) {
      if (!_addressFormat.hasMatch(value)) {
        setState(() => _error = 'Formato esperado: host:puerto');
        return;
      }
      final fingerprint = _fingerprintController.text.trim();
      if (!isValidFingerprint(fingerprint)) {
        setState(() => _error = kInvalidFingerprintMessage);
        return;
      }
      await s.setAgentAddress(value);
      await s.setFingerprint(fingerprint);
    } else {
      if (!isValidIrohId(value)) {
        setState(() => _error = kInvalidIrohIdMessage);
        return;
      }
      await s.setIrohId(value);
    }
    if (!mounted) return;
    setState(() => _error = null);
    _showSaved();
  }

  void _showSaved() {
    _savedTimer?.cancel();
    setState(() => _saved = 'Guardado');
    _savedTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final s = context.watch<SettingsViewModel>();
    final local = s.connectionMode == ConnectionMode.local;
    if (_lastMode != s.connectionMode) {
      _lastMode = s.connectionMode;
      _controller.text = local ? s.agentAddress : s.irohId;
      _fingerprintController.text = s.fingerprint;
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
          hint: local ? kDefaultAgentAddress : 'Identificador iroh',
          onChanged: (_) => setState(() {
            _error = null;
            _saved = null;
          }),
        ),
        if (local)
          AppTextField(
            controller: _fingerprintController,
            focusColor: t.accent,
            mono: true,
            hint: 'Huella del certificado (64 caracteres hexadecimales)',
            onChanged: (_) => setState(() {
              _error = null;
              _saved = null;
            }),
          ),
        if (_error != null) Text(_error!, style: const TextStyle(fontSize: 12, color: kRed)),
        if (_saved != null) Text(_saved!, style: const TextStyle(fontSize: 12, color: kGreen)),
        Align(
          alignment: Alignment.centerRight,
          child: AppButton(label: 'Guardar', onPressed: () => _save(s)),
        ),
      ],
    );
  }
}
