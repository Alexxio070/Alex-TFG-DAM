// Piezas de las tarjetas de Métricas.

import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../data/models/metrics.dart';
import 'area_chart.dart';

/// Tarjeta con título, valor actual, gráfico del último minuto y escala.
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.values,
    required this.min,
    required this.max,
    required this.scaleLabel,
  });

  final String title;
  final Widget value;
  final List<double> values;
  final double min;
  final double max;
  final String scaleLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return MetricSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            spacing: 8,
            children: [
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t.muted2),
                ),
              ),
              value,
            ],
          ),
          AreaChart(
            values: values,
            min: min,
            max: max,
            label: '$title en los últimos $kHistoryLength segundos',
          ),
          DefaultTextStyle(
            style: TextStyle(fontSize: 12, color: t.muted),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 8,
              children: [
                const Text('Hace $kHistoryLength s'),
                Flexible(
                  child: Text(
                    scaleLabel,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Text('Ahora'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Caja con el fondo y el borde de todas las tarjetas de Métricas.
class MetricSurface extends StatelessWidget {
  const MetricSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

/// Número grande con su unidad al lado.
class MetricValue extends StatelessWidget {
  const MetricValue({super.key, required this.number, required this.unit, this.color});

  final String number;
  final String unit;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Text.rich(
      TextSpan(
        text: number,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.56,
          color: color ?? t.ink,
        ),
        children: [
          TextSpan(
            text: ' $unit',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
              color: t.muted,
            ),
          ),
        ],
      ),
    );
  }
}
