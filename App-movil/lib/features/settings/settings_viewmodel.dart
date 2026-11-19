// ViewModel de Ajustes: valores actuales y guardado en el móvil.

import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../data/models/settings.dart';
import '../../data/repositories/settings_repository.dart';

export '../../data/models/settings.dart';

/// Carga los ajustes guardados al arrancar y guarda cada cambio. Lo comparten todas las pantallas.
class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel(this._repository) {
    _load();
  }

  final SettingsRepository _repository;

  bool _ready = false;
  bool _dark = false;
  Color _accent = kAccentColors.first;
  TempUnit _tempUnit = TempUnit.celsius;
  StorageUnit _storageUnit = StorageUnit.gb;
  bool _tempAlert = true;
  int _tempLimit = 85;
  int _termFont = 13;
  ConnectionMode _connectionMode = ConnectionMode.local;
  String _agentAddress = kDefaultAgentAddress;
  String _fingerprint = '';
  String _irohId = '';

  bool get ready => _ready;
  bool get dark => _dark;
  Color get accent => _accent;
  TempUnit get tempUnit => _tempUnit;
  StorageUnit get storageUnit => _storageUnit;
  bool get tempAlert => _tempAlert;
  int get tempLimit => _tempLimit;
  int get termFont => _termFont;
  ConnectionMode get connectionMode => _connectionMode;
  String get agentAddress => _agentAddress;
  String get fingerprint => _fingerprint;
  String get irohId => _irohId;

  Future<void> _load() async {
    try {
      final saved = await _repository.load();
      if (saved != null) {
        _dark = saved.dark;
        _accent = saved.accent;
        _tempUnit = saved.tempUnit;
        _storageUnit = saved.storageUnit;
        _tempAlert = saved.tempAlert;
        _tempLimit = saved.tempLimit;
        _termFont = saved.termFont;
        _connectionMode = saved.connectionMode;
        _agentAddress = saved.agentAddress;
        _fingerprint = saved.fingerprint;
        _irohId = saved.irohId;
      }
    } catch (_) {
      // Ajustes guardados corruptos (p. ej. un índice de enum fuera de
      // rango): se sigue con los valores por defecto en vez de quedarse
      // en la pantalla de carga para siempre.
    }
    _ready = true;
    notifyListeners();
  }

  Future<void> setDark(bool value) => _update(() => _dark = value);
  Future<void> setAccent(Color value) => _update(() => _accent = value);
  Future<void> setTempUnit(TempUnit value) => _update(() => _tempUnit = value);
  Future<void> setStorageUnit(StorageUnit value) => _update(() => _storageUnit = value);
  Future<void> setTempAlert(bool value) => _update(() => _tempAlert = value);
  Future<void> setTempLimit(int value) => _update(() => _tempLimit = value.clamp(60, 95));
  Future<void> setTermFont(int value) => _update(() => _termFont = value.clamp(10, 22));
  Future<void> setConnectionMode(ConnectionMode value) => _update(() => _connectionMode = value);
  Future<void> setAgentAddress(String value) => _update(() => _agentAddress = value);
  Future<void> setFingerprint(String value) => _update(() => _fingerprint = value);
  Future<void> setIrohId(String value) => _update(() => _irohId = value);

  Future<void> _update(VoidCallback change) async {
    change();
    notifyListeners();
    // Se espera a que termine de escribirse en disco: si se cierra la app
    // justo después de guardar, el cambio no debe perderse.
    await _repository.save(
      SettingsData(
        dark: _dark,
        accent: _accent,
        tempUnit: _tempUnit,
        storageUnit: _storageUnit,
        tempAlert: _tempAlert,
        tempLimit: _tempLimit,
        termFont: _termFont,
        connectionMode: _connectionMode,
        agentAddress: _agentAddress,
        fingerprint: _fingerprint,
        irohId: _irohId,
      ),
    );
  }
}
