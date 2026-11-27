// Tests de AuthViewModel: arranque, bienvenida y popups, registro, login, confirmación en la TUI,
// errores de sesión y agente inalcanzable.

import 'package:flutter_test/flutter_test.dart';
import 'package:sysmote/data/models/auth.dart';
import 'package:sysmote/data/repositories/auth_repository.dart';
import 'package:sysmote/data/repositories/agent_exceptions.dart';
import 'package:sysmote/features/auth/auth_viewmodel.dart';

import 'fakes/fake_auth_repository.dart';
import 'fakes/in_memory_token_storage.dart';

/// Crea el ViewModel con la marca de emparejada en memoria y espera al arranque.
Future<AuthViewModel> arrancar(
  AuthRepository repo,
  InMemoryTokenStorage storage, {
  bool emparejada = true,
  Duration pollInterval = const Duration(seconds: 2),
  Future<void> Function()? onForgetDevice,
}) async {
  var paired = emparejada;
  final vm = AuthViewModel(
    repo,
    storage,
    pollInterval: pollInterval,
    isPaired: () => paired,
    markPaired: () async => paired = true,
    onForgetDevice: () async {
      paired = false;
      await onForgetDevice?.call();
    },
  );
  await Future<void>.delayed(Duration.zero);
  return vm;
}

/// Arranca y abre el formulario de login desde la bienvenida.
Future<AuthViewModel> enLogin(
  AuthRepository repo,
  InMemoryTokenStorage storage, {
  Duration pollInterval = const Duration(seconds: 2),
  Future<void> Function()? onForgetDevice,
}) async {
  final vm = await arrancar(
    repo,
    storage,
    pollInterval: pollInterval,
    onForgetDevice: onForgetDevice,
  );
  expect(await vm.openLogin(), isNull);
  return vm;
}

