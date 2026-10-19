import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/app_tokens.dart';
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
      home: settings.ready ? const ShellView() : const _LoadingPlaceholder(),
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      backgroundColor: t.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            CircularProgressIndicator(color: t.accent),
            Text(
              'Linux System Companion',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t.muted2),
            ),
          ],
        ),
      ),
    );
  }
}
