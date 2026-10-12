import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/fake/fake_pairing_repository.dart';
import 'data/repositories/pairing_repository.dart';
import 'features/settings/settings_viewmodel.dart';
import 'features/shell/shell_viewmodel.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider<PairingRepository>(create: (_) => FakePairingRepository()),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        ChangeNotifierProvider(
          create: (context) => ShellViewModel(context.read<PairingRepository>()),
        ),
      ],
      child: const TfgApp(),
    ),
  );
}
