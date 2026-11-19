// Tests de AuthViewModel: arranque, registro, login, confirmación en la TUI, errores de sesión y
// agente inalcanzable.

import 'package:flutter_test/flutter_test.dart';
import 'package:sysmote/data/models/auth.dart';
import 'package:sysmote/data/repositories/auth_repository.dart';
import 'package:sysmote/data/repositories/metrics_repository.dart' show AgentUnavailableException;
import 'package:sysmote/features/auth/auth_viewmodel.dart';

import 'fakes/fake_auth_repository.dart';
import 'fakes/in_memory_token_storage.dart';

void main() {
  test('sin token y agente sin cuenta: noAccount', () async {
    final vm = AuthViewModel(
      FakeAuthRepository(configurado: false),
      InMemoryTokenStorage(),
    );
    await Future<void>.delayed(Duration.zero);

    expect(vm.stage, AuthStage.noAccount);
  });

  FakeAuthRepository sinCuenta({bool caducado = false}) => FakeAuthRepository(
        configurado: false,
        registroAbierto: true,
        codigoRegistro: 'K7QXM2PD9WTR4HNB',
        codigoCaducado: caducado,
      );

  Future<AuthViewModel> registrando(FakeAuthRepository repo, InMemoryTokenStorage storage) async {
    final vm = AuthViewModel(repo, storage);
    await Future<void>.delayed(Duration.zero);
    return vm;
  }

  test('sin cuenta y con el registro abierto: needsRegistration', () async {
    final vm = await registrando(sinCuenta(), InMemoryTokenStorage());

    expect(vm.stage, AuthStage.needsRegistration);
  });

  test('register con un código vigente guarda el token y abre sesión', () async {
    final storage = InMemoryTokenStorage();
    final vm = await registrando(sinCuenta(), storage);

    await vm.register(
      codigo: 'K7QX-M2PD-9WTR-4HNB',
      usuario: 'alex',
      contrasena: 'Abcd1',
      dispositivo: 'Pixel 8',
    );

    expect(vm.stage, AuthStage.loggedIn);
    expect(await storage.read(), isNotNull);
  });

  test('register con un código caducado explica cómo generar otro', () async {
    final vm = await registrando(sinCuenta(caducado: true), InMemoryTokenStorage());

    await vm.register(
      codigo: 'K7QXM2PD9WTR4HNB',
      usuario: 'alex',
      contrasena: 'Abcd1',
      dispositivo: 'Pixel 8',
    );

    expect(vm.stage, AuthStage.needsRegistration);
    expect(vm.error, contains('caducado'));
    expect(vm.error, contains('configuración inicial'));
  });

  test('register con un código inválido deja un error específico', () async {
    final vm = await registrando(sinCuenta(), InMemoryTokenStorage());

    await vm.register(
      codigo: 'AAAA-AAAA-AAAA-AAAA',
      usuario: 'alex',
      contrasena: 'Abcd1',
      dispositivo: 'Pixel 8',
    );

    expect(vm.stage, AuthStage.needsRegistration);
    expect(vm.error, 'El código de registro no es válido');
  });

  test('register con una contraseña débil muestra los motivos', () async {
    final vm = await registrando(sinCuenta(), InMemoryTokenStorage());

    await vm.register(
      codigo: 'K7QXM2PD9WTR4HNB',
      usuario: 'alex',
      contrasena: 'abc',
      dispositivo: 'Pixel 8',
    );

    expect(vm.stage, AuthStage.needsRegistration);
    expect(vm.error, contains('Mínimo 5 caracteres'));
    expect(vm.error, contains('mayúscula'));
  });

  test('sin token, agente con cuenta y sin sesión activa: needsLogin sin aviso', () async {
    final vm = AuthViewModel(FakeAuthRepository(), InMemoryTokenStorage());
    await Future<void>.delayed(Duration.zero);

    expect(vm.stage, AuthStage.needsLogin);
    expect(vm.sesionActivaAviso, isFalse);
  });

  test('sin token y con sesión activa en otro dispositivo: avisa antes del login', () async {
    final repo = FakeAuthRepository()..sesionActivaEnDispositivo = 'iPhone 15';
    final vm = AuthViewModel(repo, InMemoryTokenStorage());
    await Future<void>.delayed(Duration.zero);

    expect(vm.stage, AuthStage.needsLogin);
    expect(vm.sesionActivaAviso, isTrue);
  });

  test('con un token válido guardado, arranca con sesión', () async {
    final repo = FakeAuthRepository();
    final outcome = await repo.login(
      usuario: 'alex',
      contrasena: 'contraseña-valida',
      dispositivo: 'Pixel 8',
    ) as LoggedIn;
    final storage = InMemoryTokenStorage()..write(outcome.token);

    final vm = AuthViewModel(repo, storage);
    await Future<void>.delayed(Duration.zero);

    expect(vm.stage, AuthStage.loggedIn);
  });

  test('un token guardado que el agente ya no reconoce vuelve al login', () async {
    final storage = InMemoryTokenStorage()..write('token-viejo');
    final vm = AuthViewModel(FakeAuthRepository(), storage);
    await Future<void>.delayed(Duration.zero);

    expect(vm.stage, AuthStage.needsLogin);
    expect(await storage.read(), isNull);
  });

  test('submit con credenciales correctas guarda el token y abre sesión', () async {
    final storage = InMemoryTokenStorage();
    final vm = AuthViewModel(FakeAuthRepository(), storage);
    await Future<void>.delayed(Duration.zero);

    await vm.submit(usuario: 'alex', contrasena: 'contraseña-valida', dispositivo: 'Pixel 8');

    expect(vm.stage, AuthStage.loggedIn);
    expect(await storage.read(), isNotNull);
  });

  test('submit con credenciales incorrectas deja un error y vuelve a needsLogin', () async {
    final vm = AuthViewModel(FakeAuthRepository(), InMemoryTokenStorage());
    await Future<void>.delayed(Duration.zero);

    await vm.submit(usuario: 'alex', contrasena: 'mala', dispositivo: 'Pixel 8');

    expect(vm.stage, AuthStage.needsLogin);
    expect(vm.error, isNotNull);
  });

  test('submit bloqueado muestra la cuenta atrás y vuelve sola a needsLogin', () async {
    final repo = FakeAuthRepository()..bloqueadoPor = TooManyAttemptsException(2);
    final vm = AuthViewModel(repo, InMemoryTokenStorage());
    await Future<void>.delayed(Duration.zero);

    await vm.submit(usuario: 'alex', contrasena: 'contraseña-valida', dispositivo: 'Pixel 8');
    expect(vm.stage, AuthStage.blocked);
    expect(vm.blockedSecondsLeft, 2);

    await Future<void>.delayed(const Duration(milliseconds: 2200));

    expect(vm.stage, AuthStage.needsLogin);
    expect(vm.blockedSecondsLeft, lessThanOrEqualTo(0));
  });

  test('submit con una sesión activa espera la confirmación y la cuenta atrás baja', () async {
    final repo = FakeAuthRepository()..sesionActivaEnDispositivo = 'iPhone 15';
    final vm = AuthViewModel(repo, InMemoryTokenStorage(), pollInterval: const Duration(seconds: 1));
    await Future<void>.delayed(Duration.zero);

    await vm.submit(usuario: 'alex', contrasena: 'contraseña-valida', dispositivo: 'Pixel 8');

    expect(vm.stage, AuthStage.pendingConfirmation);
    expect(vm.pendingSesionActivaEn, 'iPhone 15');
    expect(vm.pendingSecondsLeft, 300);

    await Future<void>.delayed(const Duration(milliseconds: 1100));

    expect(vm.pendingSecondsLeft, 299);
  });

  test('cuando se aprueba la solicitud pendiente, entra con sesión', () async {
    final repo = FakeAuthRepository()..sesionActivaEnDispositivo = 'iPhone 15';
    final storage = InMemoryTokenStorage();
    final vm = AuthViewModel(repo, storage, pollInterval: const Duration(milliseconds: 200));
    await Future<void>.delayed(Duration.zero);

    await vm.submit(usuario: 'alex', contrasena: 'contraseña-valida', dispositivo: 'Pixel 8');
    repo.approvePending();
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(vm.stage, AuthStage.loggedIn);
    expect(await storage.read(), isNotNull);
  });

  test('cuando se rechaza la solicitud, vuelve al login con un aviso', () async {
    final repo = FakeAuthRepository()..sesionActivaEnDispositivo = 'iPhone 15';
    final vm = AuthViewModel(
      repo,
      InMemoryTokenStorage(),
      pollInterval: const Duration(milliseconds: 200),
    );
    await Future<void>.delayed(Duration.zero);

    await vm.submit(usuario: 'alex', contrasena: 'contraseña-valida', dispositivo: 'Pixel 8');
    repo.rejectPending();
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(vm.stage, AuthStage.needsLogin);
    expect(vm.error, isNotNull);
  });

  test('cuando caduca la solicitud, vuelve al login con un aviso', () async {
    final repo = FakeAuthRepository()..sesionActivaEnDispositivo = 'iPhone 15';
    final vm = AuthViewModel(
      repo,
      InMemoryTokenStorage(),
      pollInterval: const Duration(milliseconds: 200),
    );
    await Future<void>.delayed(Duration.zero);

    await vm.submit(usuario: 'alex', contrasena: 'contraseña-valida', dispositivo: 'Pixel 8');
    repo.expirePending();
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(vm.stage, AuthStage.needsLogin);
    expect(vm.error, isNotNull);
  });

  test('cancelPending() deja de esperar y vuelve al login', () async {
    final repo = FakeAuthRepository()..sesionActivaEnDispositivo = 'iPhone 15';
    final vm = AuthViewModel(repo, InMemoryTokenStorage());
    await Future<void>.delayed(Duration.zero);
    await vm.submit(usuario: 'alex', contrasena: 'contraseña-valida', dispositivo: 'Pixel 8');

    vm.cancelPending();

    expect(vm.stage, AuthStage.needsLogin);
  });

  Future<AuthViewModel> conSesion(
    FakeAuthRepository repo,
    InMemoryTokenStorage storage, {
    Future<void> Function()? onForgetDevice,
  }) async {
    final outcome = await repo.login(
      usuario: 'alex',
      contrasena: 'contraseña-valida',
      dispositivo: 'Pixel 8',
    ) as LoggedIn;
    await storage.write(outcome.token);
    final vm = AuthViewModel(repo, storage, onForgetDevice: onForgetDevice);
    await Future<void>.delayed(Duration.zero);
    return vm;
  }

  test('token expone el token de la sesión y se vacía al cerrar sesión', () async {
    final repo = FakeAuthRepository();
    final vm = await conSesion(repo, InMemoryTokenStorage());

    expect(vm.token, isNotNull);

    await vm.logout();

    expect(vm.token, isNull);
  });

  test('un no_autenticado en una petición protegida borra el token y vuelve al login', () async {
    final storage = InMemoryTokenStorage();
    var olvidado = false;
    final vm = await conSesion(
      FakeAuthRepository(),
      storage,
      onForgetDevice: () async => olvidado = true,
    );

    expect(vm.handleSessionError(NotAuthenticatedException()), isTrue);
    await Future<void>.delayed(Duration.zero);

    expect(vm.stage, AuthStage.needsLogin);
    expect(vm.token, isNull);
    expect(await storage.read(), isNull);
    expect(olvidado, isFalse);
  });

  test('un desemparejado olvida también el equipo', () async {
    var olvidado = false;
    final storage = InMemoryTokenStorage();
    final vm = await conSesion(
      FakeAuthRepository(),
      storage,
      onForgetDevice: () async => olvidado = true,
    );

    expect(vm.handleSessionError(UnpairedException()), isTrue);
    await Future<void>.delayed(Duration.zero);

    expect(olvidado, isTrue);
    expect(await storage.read(), isNull);
    expect(vm.stage, AuthStage.needsLogin);
  });

  test('handleSessionError ignora los errores que no son de sesión', () async {
    final vm = await conSesion(FakeAuthRepository(), InMemoryTokenStorage());

    expect(vm.handleSessionError(AgentErrorException('x')), isFalse);
    expect(vm.stage, AuthStage.loggedIn);
  });

  test('unpair() olvida el equipo', () async {
    var olvidado = false;
    final vm = await conSesion(
      FakeAuthRepository(),
      InMemoryTokenStorage(),
      onForgetDevice: () async => olvidado = true,
    );

    await vm.unpair();

    expect(olvidado, isTrue);
  });

  test('logout() borra el token y vuelve a pedir login', () async {
    final repo = FakeAuthRepository();
    final storage = InMemoryTokenStorage();
    final vm = AuthViewModel(repo, storage);
    await Future<void>.delayed(Duration.zero);
    await vm.submit(usuario: 'alex', contrasena: 'contraseña-valida', dispositivo: 'Pixel 8');

    await vm.logout();

    expect(vm.stage, AuthStage.needsLogin);
    expect(await storage.read(), isNull);
    expect(repo.logoutCalls, 1);
  });

  test('unpair() borra el token y vuelve a pedir login', () async {
    final repo = FakeAuthRepository();
    final storage = InMemoryTokenStorage();
    final vm = AuthViewModel(repo, storage);
    await Future<void>.delayed(Duration.zero);
    await vm.submit(usuario: 'alex', contrasena: 'contraseña-valida', dispositivo: 'Pixel 8');

    await vm.unpair();

    expect(vm.stage, AuthStage.needsLogin);
    expect(await storage.read(), isNull);
    expect(repo.unpairCalls, 1);
  });

  group('agente inalcanzable', () {
    test('sin token: pasa a unreachable con el mensaje y retry() se recupera', () async {
      final repo = _Unreachable();
      final vm = AuthViewModel(repo, InMemoryTokenStorage());
      await Future<void>.delayed(Duration.zero);

      expect(vm.stage, AuthStage.unreachable);
      expect(vm.error, 'sin agente');

      repo.available = true;
      await vm.retry();

      expect(vm.stage, AuthStage.needsLogin);
    });

    test('con token guardado: no lo borra, por si solo es un fallo de red', () async {
      final storage = InMemoryTokenStorage()..write('t0k3n');
      final vm = AuthViewModel(_Unreachable(), storage);
      await Future<void>.delayed(Duration.zero);

      expect(vm.stage, AuthStage.unreachable);
      expect(await storage.read(), 't0k3n');
    });

    test('un login sin conexión deja el error y vuelve al formulario', () async {
      final repo = _Unreachable()..available = true;
      final vm = AuthViewModel(repo, InMemoryTokenStorage());
      await Future<void>.delayed(Duration.zero);
      repo.available = false;

      await vm.submit(usuario: 'a', contrasena: 'b', dispositivo: 'c');

      expect(vm.stage, AuthStage.needsLogin);
      expect(vm.error, 'sin agente');
    });

    test('logout() y unpair() olvidan la sesión aunque el agente no responda', () async {
      final repo = _Unreachable()..available = true;
      final storage = InMemoryTokenStorage()..write('t0k3n');
      var olvidado = false;
      final vm = AuthViewModel(repo, storage, onForgetDevice: () async => olvidado = true);
      await Future<void>.delayed(Duration.zero);
      repo.available = false;

      await vm.logout();
      expect(await storage.read(), isNull);

      await vm.unpair();
      expect(olvidado, isTrue);
    });

    test('un fallo de red mientras espera la confirmación no la cancela', () async {
      final fake = FakeAuthRepository()..sesionActivaEnDispositivo = 'iPhone 15';
      final repo = _Unreachable(inner: fake)..available = true;
      final vm = AuthViewModel(repo, InMemoryTokenStorage(), pollInterval: const Duration(milliseconds: 100));
      await Future<void>.delayed(Duration.zero);
      await vm.submit(usuario: 'alex', contrasena: 'contraseña-valida', dispositivo: 'Pixel 8');

      repo.available = false;
      await Future<void>.delayed(const Duration(milliseconds: 250));

      expect(vm.stage, AuthStage.pendingConfirmation);
      vm.cancelPending();
    });
  });
}

