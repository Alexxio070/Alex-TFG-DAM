// Lista única de providers y ViewModels de la app, compartida por main.dart (repositorios reales)
// y los tests (repositorios falsos).

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'data/repositories/auth_repository.dart';
import 'data/repositories/macro_repository.dart';
import 'data/repositories/metrics_repository.dart';
import 'data/repositories/notes_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/terminal_repository.dart';
import 'data/repositories/token_storage.dart';
import 'features/auth/auth_viewmodel.dart';
import 'features/home/home_viewmodel.dart';
import 'features/metrics/metrics_viewmodel.dart';
import 'features/notes/notes_viewmodel.dart';
import 'features/settings/settings_viewmodel.dart';
import 'features/shell/shell_viewmodel.dart';
import 'features/terminal/terminal_tabs_viewmodel.dart';

/// Registra los repositorios recibidos y los ViewModels que dependen de ellos. Los repositorios que
/// necesitan leer otros providers (ajustes, sesión) se reciben como constructores que reciben el
/// [BuildContext].
List<SingleChildWidget> buildProviders({
  required AuthRepository Function(BuildContext) authRepositoryBuilder,
  required TokenStorage tokenStorage,
  required MacroRepository macroRepository,
  required NotesRepository notesRepository,
  required TerminalRepository Function() terminalRepositoryFactory,
  required SettingsRepository settingsRepository,
  required MetricsRepository Function(BuildContext) metricsRepositoryBuilder,
}) {
  return [
    Provider<TokenStorage>(create: (_) => tokenStorage),
    Provider<MacroRepository>(create: (_) => macroRepository),
    Provider<NotesRepository>(create: (_) => notesRepository),
    Provider<TerminalRepository Function()>(create: (_) => terminalRepositoryFactory),
    Provider<SettingsRepository>(create: (_) => settingsRepository),
    ChangeNotifierProvider(
      create: (context) => SettingsViewModel(context.read<SettingsRepository>()),
    ),
    Provider<AuthRepository>(create: authRepositoryBuilder),
    ChangeNotifierProvider(
      create: (context) {
        final settings = context.read<SettingsViewModel>();
        return AuthViewModel(
          context.read<AuthRepository>(),
          context.read<TokenStorage>(),
          onForgetDevice: () async {
            await settings.setAgentAddress(kDefaultAgentAddress);
            await settings.setFingerprint('');
            await settings.setIrohId('');
            await settings.setPaired(false);
          },
          isPaired: () => settings.paired,
          markPaired: () => settings.setPaired(true),
        );
      },
    ),
    Provider<MetricsRepository>(create: metricsRepositoryBuilder),
    ChangeNotifierProvider(create: (context) => ShellViewModel(context.read<AuthViewModel>())),
    ChangeNotifierProvider(create: (context) => HomeViewModel(context.read<MacroRepository>())),
    ChangeNotifierProvider(
      create: (context) =>
          MetricsViewModel(context.read<MetricsRepository>(), context.read<AuthViewModel>()),
    ),
    ChangeNotifierProvider(
      create: (context) =>
          NotesViewModel(context.read<NotesRepository>(), context.read<AuthViewModel>()),
    ),
    ChangeNotifierProvider(
      create: (context) => TerminalTabsViewModel(context.read<TerminalRepository Function()>()),
    ),
  ];
}
