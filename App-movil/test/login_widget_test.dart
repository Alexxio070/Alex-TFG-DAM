// Tests de la pantalla de login: la bienvenida con sus popups y avisos, y cada formulario.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sysmote/core/theme/app_theme.dart';
import 'package:sysmote/core/theme/app_tokens.dart';
import 'package:sysmote/core/widgets/app_button.dart';
import 'package:sysmote/data/device_name.dart';
import 'package:sysmote/data/models/auth.dart';
import 'package:sysmote/data/repositories/auth_repository.dart';
import 'package:sysmote/data/repositories/agent_exceptions.dart';
import 'package:sysmote/features/auth/auth_viewmodel.dart';
import 'package:sysmote/features/auth/login_view.dart';
import 'package:sysmote/features/settings/settings_viewmodel.dart';

import 'fakes/fake_auth_repository.dart';
import 'fakes/in_memory_settings_repository.dart';
import 'fakes/in_memory_token_storage.dart';

Widget _app(AuthViewModel vm) => MultiProvider(
  providers: [
    ChangeNotifierProvider.value(value: vm),
    ChangeNotifierProvider(create: (_) => SettingsViewModel(InMemorySettingsRepository())),
  ],
  child: MaterialApp(
    theme: buildTheme(dark: false, accent: kAccentColors.first),
    home: const LoginView(),
  ),
);

/// ViewModel con la marca de emparejada en memoria.
AuthViewModel _vm(AuthRepository repo, {bool paired = true}) {
  var marca = paired;
  return AuthViewModel(
    repo,
    InMemoryTokenStorage(),
    isPaired: () => marca,
    markPaired: () async => marca = true,
  );
}

/// Monta la bienvenida y pulsa [boton].
Future<void> _abrir(WidgetTester tester, AuthViewModel vm, String boton) async {
  addTearDown(vm.dispose);
  await tester.pumpWidget(_app(vm));
  await tester.pump();
  await tester.tap(find.text(boton));
  await tester.pump();
  await tester.pump();
}

/// Sin agente mientras [cause] no sea null; si no, delega en un [FakeAuthRepository].
class _Down implements AuthRepository {
  _Down([this.cause = AgentUnavailableCause.timeout]);

  AgentUnavailableCause? cause;
  final _inner = FakeAuthRepository();

  @override
  Future<AgentStatus> status() async {
    if (cause case final cause?) throw AgentUnavailableException('x', cause: cause);
    return _inner.status();
  }

  @override
  Future<LoginOutcome> login({
    required String usuario,
    required String contrasena,
    required String dispositivo,
  }) => _inner.login(usuario: usuario, contrasena: contrasena, dispositivo: dispositivo);

  @override
  Future<LoggedIn> register({
    required String codigo,
    required String usuario,
    required String contrasena,
    required String dispositivo,
  }) => _inner.register(
    codigo: codigo,
    usuario: usuario,
    contrasena: contrasena,
    dispositivo: dispositivo,
  );

  @override
  Future<LoginRequestStatus> checkLoginRequest(String solicitudId) =>
      _inner.checkLoginRequest(solicitudId);

  @override
  Future<SessionInfo> session() => _inner.session();

  @override
  Future<void> logout() => _inner.logout();

  @override
  Future<void> unpair() => _inner.unpair();
}

