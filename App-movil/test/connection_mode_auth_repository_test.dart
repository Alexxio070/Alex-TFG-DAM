// Tests de ConnectionModeAuthRepository: cada llamada va al repositorio del modo activo.

import 'package:flutter_test/flutter_test.dart';
import 'package:sysmote/data/connection_mode_auth_repository.dart';
import 'package:sysmote/data/models/auth.dart';
import 'package:sysmote/data/models/settings.dart';

import 'fakes/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository local;
  late FakeAuthRepository iroh;
  late ConnectionMode mode;
  late ConnectionModeAuthRepository repository;

  setUp(() {
    local = FakeAuthRepository(usuarioValido: 'local', contrasenaValida: 'x');
    iroh = FakeAuthRepository(usuarioValido: 'iroh', contrasenaValida: 'x');
    mode = ConnectionMode.local;
    repository = ConnectionModeAuthRepository(connectionMode: () => mode, local: local, iroh: iroh);
  });

  Future<String> loginUser(String usuario) async {
    final outcome = await repository.login(usuario: usuario, contrasena: 'x', dispositivo: 'd');
    return (outcome as LoggedIn).usuario;
  }

  test('usa el repositorio local cuando el modo es local', () async {
    expect(await loginUser('local'), 'local');
  });

  test('cambia al repositorio iroh en la siguiente llamada tras cambiar el modo', () async {
    mode = ConnectionMode.iroh;

    expect(await loginUser('iroh'), 'iroh');
  });

  test('todas las operaciones van al repositorio activo', () async {
    mode = ConnectionMode.iroh;
    final registro = FakeAuthRepository(
      configurado: false,
      registroAbierto: true,
      codigoRegistro: 'K7QXM2PD9WTR4HNB',
    );
    repository = ConnectionModeAuthRepository(
      connectionMode: () => mode,
      local: local,
      iroh: registro,
    );

    expect((await repository.status()).registroAbierto, isTrue);
    await repository.register(
      codigo: 'K7QXM2PD9WTR4HNB',
      usuario: 'alex',
      contrasena: 'Abcd1',
      dispositivo: 'd',
    );
    expect((await repository.session()).usuario, 'alex');
    await repository.logout();
    await repository.unpair();

    expect(registro.logoutCalls, 1);
    expect(registro.unpairCalls, 1);
    expect(local.logoutCalls, 0);
  });
}
