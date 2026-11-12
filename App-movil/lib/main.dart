import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'app_providers.dart';
import 'data/fake/fake_macro_repository.dart';
import 'data/fake/fake_notes_repository.dart';
import 'data/fake/fake_pairing_repository.dart';
import 'data/fake/fake_terminal_repository.dart';
import 'data/http/http_metrics_repository.dart';
import 'data/local/shared_preferences_settings_repository.dart';
import 'features/settings/settings_viewmodel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settingsRepository = SharedPreferencesSettingsRepository();

  runApp(
    MultiProvider(
      providers: buildProviders(
        pairingRepository: FakePairingRepository(),
        macroRepository: FakeMacroRepository(),
        notesRepository: FakeNotesRepository(),
        terminalRepositoryFactory: FakeTerminalRepository.new,
        settingsRepository: settingsRepository,
        metricsRepositoryBuilder: (context) {
          final settings = context.read<SettingsViewModel>();
          return HttpMetricsRepository(() => settings.agentAddress);
        },
      ),
      child: const SysmoteApp(),
    ),
  );
}
