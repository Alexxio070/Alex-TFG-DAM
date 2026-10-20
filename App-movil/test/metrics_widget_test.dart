import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tfg/app.dart';
import 'package:tfg/data/models/metrics.dart';
import 'package:tfg/data/repositories/metrics_repository.dart';
import 'package:tfg/features/settings/settings_viewmodel.dart';

import 'helpers/app_harness.dart';

void main() {
  Future<void> openMetrics(WidgetTester tester) async {
    tester.view.physicalSize = const Size(700 * 3, 1400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Abrir menú'));
    await pumpFor(tester, 500);
    await tester.tap(find.text('Métricas'));
    await pumpFor(tester, 600);
  }

  Future<void> closeApp(WidgetTester tester) => tester.pumpWidget(const SizedBox());

  testWidgets('muestra las cuatro tarjetas con la partición del sistema', (tester) async {
    await openMetrics(tester);

    expect(find.text('Uso de CPU'), findsOneWidget);
    expect(find.text('Temperatura de CPU'), findsOneWidget);
    expect(find.text('Uso de RAM'), findsOneWidget);
    expect(find.text('Uso de disco'), findsOneWidget);
    expect(find.text('/'), findsOneWidget);
    await closeApp(tester);
  });

  testWidgets('cambia de partición desde el selector', (tester) async {
    await openMetrics(tester);

    await tester.tap(find.text('/'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('/mnt/datos'), findsOneWidget);

    await tester.tap(find.text('/home'));
    await pumpFor(tester, 300);

    expect(find.text('/mnt/datos'), findsNothing);
    expect(find.text('/home'), findsOneWidget);
    await closeApp(tester);
  });

  testWidgets('mantener pulsada la tarjeta de disco abre las particiones', (tester) async {
    await openMetrics(tester);

    final gesture = await tester.startGesture(tester.getCenter(find.text('Uso de disco')));
    await tester.pump(const Duration(milliseconds: 1100));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('/mnt/datos'), findsOneWidget);
    await closeApp(tester);
  });

  testWidgets('muestra temperatura en Fahrenheit y GiB según ajustes', (tester) async {
    await openMetrics(tester);
    final settings = Provider.of<SettingsViewModel>(
      tester.element(find.byType(TfgApp)),
      listen: false,
    );

    settings.setTempUnit(TempUnit.fahrenheit);
    settings.setStorageUnit(StorageUnit.gib);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Escala 86–212 °F'), findsOneWidget);
    expect(find.textContaining('GiB'), findsWidgets);
    await closeApp(tester);
  });

  testWidgets('avisa cuando no hay sensor de temperatura', (tester) async {
    tester.view.physicalSize = const Size(700 * 3, 1400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(metricsRepository: _NoTempMetricsRepository()));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Abrir menú'));
    await pumpFor(tester, 500);
    await tester.tap(find.text('Métricas'));
    await pumpFor(tester, 600);

    expect(find.text('No se ha podido mostrar la temperatura'), findsOneWidget);
    await closeApp(tester);
  });
}

class _NoTempMetricsRepository implements MetricsRepository {
  @override
  Future<MachineInfo> loadInfo() async => const MachineInfo(
        ramTotalGb: 16,
        partitions: [
          Partition(id: 'root', mount: '/', device: 'nvme0n1p2', usedGb: 64.2, totalGb: 120),
        ],
      );

  @override
  Future<List<MetricSample>> loadHistory() async =>
      List.generate(60, (_) => const MetricSample(cpu: 10, tempC: null, ramGb: 9));

  @override
  Stream<MetricSample> watch() => const Stream.empty();
}
