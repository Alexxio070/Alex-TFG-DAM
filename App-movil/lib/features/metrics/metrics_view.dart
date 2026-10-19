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
    if (metrics.error != null && !metrics.ready) {
      return _ErrorState(message: metrics.error!, onRetry: metrics.retry);
    }
    final partition = metrics.partition;
    if (!metrics.ready || partition == null) return const SizedBox.shrink();

    final history = metrics.history;
    final ramTotal = metrics.info!.ramTotalGb;
    final unit = settings.storageUnit;
    final fahrenheit = settings.tempUnit == TempUnit.fahrenheit;
    final tempNow = history.last.tempC;
    final hot = tempNow != null && settings.tempAlert && tempNow > settings.tempLimit;
    final tempDisplay = tempNow == null ? null : (fahrenheit ? tempNow * 9 / 5 + 32 : tempNow);

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 32 + MediaQuery.paddingOf(context).bottom),
      children: [
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
          const _UnavailableTempCard()
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
            number: formatNumber(history.last.ramGb * unit.factor),
            unit: '/ ${formatNumber(ramTotal * unit.factor, unit == StorageUnit.gb ? 0 : 1)} ${unit.label}',
          ),
          values: [for (final s in history) s.ramGb],
          min: 0,
          max: ramTotal,
          scaleLabel:
              'Escala 0–${formatNumber(ramTotal * unit.factor, unit == StorageUnit.gb ? 0 : 1)} ${unit.label}',
        ),
        const SizedBox(height: 16),
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

class _UnavailableTempCard extends StatelessWidget {
  const _UnavailableTempCard();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return MetricSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Text(
            'Temperatura de CPU',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t.muted2),
          ),
          Text(
            'No se ha podido mostrar la temperatura',
            style: TextStyle(fontSize: 13, color: t.muted),
          ),
        ],
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
