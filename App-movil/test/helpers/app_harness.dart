// Utilidades comunes de los tests de pantalla: montar la app con repositorios falsos y avanzar el
// reloj.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sysmote/app.dart';
import 'package:sysmote/app_providers.dart';
import 'package:sysmote/data/fake/fake_macro_repository.dart';
import 'package:sysmote/data/fake/fake_notes_repository.dart';
import 'package:sysmote/data/fake/fake_terminal_repository.dart';
import 'package:sysmote/data/repositories/auth_repository.dart';
import 'package:sysmote/data/repositories/metrics_repository.dart';
import 'package:sysmote/data/repositories/notes_repository.dart';

import '../fakes/fake_auth_repository.dart';
import '../fakes/fake_metrics_repository.dart';
import '../fakes/in_memory_settings_repository.dart';
import '../fakes/in_memory_token_storage.dart';

// Por defecto las pantallas se montan con la sesión ya abierta.
/// La app completa con repositorios falsos o en memoria. Sin [authRepository], arranca con la
/// sesión ya abierta.
Widget app({
  MetricsRepository? metricsRepository,
  NotesRepository? notesRepository,
  AuthRepository? authRepository,
}) => MultiProvider(
  providers: buildProviders(
    authRepositoryBuilder: (_) => authRepository ?? FakeAuthRepository.loggedIn(),
    tokenStorage: authRepository == null
        ? (InMemoryTokenStorage()..write('token-fake'))
        : InMemoryTokenStorage(),
    macroRepository: FakeMacroRepository(),
    notesRepository: notesRepository ?? FakeNotesRepository(),
    terminalRepositoryFactory: FakeTerminalRepository.new,
    settingsRepository: InMemorySettingsRepository(),
    metricsRepositoryBuilder: (_) => metricsRepository ?? FakeMetricsRepository(),
  ),
  child: const SysmoteApp(),
);

/// Monta [root] (por defecto, [app]) y espera a que se carguen los ajustes y arranque la sesión.
Future<void> startApp(WidgetTester tester, [Widget? root]) async {
  await tester.pumpWidget(root ?? app());
  await tester.pump();
  await tester.pump();
}

/// Avanza el reloj falso [milliseconds] en saltos de 100 ms, para esperar animaciones y
/// temporizadores.
Future<void> pumpFor(WidgetTester tester, int milliseconds) async {
  for (var elapsed = 0; elapsed < milliseconds; elapsed += 100) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Monta [root] (por defecto, [app]) en una pantalla de móvil de [size] puntos
/// y abre [section] desde el menú lateral.
Future<void> openSection(
  WidgetTester tester,
  String section, {
  Widget? root,
  Size size = const Size(390, 844),
  double pixelRatio = 3,
}) async {
  tester.view.physicalSize = size * pixelRatio;
  tester.view.devicePixelRatio = pixelRatio;
  addTearDown(tester.view.reset);
  await startApp(tester, root);
  await tester.tap(find.bySemanticsLabel('Abrir menú'));
  await pumpFor(tester, 500);
  await tester.tap(find.bySemanticsLabel(section));
  await pumpFor(tester, 600);
}
