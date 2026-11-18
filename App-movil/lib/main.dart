import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'app_providers.dart';
import 'data/connection_mode_auth_repository.dart';
import 'data/connection_mode_metrics_repository.dart';
import 'data/fake/fake_macro_repository.dart';
import 'data/fake/fake_notes_repository.dart';
import 'data/fake/fake_terminal_repository.dart';
import 'data/http/http_auth_repository.dart';
import 'data/http/http_metrics_repository.dart';
import 'data/iroh/iroh_auth_repository.dart';
import 'data/iroh/iroh_connection.dart';
import 'data/iroh/iroh_metrics_repository.dart';
import 'data/local/secure_token_storage.dart';
import 'data/local/shared_preferences_settings_repository.dart';
import 'features/auth/auth_viewmodel.dart';
import 'features/settings/settings_viewmodel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settingsRepository = SharedPreferencesSettingsRepository();
  final tokenStorage = SecureTokenStorage();

  // Una sola conexión iroh compartida por Autenticación y Métricas.
  IrohConnection? irohConnection;
  IrohConnection connectionFor(SettingsViewModel settings) =>
      irohConnection ??= IrohConnection(() => settings.irohId);

  runApp(
    MultiProvider(
      providers: buildProviders(
        authRepositoryBuilder: (context) {
          final settings = context.read<SettingsViewModel>();
          return ConnectionModeAuthRepository(
            connectionMode: () => settings.connectionMode,
            local: HttpAuthRepository(
              () => settings.agentAddress,
              () => settings.fingerprint,
              tokenStorage,
            ),
            iroh: IrohAuthRepository(connectionFor(settings), tokenStorage),
          );
        },
        tokenStorage: tokenStorage,
        macroRepository: FakeMacroRepository(),
        notesRepository: FakeNotesRepository(),
        terminalRepositoryFactory: FakeTerminalRepository.new,
        settingsRepository: settingsRepository,
        metricsRepositoryBuilder: (context) {
          final settings = context.read<SettingsViewModel>();
          final auth = context.read<AuthViewModel>();
          return ConnectionModeMetricsRepository(
            connectionMode: () => settings.connectionMode,
            local: HttpMetricsRepository(
              () => settings.agentAddress,
              () => settings.fingerprint,
              () => auth.token,
            ),
            iroh: IrohMetricsRepository(connectionFor(settings), () => auth.token),
          );
        },
      ),
      child: const SysmoteApp(),
    ),
  );
}
