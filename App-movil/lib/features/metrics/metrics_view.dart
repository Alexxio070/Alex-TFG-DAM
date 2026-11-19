import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_button.dart';
import '../settings/settings_viewmodel.dart';
import 'metrics_viewmodel.dart';
import 'widgets/disk_card.dart';
import 'widgets/metric_card.dart';

class MetricsView extends StatefulWidget {
  const MetricsView({super.key});

  @override
  State<MetricsView> createState() => _MetricsViewState();
}

class _MetricsViewState extends State<MetricsView> {
  late final MetricsViewModel _vm = context.read<MetricsViewModel>();
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _vm.start();
    _lifecycle = AppLifecycleListener(onResume: _vm.start, onPause: _vm.stop);
  }

  @override
  void dispose() {
    _vm.stop();
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metrics = context.watch<MetricsViewModel>();
    final settings = context.watch<SettingsViewModel>();
    final error = metrics.error;
    if (!metrics.ready) {
      return error == null
          ? const _LoadingState()
          : _ErrorState(message: error, onRetry: metrics.retry);
    }

    final partition = metrics.partition;
    final history = metrics.history;
    final ramTotal = metrics.info!.ramTotalGb;
    final unit = settings.storageUnit;
    final ramTotalLabel =
        '${unit.format(ramTotal, decimals: unit == StorageUnit.gb ? 0 : 1)} ${unit.label}';
    final fahrenheit = settings.tempUnit == TempUnit.fahrenheit;
    final tempNow = history.last.tempC;
    final hot = tempNow != null && settings.tempAlert && tempNow > settings.tempLimit;
    final tempDisplay = tempNow == null ? null : settings.tempUnit.fromCelsius(tempNow);

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 32 + MediaQuery.paddingOf(context).bottom),
      children: [
        // El repositorio sigue reintentando cada segundo: el aviso desaparece
        // solo en cuanto vuelve a llegar una muestra.
        if (error != null) ...[
          _ConnectionLostBanner(message: error),
          const SizedBox(height: 16),
        ],
        MetricCard(
          title: 'Uso de CPU',
          value: MetricValue(number: formatNumber(history.last.cpu, 0), unit: '%'),
          values: [for (final s in history) s.cpu],
          min: 0,
          max: 100,
          scaleLabel: 'Escala 0–100 %',
        ),
        const SizedBox(height: 16),
        if (tempDisplay == null)
          const _UnavailableCard(
            title: 'Temperatura de CPU',
            message: 'No se ha podido mostrar la temperatura',
          )
        else
          MetricCard(
            title: 'Temperatura de CPU',
            value: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              spacing: 8,
              children: [
                if (hot) const _HotBadge(),
                MetricValue(
                  number: formatNumber(tempDisplay, 0),
                  unit: fahrenheit ? '°F' : '°C',
                  color: hot ? kRed : null,
                ),
              ],
            ),
            values: [for (final s in history) s.tempC ?? 0],
            min: 30,
            max: 100,
            scaleLabel: fahrenheit ? 'Escala 86–212 °F' : 'Escala 30–100 °C',
          ),
        const SizedBox(height: 16),
        MetricCard(
          title: 'Uso de RAM',
          value: MetricValue(
            number: unit.format(history.last.ramGb),
            unit: '/ $ramTotalLabel',
          ),
          values: [for (final s in history) s.ramGb],
          min: 0,
          max: ramTotal,
          scaleLabel: 'Escala 0–$ramTotalLabel',
        ),
        const SizedBox(height: 16),
        if (partition == null)
          const _UnavailableCard(
            title: 'Uso de disco',
            message: 'El agente no ha encontrado ninguna partición',
          )
        else
          DiskCard(
            partitions: metrics.info!.partitions,
            selected: partition,
            unit: unit,
            onSelect: metrics.selectPartition,
          ),
      ],
    );
  }
}

class _UnavailableCard extends StatelessWidget {
  const _UnavailableCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return MetricSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t.muted2),
          ),
          Text(message, style: TextStyle(fontSize: 13, color: t.muted)),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          CircularProgressIndicator(color: t.accent),
          Text('Conectando con el agente…', style: TextStyle(fontSize: 13, color: t.muted)),
        ],
      ),
    );
  }
}

class _ConnectionLostBanner extends StatelessWidget {
  const _ConnectionLostBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: t.surface,
          border: Border.all(color: kRed),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          spacing: 12,
          children: [
            SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: kRed),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    'Conexión perdida. Reintentando…',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t.ink),
                  ),
                  Text(
                    '$message. Los datos de abajo son los últimos recibidos.',
                    style: TextStyle(fontSize: 12, color: t.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            Text(
              'No se puede conectar con el agente',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: t.ink),
            ),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: t.muted),
            ),
            const SizedBox(height: 6),
            AppButton(label: 'Reintentar', fill: t.accent, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

class _HotBadge extends StatelessWidget {
  const _HotBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: kRed, borderRadius: BorderRadius.circular(999)),
      child: const Text(
        'Alta',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
      ),
    );
  }
}