void main() {
  group('bienvenida', () {
    testWidgets('sin emparejar solo ofrece conectar con el agente, sin avisos', (tester) async {
      final vm = _vm(_Down(), paired: false);
      addTearDown(vm.dispose);
      await tester.pumpWidget(_app(vm));
      await tester.pump();

      expect(find.text('Sysmote'), findsOneWidget);
      expect(find.text('Conectar con el agente'), findsOneWidget);
      expect(find.text('Iniciar sesión'), findsNothing);
      expect(find.text('Registrar cuenta'), findsNothing);
      expect(find.text('El PC no responde. ¿Está encendido y en la misma red?'), findsNothing);
    });

    testWidgets('«Conectar con el agente» abre los campos de dirección y huella', (tester) async {
      await _abrir(tester, _vm(_Down(), paired: false), 'Conectar con el agente');
      await tester.pumpAndSettle();

      expect(find.text('Local'), findsOneWidget);
      expect(find.text('iroh'), findsOneWidget);
      expect(find.text('Guardar'), findsOneWidget);
    });

    testWidgets('emparejada ofrece iniciar sesión y registrar cuenta', (tester) async {
      final vm = _vm(FakeAuthRepository());
      addTearDown(vm.dispose);
      await tester.pumpWidget(_app(vm));
      await tester.pump();

      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(find.text('Registrar cuenta'), findsOneWidget);
      expect(find.text('Conectar con el agente'), findsNothing);
    });

    for (final (cause, message) in [
      (AgentUnavailableCause.timeout, 'El PC no responde. ¿Está encendido y en la misma red?'),
      (AgentUnavailableCause.unreachable, 'No se puede llegar al PC. Revisa la dirección.'),
      (AgentUnavailableCause.fingerprint, 'La huella no coincide con la de este PC.'),
      (AgentUnavailableCause.invalidIrohId, 'El identificador del PC no es válido.'),
      (AgentUnavailableCause.unexpected, 'El agente respondió algo inesperado.'),
    ]) {
      testWidgets('sin respuesta por ${cause.name}: aviso en gris sin reintentar', (tester) async {
        final vm = _vm(_Down(cause));
        addTearDown(vm.dispose);
        await tester.pumpWidget(_app(vm));
        await tester.pump();

        expect(find.text(message), findsOneWidget);
        expect(find.text('Reintentar'), findsNothing);
        expect(find.text('Iniciar sesión'), findsOneWidget);
      });
    }

    testWidgets('al pulsar un botón vuelve a comprobar el agente', (tester) async {
      final repo = _Down();
      final vm = _vm(repo);
      addTearDown(vm.dispose);
      await tester.pumpWidget(_app(vm));
      await tester.pump();
      repo.cause = null;

      await tester.tap(find.text('Iniciar sesión'));
      await tester.pump();
      await tester.pump();

      expect(find.text('El PC no responde. ¿Está encendido y en la misma red?'), findsNothing);
      expect(find.text('Usuario'), findsOneWidget);
    });

    for (final (repo, boton, popup) in [
      (FakeAuthRepository(), 'Registrar cuenta', kAccountExistsPopup),
      (
        FakeAuthRepository(configurado: false, registroAbierto: true),
        'Iniciar sesión',
        kNoAccountPopup,
      ),
      (FakeAuthRepository(configurado: false), 'Iniciar sesión', kRegistrationClosedPopup),
      (FakeAuthRepository(configurado: false), 'Registrar cuenta', kRegistrationClosedPopup),
    ]) {
      testWidgets('«$boton» muestra el popup «$popup»', (tester) async {
        await _abrir(tester, _vm(repo), boton);
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text(popup), findsOneWidget);

        await tester.tap(find.text('Aceptar'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        expect(find.text('Iniciar sesión'), findsOneWidget);
      });
    }

    for (final (error, popup) in <(Exception, String)>[
      (SessionExpiredException(), kSessionExpiredPopup),
      (NotAuthenticatedException(), kSessionInvalidPopup),
    ]) {
      testWidgets('${error.runtimeType} avisa con un popup una sola vez', (tester) async {
        final vm = _vm(FakeAuthRepository());
        addTearDown(vm.dispose);
        await tester.pumpWidget(_app(vm));
        await tester.pump();

        vm.handleSessionError(error);
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text(popup), findsOneWidget);

        await tester.tap(find.text('Aceptar'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        expect(find.text('Iniciar sesión'), findsOneWidget);
      });
    }

    testWidgets('un token que el agente no reconoce avisa nada más arrancar', (tester) async {
      final storage = InMemoryTokenStorage()..write('token-viejo');
      final vm = AuthViewModel(
        FakeAuthRepository(),
        storage,
        isPaired: () => true,
        markPaired: () async {},
      );
      addTearDown(vm.dispose);
      await tester.pumpWidget(_app(vm));
      await tester.pumpAndSettle();

      expect(find.text(kSessionInvalidPopup), findsOneWidget);
    });

    testWidgets('un desemparejado no avisa con ningún popup', (tester) async {
      final vm = _vm(FakeAuthRepository());
      addTearDown(vm.dispose);
      await tester.pumpWidget(_app(vm));
      await tester.pump();

      vm.handleSessionError(UnpairedException());
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  FakeAuthRepository sinCuenta({bool caducado = false}) => FakeAuthRepository(
    configurado: false,
    registroAbierto: true,
    codigoRegistro: 'K7QXM2PD9WTR4HNB',
    codigoCaducado: caducado,
  );

  Future<void> rellenarRegistro(WidgetTester tester, {String contrasena = 'Abcd1'}) async {
    await tester.enterText(find.byType(TextField).at(0), 'K7QX-M2PD-9WTR-4HNB');
    await tester.enterText(find.byType(TextField).at(1), 'alex');
    await tester.enterText(find.byType(TextField).at(2), contrasena);
    await tester.enterText(find.byType(TextField).at(3), 'Pixel 8');
    await tester.tap(find.text('Crear cuenta'));
    await tester.pump();
  }

  testWidgets('«Registrar cuenta» con el registro abierto muestra el formulario', (tester) async {
    await _abrir(tester, _vm(sinCuenta()), 'Registrar cuenta');

    expect(find.text('Crear la cuenta'), findsOneWidget);
    expect(find.text('Código de registro'), findsOneWidget);
    expect(find.text('Conexión con el PC'), findsNothing);
    expect(find.text('Entrar'), findsNothing);
  });

  testWidgets('si otro móvil se adelanta al registrar, vuelve con el popup', (tester) async {
    final repo = sinCuenta();
    await _abrir(tester, _vm(repo), 'Registrar cuenta');
    repo.configurado = true;

    await rellenarRegistro(tester);
    await tester.pumpAndSettle();

    expect(find.text(kAccountExistsPopup), findsOneWidget);
    expect(find.text('Registrar cuenta'), findsOneWidget);
  });

  testWidgets('«Volver» y el gesto atrás vuelven a la bienvenida', (tester) async {
    final vm = _vm(sinCuenta());
    await _abrir(tester, vm, 'Registrar cuenta');

    await tester.ensureVisible(find.text('Volver'));
    await tester.tap(find.text('Volver'));
    await tester.pump();

    expect(vm.stage, AuthStage.welcome);

    await tester.tap(find.text('Registrar cuenta'));
    await tester.pump();
    await tester.pump();
    expect(vm.stage, AuthStage.needsRegistration);

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(vm.stage, AuthStage.welcome);
  });

  testWidgets('un registro correcto entra en sesión', (tester) async {
    final vm = _vm(sinCuenta());
    await _abrir(tester, vm, 'Registrar cuenta');

    await rellenarRegistro(tester);

    expect(vm.stage, AuthStage.loggedIn);
  });

  testWidgets('un código caducado explica cómo generar otro', (tester) async {
    await _abrir(tester, _vm(sinCuenta(caducado: true)), 'Registrar cuenta');

    await rellenarRegistro(tester);

    expect(find.textContaining('ha caducado'), findsOneWidget);
    expect(
      find.textContaining('configuración inicial en la TUI para generar otro'),
      findsOneWidget,
    );
  });

  testWidgets('una contraseña débil muestra los motivos', (tester) async {
    final vm = _vm(sinCuenta());
    await _abrir(tester, vm, 'Registrar cuenta');

    await rellenarRegistro(tester, contrasena: 'abc');

    expect(find.textContaining('Contraseña débil'), findsOneWidget);
    expect(vm.stage, AuthStage.needsRegistration);
  });

  testWidgets('con cuenta y sin sesión activa, muestra el formulario sin aviso', (tester) async {
    final vm = _vm(FakeAuthRepository());
    await _abrir(tester, vm, 'Iniciar sesión');

    expect(find.text('Usuario'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Nombre de este dispositivo (opcional)'), findsOneWidget);
    expect(find.textContaining('sesión activa en otro dispositivo'), findsNothing);
  });

  testWidgets('con sesión activa en otro dispositivo, avisa antes del login', (tester) async {
    final repo = FakeAuthRepository()..sesionActivaEnDispositivo = 'iPhone 15';
    final vm = _vm(repo);
    await _abrir(tester, vm, 'Iniciar sesión');

    expect(find.textContaining('sesión activa en otro dispositivo'), findsOneWidget);
  });

  testWidgets('credenciales correctas entran en sesión', (tester) async {
    final vm = _vm(FakeAuthRepository());
    await _abrir(tester, vm, 'Iniciar sesión');

    await tester.enterText(find.byType(TextField).at(0), 'alex');
    await tester.enterText(find.byType(TextField).at(1), 'contraseña-valida');
    await tester.enterText(find.byType(TextField).at(2), 'Pixel 8');
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(vm.stage, AuthStage.loggedIn);
  });

  testWidgets('credenciales incorrectas muestran el error', (tester) async {
    final vm = _vm(FakeAuthRepository());
    await _abrir(tester, vm, 'Iniciar sesión');

    await tester.enterText(find.byType(TextField).at(0), 'alex');
    await tester.enterText(find.byType(TextField).at(1), 'mala');
    await tester.enterText(find.byType(TextField).at(2), 'Pixel 8');
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Usuario o contraseña incorrectos'), findsOneWidget);
  });

  testWidgets('sin usuario o contraseña avisa de lo que falta', (tester) async {
    final vm = _vm(FakeAuthRepository());
    await _abrir(tester, vm, 'Iniciar sesión');

    await tester.enterText(find.byType(TextField).at(0), 'alex');
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Escribe el usuario y la contraseña.'), findsOneWidget);
    expect(vm.stage, isNot(AuthStage.loggedIn));
  });

  testWidgets('sin nombre de dispositivo entra con el nombre por defecto', (tester) async {
    final repo = FakeAuthRepository();
    final vm = _vm(repo);
    await _abrir(tester, vm, 'Iniciar sesión');

    await tester.enterText(find.byType(TextField).at(0), 'alex');
    await tester.enterText(find.byType(TextField).at(1), 'contraseña-valida');
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(vm.stage, AuthStage.loggedIn);
    expect((await repo.session()).dispositivo, kDefaultDeviceName);
  });

  testWidgets('sin código, usuario o contraseña el registro avisa de lo que falta', (tester) async {
    final vm = _vm(sinCuenta());
    await _abrir(tester, vm, 'Registrar cuenta');

    await tester.tap(find.text('Crear cuenta'));
    await tester.pump();

    expect(find.text('Escribe el código, el usuario y la contraseña.'), findsOneWidget);
    expect(vm.stage, AuthStage.needsRegistration);
  });

  testWidgets('bloqueado muestra la cuenta atrás y deshabilita Entrar', (tester) async {
    final repo = FakeAuthRepository()..bloqueadoPor = TooManyAttemptsException(40);
    final vm = _vm(repo);
    await _abrir(tester, vm, 'Iniciar sesión');

    await tester.enterText(find.byType(TextField).at(0), 'alex');
    await tester.enterText(find.byType(TextField).at(1), 'contraseña-valida');
    await tester.enterText(find.byType(TextField).at(2), 'Pixel 8');
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.textContaining('Demasiados intentos. Espera 40 s.'), findsOneWidget);
    final button = tester.widget<AppButton>(find.widgetWithText(AppButton, 'Entrar'));
    expect(button.onPressed, isNull);

    vm.backToWelcome();
  });

  testWidgets('sesión activa en otro dispositivo: espera con cuenta atrás y cancelar', (
    tester,
  ) async {
    final repo = FakeAuthRepository()..sesionActivaEnDispositivo = 'iPhone 15';
    final vm = _vm(repo);
    await _abrir(tester, vm, 'Iniciar sesión');

    await tester.enterText(find.byType(TextField).at(0), 'alex');
    await tester.enterText(find.byType(TextField).at(1), 'contraseña-valida');
    await tester.enterText(find.byType(TextField).at(2), 'Pixel 8');
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.textContaining('Hay una sesión activa en iPhone 15'), findsOneWidget);
    expect(find.text('5:00'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pump();

    expect(vm.stage, AuthStage.needsLogin);
    expect(find.text('Usuario'), findsOneWidget);
  });

  testWidgets('el login no tiene «Conexión con el PC» y «Volver» regresa', (tester) async {
    final vm = _vm(FakeAuthRepository());
    await _abrir(tester, vm, 'Iniciar sesión');

    expect(find.text('Conexión con el PC'), findsNothing);

    await tester.ensureVisible(find.text('Volver'));
    await tester.tap(find.text('Volver'));
    await tester.pump();

    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Usuario'), findsNothing);
  });
}
