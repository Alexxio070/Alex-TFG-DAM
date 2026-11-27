// Interfaz de los ajustes guardados.

import 'package:flutter/material.dart';

import '../models/settings.dart';

/// Todos los ajustes de la app juntos, tal como se guardan.
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
    required this.fingerprint,
    required this.irohId,
    required this.paired,
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
  final String fingerprint;
  final String irohId;

  /// El agente ha respondido bien con la dirección, la huella y el identificador guardados.
  final bool paired;
}

/// Carga y guarda [SettingsData].
abstract class SettingsRepository {
  /// Devuelve `null` si no hay nada guardado todavía (primer arranque).
  Future<SettingsData?> load();
  Future<void> save(SettingsData data);
}
