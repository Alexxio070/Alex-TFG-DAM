// Ajustes guardados en memoria para los tests.

import 'package:sysmote/data/repositories/settings_repository.dart';

/// [SettingsRepository] que guarda en una variable en vez de en shared_preferences.
class InMemorySettingsRepository implements SettingsRepository {
  SettingsData? _data;

  @override
  Future<SettingsData?> load() async => _data;

  @override
  Future<void> save(SettingsData data) async => _data = data;
}
