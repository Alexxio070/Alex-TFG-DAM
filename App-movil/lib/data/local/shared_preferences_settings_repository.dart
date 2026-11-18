import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/settings.dart';
import '../repositories/settings_repository.dart';

const _keyDark = 'settings_dark';
const _keyAccent = 'settings_accent';
const _keyTempUnit = 'settings_temp_unit';
const _keyStorageUnit = 'settings_storage_unit';
const _keyTempAlert = 'settings_temp_alert';
const _keyTempLimit = 'settings_temp_limit';
const _keyTermFont = 'settings_term_font';
const _keyConnectionMode = 'settings_connection_mode';
const _keyAgentAddress = 'settings_agent_address';
const _keyFingerprint = 'settings_fingerprint';
const _keyIrohId = 'settings_iroh_id';

class SharedPreferencesSettingsRepository implements SettingsRepository {
  @override
  Future<SettingsData?> load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_keyDark)) return null;
    return SettingsData(
      dark: prefs.getBool(_keyDark) ?? false,
      accent: Color(prefs.getInt(_keyAccent) ?? 0),
      tempUnit: TempUnit.values[prefs.getInt(_keyTempUnit) ?? 0],
      storageUnit: StorageUnit.values[prefs.getInt(_keyStorageUnit) ?? 0],
      tempAlert: prefs.getBool(_keyTempAlert) ?? true,
      tempLimit: prefs.getInt(_keyTempLimit) ?? 85,
      termFont: prefs.getInt(_keyTermFont) ?? 13,
      connectionMode: ConnectionMode.values[prefs.getInt(_keyConnectionMode) ?? 0],
      agentAddress: prefs.getString(_keyAgentAddress) ?? kDefaultAgentAddress,
      fingerprint: prefs.getString(_keyFingerprint) ?? '',
      irohId: prefs.getString(_keyIrohId) ?? '',
    );
  }

  @override
  Future<void> save(SettingsData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDark, data.dark);
    await prefs.setInt(_keyAccent, data.accent.toARGB32());
    await prefs.setInt(_keyTempUnit, data.tempUnit.index);
    await prefs.setInt(_keyStorageUnit, data.storageUnit.index);
    await prefs.setBool(_keyTempAlert, data.tempAlert);
    await prefs.setInt(_keyTempLimit, data.tempLimit);
    await prefs.setInt(_keyTermFont, data.termFont);
    await prefs.setInt(_keyConnectionMode, data.connectionMode.index);
    await prefs.setString(_keyAgentAddress, data.agentAddress);
    await prefs.setString(_keyFingerprint, data.fingerprint);
    await prefs.setString(_keyIrohId, data.irohId);
  }
}
