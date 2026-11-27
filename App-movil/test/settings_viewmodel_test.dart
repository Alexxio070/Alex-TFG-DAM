// Tests de SettingsViewModel: ajustes corruptos, que un cambio no se da por hecho hasta guardarse y
// cuándo se borra la marca de emparejado.

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

  group('la marca de emparejado', () {
    Future<SettingsViewModel> paired() async {
      final vm = SettingsViewModel(_SlowSettingsRepository());
      await Future<void>.delayed(Duration.zero);
      await vm.setPaired(true);
      return vm;
    }

    test('se borra al cambiar la dirección', () async {
      final vm = await paired();
      await vm.setAgentAddress('192.168.1.50:8443');
      expect(vm.paired, isFalse);
    });

    test('se borra al cambiar la huella', () async {
      final vm = await paired();
      await vm.setFingerprint('a' * 64);
      expect(vm.paired, isFalse);
    });

    test('se borra al cambiar el identificador iroh', () async {
      final vm = await paired();
      await vm.setIrohId('b' * 64);
      expect(vm.paired, isFalse);
    });

    test('no se borra al guardar los mismos valores ni al cambiar de modo', () async {
      final vm = await paired();
      await vm.setAgentAddress(vm.agentAddress);
      await vm.setFingerprint(vm.fingerprint);
      await vm.setIrohId(vm.irohId);
      await vm.setConnectionMode(ConnectionMode.iroh);
      expect(vm.paired, isTrue);
    });
  });
}
