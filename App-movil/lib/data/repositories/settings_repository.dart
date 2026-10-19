import 'package:flutter/material.dart';

import '../models/settings.dart';

class SettingsData {
  const SettingsData({
    required this.dark,
    required this.accent,
    required this.tempUnit,
    required this.storageUnit,
    required this.tempAlert,
    required this.tempLimit,
    required this.termFont,
    required this.connectionMode,
    required this.agentAddress,
    required this.irohId,
  });

  final bool dark;
  final Color accent;
  final TempUnit tempUnit;
  final StorageUnit storageUnit;
  final bool tempAlert;
  final int tempLimit;
  final int termFont;
  final ConnectionMode connectionMode;
  final String agentAddress;
  final String irohId;
}

abstract class SettingsRepository {
  /// Devuelve `null` si no hay nada guardado todavía (primer arranque).
  Future<SettingsData?> load();
  Future<void> save(SettingsData data);
}