/// Falla con [AgentUnavailableException] mientras `available` sea false y, si
/// no, delega en un [FakeAuthRepository].
class _Unreachable implements AuthRepository {
  _Unreachable({FakeAuthRepository? inner}) : _inner = inner ?? FakeAuthRepository();

  final FakeAuthRepository _inner;
  bool available = false;

  T _guard<T>(T Function() call) {
    if (!available) throw AgentUnavailableException('sin agente');
    return call();
  }

  @override
  Future<AgentStatus> status() async => _guard(_inner.status).then((s) => s);

  @override
  Future<LoginOutcome> login({
    required String usuario,
    required String contrasena,
    required String dispositivo,
  }) async =>
      _guard(() => _inner.login(usuario: usuario, contrasena: contrasena, dispositivo: dispositivo));

  @override
  Future<LoggedIn> register({
    required String codigo,
    required String usuario,
    required String contrasena,
    required String dispositivo,
  }) async =>
      _guard(() => _inner.register(
            codigo: codigo,
            usuario: usuario,
            contrasena: contrasena,
            dispositivo: dispositivo,
          ));

  @override
  Future<LoginRequestStatus> checkLoginRequest(String solicitudId) async =>
      _guard(() => _inner.checkLoginRequest(solicitudId));

  @override
  Future<SessionInfo> session() async => _guard(_inner.session);

  @override
  Future<void> logout() async => _guard(_inner.logout);

  @override
  Future<void> unpair() async => _guard(_inner.unpair);
}
