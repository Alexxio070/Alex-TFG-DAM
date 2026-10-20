import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tfg/app.dart';
import 'package:tfg/app_providers.dart';
import 'package:tfg/data/fake/fake_macro_repository.dart';
import 'package:tfg/data/fake/fake_notes_repository.dart';
import 'package:tfg/data/fake/fake_pairing_repository.dart';
import 'package:tfg/data/fake/fake_terminal_repository.dart';
import 'package:tfg/data/repositories/metrics_repository.dart';
import 'package:tfg/data/repositories/notes_repository.dart';

import '../fakes/fake_metrics_repository.dart';
import '../fakes/in_memory_settings_repository.dart';

Widget app({MetricsRepository? metricsRepository, NotesRepository? notesRepository}) =>
    MultiProvider(
      providers: buildProviders(
        pairingRepository: FakePairingRepository(),
        macroRepository: FakeMacroRepository(),
        notesRepository: notesRepository ?? FakeNotesRepository(),
        terminalRepositoryFactory: FakeTerminalRepository.new,
        settingsRepository: InMemorySettingsRepository(),
        metricsRepositoryBuilder: (_) => metricsRepository ?? FakeMetricsRepository(),
      ),
      child: const TfgApp(),
    );

Future<void> pumpFor(WidgetTester tester, int milliseconds) async {
  for (var elapsed = 0; elapsed < milliseconds; elapsed += 100) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
