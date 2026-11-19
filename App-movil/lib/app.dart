// Raíz de la interfaz: aplica el tema de Ajustes y elige la pantalla según el estado de la sesión.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/app_tokens.dart';
import 'features/auth/auth_viewmodel.dart';
import 'features/auth/login_view.dart';
import 'features/settings/settings_viewmodel.dart';
import 'features/shell/shell_view.dart';

/// MaterialApp de Sysmote: pantalla de carga mientras se leen los ajustes, [ShellView] con la
/// sesión abierta y [LoginView] en cualquier otro caso.
class SysmoteApp extends StatelessWidget {
  const SysmoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsViewModel>();
    final auth = context.watch<AuthViewModel>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sysmote',
      theme: buildTheme(dark: settings.dark, accent: settings.accent),
      home: !settings.ready
          ? const _LoadingPlaceholder()
          : auth.stage == AuthStage.loggedIn
          ? const ShellView()
          : const LoginView(),
    );
  }
}

/// Pantalla que se ve mientras se cargan los ajustes guardados.
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
              'Sysmote',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t.muted2),
            ),
          ],
        ),
      ),
    );
  }
}
