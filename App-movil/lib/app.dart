import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/settings/settings_viewmodel.dart';
import 'features/shell/shell_view.dart';

class TfgApp extends StatelessWidget {
  const TfgApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsViewModel>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Linux System Companion',
      theme: buildTheme(dark: settings.dark, accent: settings.accent),
      home: const ShellView(),
    );
  }
}
