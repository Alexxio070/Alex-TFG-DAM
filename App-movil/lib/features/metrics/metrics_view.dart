import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme/app_tokens.dart';
import '../settings/settings_viewmodel.dart';
import 'metrics_viewmodel.dart';
import 'widgets/disk_card.dart';
import 'widgets/metric_card.dart';

class MetricsView extends StatelessWidget {
  const MetricsView({super.key});

  @override
  Widget build(BuildContext context) {
    final metrics = context.watch<MetricsViewModel>();
    final settings = context.watch<SettingsViewModel>();
    final partition = metrics.partition;
    if (!metrics.ready || partition == null) return const SizedBox.shrink();

    final history = metrics.history;
    final ramTotal = metrics.info!.ramTotalGb;
    final unit = settings.storageUnit;
    final fahrenheit = settings.tempUnit == TempUnit.fahrenheit;
    final tempNow = history.last.tempC;
    final hot = settings.tempAlert && tempNow > settings.tempLimit;
    final tempDisplay = fahrenheit ? tempNow * 9 / 5 + 32 : tempNow;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
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
          values: [for (final s in history) s.tempC],
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
