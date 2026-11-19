// Tests de la pantalla de login: cada estado de AuthViewModel y su formulario.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sysmote/core/theme/app_theme.dart';
import 'package:sysmote/core/theme/app_tokens.dart';
import 'package:sysmote/core/widgets/app_button.dart';
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

class _Down implements AuthRepository {
  bool available = false;
  final _inner = FakeAuthRepository();

  @override
  Future<AgentStatus> status() async {
    if (!available) throw AgentUnavailableException('El agente no respondió a tiempo');
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
  testWidgets('sin cuenta en el agente, avisa de crearla en la TUI', (tester) async {
    final vm = AuthViewModel(FakeAuthRepository(configurado: false), InMemoryTokenStorage());
    addTearDown(vm.dispose);
    await tester.pumpWidget(_app(vm));
    await tester.pump();

    expect(find.textContaining('Créala desde la TUI del PC'), findsOneWidget);
    expect(find.text('Entrar'), findsNothing);
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

  testWidgets('sin cuenta y con el registro abierto, muestra el formulario de registro', (
    tester,
  ) async {
    final vm = AuthViewModel(sinCuenta(), InMemoryTokenStorage());
    addTearDown(vm.dispose);
    await tester.pumpWidget(_app(vm));
    await tester.pump();

    expect(find.text('Crear la cuenta'), findsOneWidget);
    expect(find.text('Código de registro'), findsOneWidget);
    expect(find.text('Entrar'), findsNothing);
  });

  testWidgets('un registro correcto entra en sesión', (tester) async {
    final vm = AuthViewModel(sinCuenta(), InMemoryTokenStorage());
    addTearDown(vm.dispose);
    await tester.pumpWidget(_app(vm));
    await tester.pump();

    await rellenarRegistro(tester);

    expect(vm.stage, AuthStage.loggedIn);
  });

  testWidgets('un código caducado explica cómo generar otro', (tester) async {
    final vm = AuthViewModel(sinCuenta(caducado: true), InMemoryTokenStorage());
    addTearDown(vm.dispose);
    await tester.pumpWidget(_app(vm));
    await tester.pump();

    await rellenarRegistro(tester);

    expect(find.textContaining('ha caducado'), findsOneWidget);
    expect(
      find.textContaining('configuración inicial en la TUI para generar otro'),
      findsOneWidget,
    );
  });

  testWidgets('una contraseña débil muestra los motivos', (tester) async {
    final vm = AuthViewModel(sinCuenta(), InMemoryTokenStorage());
    addTearDown(vm.dispose);
    await tester.pumpWidget(_app(vm));
    await tester.pump();

    await rellenarRegistro(tester, contrasena: 'abc');

    expect(find.textContaining('Contraseña débil'), findsOneWidget);
    expect(vm.stage, AuthStage.needsRegistration);
  });

  testWidgets('con cuenta y sin sesión activa, muestra el formulario sin aviso', (tester) async {
    final vm = AuthViewModel(FakeAuthRepository(), InMemoryTokenStorage());
    addTearDown(vm.dispose);
    await tester.pumpWidget(_app(vm));
    await tester.pump();

    expect(find.text('Usuario'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Nombre de este dispositivo'), findsOneWidget);
    expect(find.textContaining('sesión activa en otro dispositivo'), findsNothing);
  });

  testWidgets('con sesión activa en otro dispositivo, avisa antes del login', (tester) async {
    final repo = FakeAuthRepository()..sesionActivaEnDispositivo = 'iPhone 15';
    final vm = AuthViewModel(repo, InMemoryTokenStorage());
    addTearDown(vm.dispose);
    await tester.pumpWidget(_app(vm));
    await tester.pump();

    expect(find.textContaining('sesión activa en otro dispositivo'), findsOneWidget);
  });

  testWidgets('credenciales correctas entran en sesión', (tester) async {
    final vm = AuthViewModel(FakeAuthRepository(), InMemoryTokenStorage());
    addTearDown(vm.dispose);
    await tester.pumpWidget(_app(vm));
    await tester.pump();

    await tester.enterText(find.byType(TextField).at(0), 'alex');
    await tester.enterText(find.byType(TextField).at(1), 'contraseña-valida');
    await tester.enterText(find.byType(TextField).at(2), 'Pixel 8');
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(vm.stage, AuthStage.loggedIn);
  });

  testWidgets('credenciales incorrectas muestran el error', (tester) async {
    final vm = AuthViewModel(FakeAuthRepository(), InMemoryTokenStorage());
    addTearDown(vm.dispose);
    await tester.pumpWidget(_app(vm));
    await tester.pump();

    await tester.enterText(find.byType(TextField).at(0), 'alex');
    await tester.enterText(find.byType(TextField).at(1), 'mala');
    await tester.enterText(find.byType(TextField).at(2), 'Pixel 8');
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Usuario o contraseña incorrectos'), findsOneWidget);
  });

  testWidgets('bloqueado muestra la cuenta atrás y deshabilita Entrar', (tester) async {
    final repo = FakeAuthRepository()..bloqueadoPor = TooManyAttemptsException(40);
    final vm = AuthViewModel(repo, InMemoryTokenStorage());
    await tester.pumpWidget(_app(vm));
    await tester.pump();

    await tester.enterText(find.byType(TextField).at(0), 'alex');
    await tester.enterText(find.byType(TextField).at(1), 'contraseña-valida');
    await tester.enterText(find.byType(TextField).at(2), 'Pixel 8');
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.textContaining('Demasiados intentos. Espera 40 s.'), findsOneWidget);
    final button = tester.widget<AppButton>(find.widgetWithText(AppButton, 'Entrar'));
    expect(button.onPressed, isNull);

    vm.dispose();
  });

  testWidgets('sesión activa en otro dispositivo: espera con cuenta atrás y cancelar', (
    tester,
  ) async {
    final repo = FakeAuthRepository()..sesionActivaEnDispositivo = 'iPhone 15';
    final vm = AuthViewModel(repo, InMemoryTokenStorage());
    addTearDown(vm.dispose);
    await tester.pumpWidget(_app(vm));
    await tester.pump();

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

  testWidgets('sin conexión con el agente, avisa y deja reintentar', (tester) async {
    final repo = _Down();
    final vm = AuthViewModel(repo, InMemoryTokenStorage());
    addTearDown(vm.dispose);
    await tester.pumpWidget(_app(vm));
    await tester.pump();

    expect(find.text('No se puede conectar con el agente'), findsOneWidget);
    expect(find.text('El agente no respondió a tiempo'), findsOneWidget);

    repo.available = true;
    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Usuario'), findsOneWidget);
  });

  testWidgets('«Conexión con el PC» abre los campos de dirección y huella', (tester) async {
    final vm = AuthViewModel(FakeAuthRepository(), InMemoryTokenStorage());
    addTearDown(vm.dispose);
    await tester.pumpWidget(_app(vm));
    await tester.pump();

    await tester.ensureVisible(find.text('Conexión con el PC'));
    await tester.tap(find.text('Conexión con el PC'));
    await tester.pumpAndSettle();

    expect(find.text('Local'), findsOneWidget);
    expect(find.text('iroh'), findsOneWidget);
    expect(find.text('Guardar'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(5));
  });
}
