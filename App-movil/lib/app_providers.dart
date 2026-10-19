import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

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

List<SingleChildWidget> buildProviders({
  required PairingRepository pairingRepository,
  required MacroRepository macroRepository,
  required NotesRepository notesRepository,
  required TerminalRepository Function() terminalRepositoryFactory,
  required SettingsRepository settingsRepository,
  required MetricsRepository Function(BuildContext) metricsRepositoryBuilder,
}) {
  return [
    Provider<PairingRepository>(create: (_) => pairingRepository),
    Provider<MacroRepository>(create: (_) => macroRepository),
    Provider<NotesRepository>(create: (_) => notesRepository),
    Provider<TerminalRepository Function()>(create: (_) => terminalRepositoryFactory),
    Provider<SettingsRepository>(create: (_) => settingsRepository),
    ChangeNotifierProvider(
      create: (context) => SettingsViewModel(context.read<SettingsRepository>()),
    ),
    Provider<MetricsRepository>(create: metricsRepositoryBuilder),
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
  ];
}