void main() {
  group('bienvenida', () {
    test('sin token arranca en la bienvenida y marca la app como emparejada', () async {
      final vm = await arrancar(FakeAuthRepository(), InMemoryTokenStorage(), emparejada: false);

      expect(vm.stage, AuthStage.welcome);
      expect(vm.paired, isTrue);
      expect(vm.unreachableCause, isNull);
    });

    test('sin emparejar y sin agente no avisa de nada al arrancar', () async {
      final vm = await arrancar(_Unreachable(), InMemoryTokenStorage(), emparejada: false);

      expect(vm.stage, AuthStage.welcome);
      expect(vm.paired, isFalse);
      expect(vm.unreachableCause, isNull);
    });

    test('connect() sin agente avisa de la causa y sigue sin emparejar', () async {
      final repo = _Unreachable();
      final vm = await arrancar(repo, InMemoryTokenStorage(), emparejada: false);

      await vm.connect();

      expect(vm.paired, isFalse);
      expect(vm.unreachableCause, AgentUnavailableCause.timeout);

      repo.available = true;
      await vm.connect();

      expect(vm.paired, isTrue);
      expect(vm.unreachableCause, isNull);
    });

    test('emparejada y sin agente: avisa al arrancar y se recupera al volver', () async {
      final repo = _Unreachable();
      final vm = await arrancar(repo, InMemoryTokenStorage());

      expect(vm.stage, AuthStage.welcome);
      expect(vm.unreachableCause, AgentUnavailableCause.timeout);

      repo.available = true;
      await vm.refresh();

      expect(vm.unreachableCause, isNull);
    });

    test('un código HTTP inesperado se avisa como respuesta inesperada', () async {
      final vm = await arrancar(
        _Unreachable(error: AgentErrorException('500')),
        InMemoryTokenStorage(),
      );

      expect(vm.unreachableCause, AgentUnavailableCause.unexpected);
    });

    group('popups según el estado del agente', () {
      final abierto = FakeAuthRepository(configurado: false, registroAbierto: true);
      final cerrado = FakeAuthRepository(configurado: false);

      test('con cuenta: login abre el formulario y registro avisa', () async {
        final vm = await arrancar(FakeAuthRepository(), InMemoryTokenStorage());

        expect(await vm.openRegistration(), kAccountExistsPopup);
        expect(vm.stage, AuthStage.welcome);
        expect(await vm.openLogin(), isNull);
        expect(vm.stage, AuthStage.needsLogin);
      });

      test('sin cuenta y registro abierto: registro abre el formulario y login avisa', () async {
        final vm = await arrancar(abierto, InMemoryTokenStorage());

        expect(await vm.openLogin(), kNoAccountPopup);
        expect(vm.stage, AuthStage.welcome);
        expect(await vm.openRegistration(), isNull);
        expect(vm.stage, AuthStage.needsRegistration);
      });

      test('sin cuenta y registro cerrado: los dos avisan de que está cerrado', () async {
        final vm = await arrancar(cerrado, InMemoryTokenStorage());

        expect(await vm.openLogin(), kRegistrationClosedPopup);
        expect(await vm.openRegistration(), kRegistrationClosedPopup);
        expect(vm.stage, AuthStage.welcome);
      });
    });

    test('pulsar un botón sin agente no abre nada y avisa de la causa', () async {
      final repo = _Unreachable()..available = true;
      final vm = await arrancar(repo, InMemoryTokenStorage());
      repo.available = false;

      expect(await vm.openLogin(), isNull);

      expect(vm.stage, AuthStage.welcome);
      expect(vm.unreachableCause, AgentUnavailableCause.timeout);
    });

    test('backToWelcome() deja el formulario y borra el error', () async {
      final vm = await enLogin(FakeAuthRepository(), InMemoryTokenStorage());
      await vm.submit(usuario: 'alex', contrasena: 'mala', dispositivo: 'Pixel 8');

      vm.backToWelcome();

      expect(vm.stage, AuthStage.welcome);
      expect(vm.error, isNull);
    });
  });

  FakeAuthRepository sinCuenta({bool caducado = false}) => FakeAuthRepository(
    configurado: false,
    registroAbierto: true,
    codigoRegistro: 'K7QXM2PD9WTR4HNB',
    codigoCaducado: caducado,
  );

  Future<AuthViewModel> registrando(FakeAuthRepository repo, InMemoryTokenStorage storage) async {
    final vm = await arrancar(repo, storage);
    expect(await vm.openRegistration(), isNull);
    return vm;
  }

  test('si otro móvil se adelanta al registrar, vuelve a la bienvenida con el popup', () async {
    final repo = sinCuenta();
    final vm = await registrando(repo, InMemoryTokenStorage());
    repo.configurado = true;

    final popup = await vm.register(
      codigo: 'K7QXM2PD9WTR4HNB',
      usuario: 'alex',
      contrasena: 'Abcd1',
      dispositivo: 'Pixel 8',
    );

    expect(popup, kAccountExistsPopup);
    expect(vm.stage, AuthStage.welcome);
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

  test('agente con cuenta y sin sesión activa: login sin aviso', () async {
    final vm = await enLogin(FakeAuthRepository(), InMemoryTokenStorage());

    expect(vm.stage, AuthStage.needsLogin);
    expect(vm.sesionActivaAviso, isFalse);
  });

  test('con sesión activa en otro dispositivo: avisa antes del login', () async {
    final repo = FakeAuthRepository()..sesionActivaEnDispositivo = 'iPhone 15';
    final vm = await enLogin(repo, InMemoryTokenStorage());

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

    final vm = await arrancar(repo, storage, emparejada: false);

    expect(vm.stage, AuthStage.loggedIn);
    expect(vm.paired, isTrue);
  });

  test('un token pasado de los 7 días vuelve a la bienvenida con el aviso de caducada', () async {
    final storage = InMemoryTokenStorage()..write('token-viejo');
    final vm = await arrancar(FakeAuthRepository()..tokenCaducado = true, storage);

    expect(vm.stage, AuthStage.welcome);
    expect(vm.sessionExpired, isTrue);
    expect(await storage.read(), isNull);

    await vm.openLogin();

    expect(vm.sessionExpired, isFalse);
  });

  test('un token que el agente ya no reconoce vuelve a la bienvenida sin aviso', () async {
    final storage = InMemoryTokenStorage()..write('token-viejo');
    final vm = await arrancar(FakeAuthRepository(), storage);

    expect(vm.stage, AuthStage.welcome);
    expect(vm.sessionExpired, isFalse);
    expect(await storage.read(), isNull);
  });

  test('submit con credenciales correctas guarda el token y abre sesión', () async {
    final storage = InMemoryTokenStorage();
    final vm = await enLogin(FakeAuthRepository(), storage);

    await vm.submit(usuario: 'alex', contrasena: 'contraseña-valida', dispositivo: 'Pixel 8');

    expect(vm.stage, AuthStage.loggedIn);
    expect(await storage.read(), isNotNull);
  });

  test('submit con credenciales incorrectas deja un error y vuelve a needsLogin', () async {
    final vm = await enLogin(FakeAuthRepository(), InMemoryTokenStorage());

    await vm.submit(usuario: 'alex', contrasena: 'mala', dispositivo: 'Pixel 8');

    expect(vm.stage, AuthStage.needsLogin);
    expect(vm.error, isNotNull);
  });

  test('submit bloqueado muestra la cuenta atrás y vuelve sola a needsLogin', () async {
    final repo = FakeAuthRepository()..bloqueadoPor = TooManyAttemptsException(2);
    final vm = await enLogin(repo, InMemoryTokenStorage());

    await vm.submit(usuario: 'alex', contrasena: 'contraseña-valida', dispositivo: 'Pixel 8');
    expect(vm.stage, AuthStage.blocked);
    expect(vm.blockedSecondsLeft, 2);

    await Future<void>.delayed(const Duration(milliseconds: 2200));

    expect(vm.stage, AuthStage.needsLogin);
    expect(vm.blockedSecondsLeft, lessThanOrEqualTo(0));
  });

  test('submit con una sesión activa espera la confirmación y la cuenta atrás baja', () async {
    final repo = FakeAuthRepository()..sesionActivaEnDispositivo = 'iPhone 15';
    final vm = await enLogin(
      repo,
      InMemoryTokenStorage(),
      pollInterval: const Duration(seconds: 1),
    );

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
    final vm = await enLogin(repo, storage, pollInterval: const Duration(milliseconds: 200));

    await vm.submit(usuario: 'alex', contrasena: 'contraseña-valida', dispositivo: 'Pixel 8');
    repo.approvePending();
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(vm.stage, AuthStage.loggedIn);
    expect(await storage.read(), isNotNull);
  });

  test('cuando se rechaza la solicitud, vuelve al login con un aviso', () async {
    final repo = FakeAuthRepository()..sesionActivaEnDispositivo = 'iPhone 15';
    final vm = await enLogin(
      repo,
      InMemoryTokenStorage(),
      pollInterval: const Duration(milliseconds: 200),
    );

    await vm.submit(usuario: 'alex', contrasena: 'contraseña-valida', dispositivo: 'Pixel 8');
    repo.rejectPending();
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(vm.stage, AuthStage.needsLogin);
    expect(vm.error, isNotNull);
  });

  test('cuando caduca la solicitud, vuelve al login con un aviso', () async {
    final repo = FakeAuthRepository()..sesionActivaEnDispositivo = 'iPhone 15';
    final vm = await enLogin(
      repo,
      InMemoryTokenStorage(),
      pollInterval: const Duration(milliseconds: 200),
    );

    await vm.submit(usuario: 'alex', contrasena: 'contraseña-valida', dispositivo: 'Pixel 8');
    repo.expirePending();
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(vm.stage, AuthStage.needsLogin);
    expect(vm.error, isNotNull);
  });

  test('cancelPending() deja de esperar y vuelve al login', () async {
    final repo = FakeAuthRepository()..sesionActivaEnDispositivo = 'iPhone 15';
    final vm = await enLogin(repo, InMemoryTokenStorage());
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
    return arrancar(repo, storage, onForgetDevice: onForgetDevice);
  }

  test('token expone el token de la sesión y se vacía al cerrar sesión', () async {
    final repo = FakeAuthRepository();
    final vm = await conSesion(repo, InMemoryTokenStorage());

    expect(vm.token, isNotNull);

    await vm.logout();

    expect(vm.token, isNull);
  });

  test(
    'un no_autenticado en una petición protegida borra el token y vuelve a la bienvenida',
    () async {
      final storage = InMemoryTokenStorage();
      var olvidado = false;
      final vm = await conSesion(
        FakeAuthRepository(),
        storage,
        onForgetDevice: () async => olvidado = true,
      );

      expect(vm.handleSessionError(NotAuthenticatedException()), isTrue);
      await Future<void>.delayed(Duration.zero);

      expect(vm.stage, AuthStage.welcome);
      expect(vm.sessionExpired, isFalse);
      expect(vm.paired, isTrue);
      expect(vm.token, isNull);
      expect(await storage.read(), isNull);
      expect(olvidado, isFalse);
    },
  );

  test(
    'un sesion_caducada en una petición protegida borra el token y avisa de que caducó',
    () async {
      final storage = InMemoryTokenStorage();
      final vm = await conSesion(FakeAuthRepository(), storage);

      expect(vm.handleSessionError(SessionExpiredException()), isTrue);
      await Future<void>.delayed(Duration.zero);

      expect(vm.stage, AuthStage.welcome);
      expect(vm.sessionExpired, isTrue);
      expect(vm.paired, isTrue);
      expect(vm.token, isNull);
      expect(await storage.read(), isNull);
    },
  );

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
    expect(vm.stage, AuthStage.welcome);
    expect(vm.paired, isFalse);
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

  test('logout() borra el token y vuelve a la bienvenida emparejada', () async {
    final repo = FakeAuthRepository();
    final storage = InMemoryTokenStorage();
    final vm = await enLogin(repo, storage);
    await vm.submit(usuario: 'alex', contrasena: 'contraseña-valida', dispositivo: 'Pixel 8');

    await vm.logout();

    expect(vm.stage, AuthStage.welcome);
    expect(vm.paired, isTrue);
    expect(await storage.read(), isNull);
    expect(repo.logoutCalls, 1);
  });

  test('unpair() borra el token y la marca y vuelve a la bienvenida', () async {
    final repo = FakeAuthRepository();
    final storage = InMemoryTokenStorage();
    final vm = await enLogin(repo, storage);
    await vm.submit(usuario: 'alex', contrasena: 'contraseña-valida', dispositivo: 'Pixel 8');

    await vm.unpair();

    expect(vm.stage, AuthStage.welcome);
    expect(vm.paired, isFalse);
    expect(await storage.read(), isNull);
    expect(repo.unpairCalls, 1);
  });

  group('agente inalcanzable', () {
    test('con token guardado: no lo borra y entra cuando el agente vuelve', () async {
      final fake = FakeAuthRepository.loggedIn();
      final repo = _Unreachable(inner: fake);
      final storage = InMemoryTokenStorage()..write('token-fake');
      final vm = await arrancar(repo, storage);

      expect(vm.stage, AuthStage.welcome);
      expect(await storage.read(), 'token-fake');

      repo.available = true;
      await vm.openLogin();

      expect(vm.stage, AuthStage.loggedIn);
    });

    test('un login sin conexión deja el error y vuelve al formulario', () async {
      final repo = _Unreachable()..available = true;
      final vm = await enLogin(repo, InMemoryTokenStorage());
      repo.available = false;

      await vm.submit(usuario: 'a', contrasena: 'b', dispositivo: 'c');

      expect(vm.stage, AuthStage.needsLogin);
      expect(vm.error, 'sin agente');
    });

    test('logout() y unpair() olvidan la sesión aunque el agente no responda', () async {
      final repo = _Unreachable()..available = true;
      final storage = InMemoryTokenStorage()..write('t0k3n');
      var olvidado = false;
      final vm = await arrancar(repo, storage, onForgetDevice: () async => olvidado = true);
      repo.available = false;

      await vm.logout();
      expect(await storage.read(), isNull);

      await vm.unpair();
      expect(olvidado, isTrue);
    });

    test('un fallo de red mientras espera la confirmación no la cancela', () async {
      final fake = FakeAuthRepository()..sesionActivaEnDispositivo = 'iPhone 15';
      final repo = _Unreachable(inner: fake)..available = true;
      final vm = await enLogin(
        repo,
        InMemoryTokenStorage(),
        pollInterval: const Duration(milliseconds: 100),
      );
      await vm.submit(usuario: 'alex', contrasena: 'contraseña-valida', dispositivo: 'Pixel 8');

      repo.available = false;
      await Future<void>.delayed(const Duration(milliseconds: 250));

      expect(vm.stage, AuthStage.pendingConfirmation);
      vm.cancelPending();
    });
  });
}

/// Falla con [error] mientras `available` sea false y, si no, delega en un
/// [FakeAuthRepository].
class _Unreachable implements AuthRepository {
  _Unreachable({FakeAuthRepository? inner, this.error}) : _inner = inner ?? FakeAuthRepository();

  final FakeAuthRepository _inner;
  bool available = false;

  /// Lo que se lanza sin agente; por defecto, un timeout.
  final Exception? error;

  T _guard<T>(T Function() call) {
    if (!available) {
      throw error ?? AgentUnavailableException('sin agente', cause: AgentUnavailableCause.timeout);
    }
    return call();
  }

  @override
  Future<AgentStatus> status() async => _guard(_inner.status).then((s) => s);

  @override
  Future<LoginOutcome> login({
    required String usuario,
    required String contrasena,
    required String dispositivo,
  }) async => _guard(
    () => _inner.login(usuario: usuario, contrasena: contrasena, dispositivo: dispositivo),
  );

  @override
  Future<LoggedIn> register({
    required String codigo,
    required String usuario,
    required String contrasena,
    required String dispositivo,
  }) async => _guard(
    () => _inner.register(
      codigo: codigo,
      usuario: usuario,
      contrasena: contrasena,
      dispositivo: dispositivo,
    ),
  );

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
