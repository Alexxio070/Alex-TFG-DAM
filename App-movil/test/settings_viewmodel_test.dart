import 'package:flutter_test/flutter_test.dart';
import 'package:sysmote/data/repositories/settings_repository.dart';
import 'package:sysmote/features/settings/settings_viewmodel.dart';

class _CorruptSettingsRepository implements SettingsRepository {
  @override
  Future<SettingsData?> load() async => throw RangeError.index(9, const []);

  @override
  Future<void> save(SettingsData data) async {}
}

void main() {
  test('unos ajustes corruptos no dejan la app colgada en la carga', () async {
    final vm = SettingsViewModel(_CorruptSettingsRepository());

    await Future<void>.delayed(Duration.zero);

    expect(vm.ready, isTrue);
    expect(vm.dark, isFalse);
    expect(vm.agentAddress, '127.0.0.1:8443');
  });
}
