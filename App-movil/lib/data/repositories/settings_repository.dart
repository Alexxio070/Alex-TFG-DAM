import 'package:flutter/material.dart';

import '../../features/settings/settings_viewmodel.dart';

class SettingsData {
  const SettingsData({
    required this.dark,
    required this.accent,
    required this.tempUnit,
    required this.storageUnit,
    required this.tempAlert,
    required this.tempLimit,
    required this.termFont,
  });

  final bool dark;
  final Color accent;
  final TempUnit tempUnit;
  final StorageUnit storageUnit;
  final bool tempAlert;
  final int tempLimit;
  final int termFont;
}

abstract class SettingsRepository {
  /// Devuelve `null` si no hay nada guardado todavía (primer arranque).
  Future<SettingsData?> load();
  Future<void> save(SettingsData data);
}
