/// Prueba de concepto de la fase 2: conectar por iroh al agente y mostrar
/// las métricas reales con el mismo widget de la app (gráficas en vivo).
///
/// Punto de entrada aislado, al margen de la app real. Se ejecuta con:
///   flutter run -t lib/debug/iroh_poc_main.dart
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/app_tokens.dart';
import '../data/iroh/iroh_metrics_repository.dart';
import '../data/local/shared_preferences_settings_repository.dart';
import '../features/metrics/metrics_view.dart';
import '../features/metrics/metrics_viewmodel.dart';
import '../features/settings/settings_viewmodel.dart';

void main() => runApp(const IrohPocApp());

class IrohPocApp extends StatelessWidget {
  const IrohPocApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(dark: false, accent: kAccentColors.first),
      home: ChangeNotifierProvider(
        create: (_) => SettingsViewModel(SharedPreferencesSettingsRepository()),
        child: const _IrohPocHome(),
      ),
    );
  }
}

class _IrohPocHome extends StatefulWidget {
  const _IrohPocHome();

  @override
  State<_IrohPocHome> createState() => _IrohPocHomeState();
}

class _IrohPocHomeState extends State<_IrohPocHome> {
  final _idController = TextEditingController();
  MetricsViewModel? _metricsViewModel;

  void _connect() {
    final id = _idController.text.trim();
    setState(() {
      _metricsViewModel = MetricsViewModel(IrohMetricsRepository(() => id));
    });
  }

  @override
  void dispose() {
    _idController.dispose();
    _metricsViewModel?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = _metricsViewModel;
    if (viewModel != null) {
      return ChangeNotifierProvider.value(
        value: viewModel,
        child: Scaffold(
          appBar: AppBar(title: const Text('PoC iroh')),
          body: const MetricsView(),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('PoC iroh')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _idController,
              decoration: const InputDecoration(labelText: 'Identificador iroh del agente (hex)'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _connect, child: const Text('Conectar')),
          ],
        ),
      ),
    );
  }
}
