// Tests del formato de números y fechas relativas.

import 'package:flutter_test/flutter_test.dart';
import 'package:sysmote/core/format.dart';

void main() {
  group('formatNumber', () {
    test('usa coma decimal y un decimal por defecto', () {
      expect(formatNumber(64.25), '64,3');
    });

    test('respeta el número de decimales pedido', () {
      expect(formatNumber(64.25, 0), '64');
      expect(formatNumber(1.0, 2), '1,00');
    });
  });

  group('formatRelativeDate', () {
    final now = DateTime(2026, 10, 20, 12, 0, 0);

    test('menos de un minuto: "ahora"', () {
      final date = now.subtract(const Duration(seconds: 30));
      expect(formatRelativeDate(date, now), 'ahora');
    });

    test('menos de una hora: "hace N min"', () {
      final date = now.subtract(const Duration(minutes: 25));
      expect(formatRelativeDate(date, now), 'hace 25 min');
    });

    test('mismo día, hace más de una hora: "hoy"', () {
      final date = DateTime(2026, 10, 20, 2, 0, 0);
      expect(formatRelativeDate(date, now), 'hoy');
    });

    test('el día anterior: "ayer"', () {
      final date = now.subtract(const Duration(days: 1));
      expect(formatRelativeDate(date, now), 'ayer');
    });

    test('entre 2 y 6 días: abreviatura del día de la semana', () {
      final date = now.subtract(const Duration(days: 3));
      const names = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
      expect(formatRelativeDate(date, now), names[date.weekday - 1]);
    });

    test('7 días o más: dd/mm/aaaa', () {
      final date = now.subtract(const Duration(days: 10));
      expect(formatRelativeDate(date, now), '10/10/2026');
    });
  });
}
