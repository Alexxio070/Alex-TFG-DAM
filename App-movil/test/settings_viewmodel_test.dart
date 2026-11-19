// Tests de SettingsViewModel: ajustes corruptos y que un cambio no se da por hecho hasta guardarse.

import 'package:flutter_test/flutter_test.dart';
import 'package:sysmote/data/repositories/settings_repository.dart';
import 'package:sysmote/features/settings/settings_viewmodel.dart';

class _CorruptSettingsRepository implements SettingsRepository {
  @override
  Future<SettingsData?> load() async => throw RangeError.index(9, const []);

  @override
  Future<void> save(SettingsData data) async {}
}

class _SlowSettingsRepository implements SettingsRepository {
  SettingsData? saved;

  @override
  Future<SettingsData?> load() async => null;

  @override
  Future<void> save(SettingsData data) async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    saved = data;
  }
}

void main() {
  test('unos ajustes corruptos no dejan la app colgada en la carga', () async {
    final vm = SettingsViewModel(_CorruptSettingsRepository());

    await Future<void>.delayed(Duration.zero);

    expect(vm.ready, isTrue);
    expect(vm.dark, isFalse);
    expect(vm.agentAddress, '127.0.0.1:8443');
  });

  test('setIrohId no termina hasta que el repositorio ha guardado de verdad', () async {
    final repository = _SlowSettingsRepository();
    final vm = SettingsViewModel(repository);
    await Future<void>.delayed(Duration.zero);

    await vm.setIrohId('abc123');

    expect(repository.saved?.irohId, 'abc123');
  });
}
