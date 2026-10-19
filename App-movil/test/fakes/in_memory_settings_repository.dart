import 'package:tfg/data/repositories/settings_repository.dart';

class InMemorySettingsRepository implements SettingsRepository {
  SettingsData? _data;

  @override
  Future<SettingsData?> load() async => _data;

  @override
  Future<void> save(SettingsData data) async => _data = data;
}
