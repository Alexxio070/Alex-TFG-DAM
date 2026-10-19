import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../data/repositories/settings_repository.dart';

enum TempUnit { celsius, fahrenheit }

enum ConnectionMode { local, iroh }

enum StorageUnit {
  gb('GB', 1),
  gib('GiB', 0.9313);

  const StorageUnit(this.label, this.factor);
  final String label;
  final double factor;
}

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
  String _agentAddress = '127.0.0.1:8443';
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

  void setDark(bool value) => _update(() => _dark = value);
  void setAccent(Color value) => _update(() => _accent = value);
  void setTempUnit(TempUnit value) => _update(() => _tempUnit = value);
  void setStorageUnit(StorageUnit value) => _update(() => _storageUnit = value);
  void setTempAlert(bool value) => _update(() => _tempAlert = value);
  void setTempLimit(int value) => _update(() => _tempLimit = value.clamp(60, 95));
  void setTermFont(int value) => _update(() => _termFont = value.clamp(10, 22));
  void setConnectionMode(ConnectionMode value) => _update(() => _connectionMode = value);
  void setAgentAddress(String value) => _update(() => _agentAddress = value);
  void setIrohId(String value) => _update(() => _irohId = value);

  void _update(VoidCallback change) {
    change();
    notifyListeners();
    _repository.save(
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
        irohId: _irohId,
      ),
    );
  }
}
