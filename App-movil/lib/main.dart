import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/fake/fake_macro_repository.dart';
import 'data/fake/fake_metrics_repository.dart';
import 'data/fake/fake_pairing_repository.dart';
import 'data/repositories/macro_repository.dart';
import 'data/repositories/metrics_repository.dart';
import 'data/repositories/pairing_repository.dart';
import 'features/home/home_viewmodel.dart';
import 'features/metrics/metrics_viewmodel.dart';
import 'features/settings/settings_viewmodel.dart';
import 'features/shell/shell_viewmodel.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider<PairingRepository>(create: (_) => FakePairingRepository()),
        Provider<MacroRepository>(create: (_) => FakeMacroRepository()),
        Provider<MetricsRepository>(create: (_) => FakeMetricsRepository()),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        ChangeNotifierProvider(
          create: (context) => ShellViewModel(context.read<PairingRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => HomeViewModel(context.read<MacroRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => MetricsViewModel(context.read<MetricsRepository>()),
        ),
      ],
      child: const TfgApp(),
    ),
  );
}
