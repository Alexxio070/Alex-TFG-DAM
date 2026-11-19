// Tests de SharedPreferencesSettingsRepository: primer arranque, ida y vuelta y datos corruptos.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sysmote/data/local/shared_preferences_settings_repository.dart';
import 'package:sysmote/data/models/settings.dart';
import 'package:sysmote/data/repositories/settings_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('en el primer arranque, sin nada guardado, load() devuelve null', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = SharedPreferencesSettingsRepository();

    expect(await repository.load(), isNull);
  });

  test('save() y load() hacen el viaje de ida y vuelta sin perder datos', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = SharedPreferencesSettingsRepository();
    const data = SettingsData(
      dark: true,
      accent: Color(0xFF3346C7),
      tempUnit: TempUnit.fahrenheit,
      storageUnit: StorageUnit.gib,
      tempAlert: false,
      tempLimit: 90,
      termFont: 18,
      connectionMode: ConnectionMode.iroh,
      agentAddress: '192.168.1.50:9000',
      fingerprint: 'a3f5c9d1a3f5c9d1a3f5c9d1a3f5c9d1a3f5c9d1a3f5c9d1a3f5c9d1a3f5c9d1',
      irohId: 'nodeid-de-prueba',
    );

    await repository.save(data);
    final loaded = await repository.load();

    expect(loaded, isNotNull);
    expect(loaded!.dark, data.dark);
    expect(loaded.accent, data.accent);
    expect(loaded.tempUnit, data.tempUnit);
    expect(loaded.storageUnit, data.storageUnit);
    expect(loaded.tempAlert, data.tempAlert);
    expect(loaded.tempLimit, data.tempLimit);
    expect(loaded.termFont, data.termFont);
    expect(loaded.connectionMode, data.connectionMode);
    expect(loaded.agentAddress, data.agentAddress);
    expect(loaded.fingerprint, data.fingerprint);
    expect(loaded.irohId, data.irohId);
  });

  test('un índice de enum guardado fuera de rango lanza al leerlo', () async {
    SharedPreferences.setMockInitialValues({
      'settings_dark': false,
      'settings_temp_unit': 99,
    });
    final repository = SharedPreferencesSettingsRepository();

    expect(repository.load(), throwsRangeError);
  });
}
