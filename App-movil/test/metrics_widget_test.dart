// Tests de la pantalla de Métricas: tarjetas, particiones, unidades, avisos y desbordes en móviles
// estrechos.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sysmote/app.dart';
import 'package:sysmote/data/models/metrics.dart';
import 'package:sysmote/data/repositories/agent_exceptions.dart';
import 'package:sysmote/data/repositories/metrics_repository.dart';
import 'package:sysmote/features/settings/settings_viewmodel.dart';

import 'helpers/app_harness.dart';

void main() {
  Future<void> openMetrics(WidgetTester tester, {MetricsRepository? repository, Size? size}) =>
      openSection(
        tester,
        'Métricas',
        root: app(metricsRepository: repository),
        size: size ?? const Size(700, 1400),
        pixelRatio: size == null ? 3 : 2,
      );

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
      tester.element(find.byType(SysmoteApp)),
      listen: false,
    );

    settings.setTempUnit(TempUnit.fahrenheit);
    settings.setStorageUnit(StorageUnit.gib);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Escala 86–212 °F'), findsOneWidget);
    expect(find.textContaining('GiB'), findsWidgets);
    await closeApp(tester);
  });

  testWidgets('el punto de montaje largo no desborda en un móvil estrecho', (tester) async {
    await openMetrics(tester, repository: _StaticMetricsRepository(), size: const Size(360, 800));
    expect(tester.takeException(), isNull);

    final gesture = await tester.startGesture(tester.getCenter(find.text('Uso de disco')));
    await tester.pump(const Duration(milliseconds: 1100));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    final mountRect = tester.getRect(find.text('/home/juegos-y-apss'));
    expect(mountRect.right, lessThanOrEqualTo(360));
    await closeApp(tester);
  });

  testWidgets('las tarjetas de CPU, temperatura y RAM no desbordan en un móvil estrecho', (
    tester,
  ) async {
    await openMetrics(tester, size: const Size(360, 800));

    expect(tester.takeException(), isNull);
    await closeApp(tester);
  });

  testWidgets('avisa cuando no hay sensor de temperatura', (tester) async {
    await openMetrics(tester, repository: _StaticMetricsRepository());

    expect(find.text('No se ha podido mostrar la temperatura'), findsOneWidget);
    await closeApp(tester);
  });

  testWidgets('avisa cuando no hay particiones y sigue mostrando el resto', (tester) async {
    await openMetrics(tester, repository: _StaticMetricsRepository(partitions: const []));

    expect(find.text('Uso de CPU'), findsOneWidget);
    expect(find.text('El agente no ha encontrado ninguna partición'), findsOneWidget);
    await closeApp(tester);
  });

  testWidgets('muestra un indicador mientras conecta con el agente', (tester) async {
    final pending = Completer<MachineInfo>();
    await openMetrics(tester, repository: _StaticMetricsRepository(info: pending.future));

    expect(find.text('Conectando con el agente…'), findsOneWidget);
    await closeApp(tester);
  });

  testWidgets('avisa si se pierde la conexión sin borrar los últimos datos', (tester) async {
    final samples = StreamController<MetricSample>();
    addTearDown(samples.close);
    await openMetrics(tester, repository: _StaticMetricsRepository(samples: samples.stream));

    // El aviso llega por el stream de forma asíncrona: hace falta un fotograma más.
    samples.addError(AgentUnavailableException('El agente no respondió a tiempo'));
    await pumpFor(tester, 200);
    expect(find.text('Conexión perdida. Reintentando…'), findsOneWidget);
    expect(find.text('Uso de CPU'), findsOneWidget);

    samples.add(const MetricSample(cpu: 20, tempC: null, ramGb: 15));
    await pumpFor(tester, 200);
    expect(find.text('Conexión perdida. Reintentando…'), findsNothing);
    await closeApp(tester);
  });
}

class _StaticMetricsRepository implements MetricsRepository {
  _StaticMetricsRepository({
    this.partitions = const [
      Partition(id: 'root', mount: '/', device: '/dev/nvme0n1p6', usedGb: 70, totalGb: 380),
      Partition(
        id: 'home',
        mount: '/home/juegos-y-apss',
        device: '/dev/nvme1n1p2',
        usedGb: 598,
        totalGb: 983,
      ),
    ],
    this.info,
    this.samples = const Stream.empty(),
  });

  final List<Partition> partitions;
  final Future<MachineInfo>? info;
  final Stream<MetricSample> samples;

  @override
  Future<MachineInfo> loadInfo() =>
      info ?? Future.value(MachineInfo(ramTotalGb: 34, partitions: partitions));

  @override
  Future<List<MetricSample>> loadHistory() async =>
      List.generate(kHistoryLength, (_) => const MetricSample(cpu: 10, tempC: null, ramGb: 15));

  @override
  Stream<MetricSample> watch() => samples;
}
