import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/fake/fake_macro_repository.dart';
import 'data/fake/fake_notes_repository.dart';
import 'data/fake/fake_pairing_repository.dart';
import 'data/fake/fake_terminal_repository.dart';
import 'data/http/http_metrics_repository.dart';
import 'data/local/shared_preferences_settings_repository.dart';
import 'data/repositories/macro_repository.dart';
import 'data/repositories/metrics_repository.dart';
import 'data/repositories/notes_repository.dart';
import 'data/repositories/pairing_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/terminal_repository.dart';
import 'features/home/home_viewmodel.dart';
import 'features/metrics/metrics_viewmodel.dart';
import 'features/notes/notes_viewmodel.dart';
import 'features/settings/settings_viewmodel.dart';
import 'features/shell/shell_viewmodel.dart';
import 'features/terminal/terminal_tabs_viewmodel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settingsRepository = SharedPreferencesSettingsRepository();

  runApp(
    MultiProvider(
      providers: [
        Provider<PairingRepository>(create: (_) => FakePairingRepository()),
        Provider<MacroRepository>(create: (_) => FakeMacroRepository()),
        Provider<NotesRepository>(create: (_) => FakeNotesRepository()),
        Provider<TerminalRepository Function()>(create: (_) => FakeTerminalRepository.new),
        Provider<SettingsRepository>(create: (_) => settingsRepository),
        ChangeNotifierProvider(
          create: (context) => SettingsViewModel(context.read<SettingsRepository>()),
        ),
        Provider<MetricsRepository>(
          create: (context) {
            final settings = context.read<SettingsViewModel>();
            return HttpMetricsRepository(() => settings.agentAddress);
          },
        ),
        ChangeNotifierProvider(
          create: (context) => ShellViewModel(context.read<PairingRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => HomeViewModel(context.read<MacroRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => MetricsViewModel(context.read<MetricsRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => NotesViewModel(
            context.read<NotesRepository>(),
            context.read<PairingRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              TerminalTabsViewModel(context.read<TerminalRepository Function()>()),
        ),
      ],
      child: const TfgApp(),
    ),
  );
}
