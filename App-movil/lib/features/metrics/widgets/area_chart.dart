import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';

class AreaChart extends StatelessWidget {
  const AreaChart({
    super.key,
    required this.values,
    required this.min,
    required this.max,
    required this.label,
  });

  final List<double> values;
  final double min;
  final double max;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      image: true,
      label: label,
      child: SizedBox(
        height: 110,
        width: double.infinity,
        child: CustomPaint(
          painter: _AreaChartPainter(
            values: values,
            min: min,
            max: max,
            lineColor: t.accent,
            fillColor: t.accent.withValues(alpha: 0x1F / 255),
            gridColor: t.line,
            baseColor: t.borderStrong,
          ),
        ),
      ),
    );
  }
}

class _AreaChartPainter extends CustomPainter {
  _AreaChartPainter({
    required this.values,
    required this.min,
    required this.max,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
    required this.baseColor,
  });

  final List<double> values;
  final double min;
  final double max;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;
  final Color baseColor;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (final fraction in const [0.25, 0.5, 0.75]) {
      final y = size.height * fraction;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final y = size.height - 0.5;
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      Paint()
        ..color = baseColor
        ..strokeWidth = 1,
    );

    if (values.length < 2) return;
    final line = Path();
    for (var i = 0; i < values.length; i++) {
      final x = i * size.width / (values.length - 1);
      final ratio = (values[i].clamp(min, max) - min) / (max - min);
      final py = size.height - ratio * size.height;
      i == 0 ? line.moveTo(x, py) : line.lineTo(x, py);
    }
    final area = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(area, Paint()..color = fillColor);
    canvas.drawPath(
      line,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_AreaChartPainter old) =>
      old.values != values ||
      old.lineColor != lineColor ||
      old.gridColor != gridColor ||
      old.baseColor != baseColor;
}
