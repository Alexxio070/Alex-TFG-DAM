import 'package:flutter_test/flutter_test.dart';
import 'package:sysmote/data/connection_mode_metrics_repository.dart';
import 'package:sysmote/data/models/metrics.dart';
import 'package:sysmote/data/models/settings.dart';
import 'package:sysmote/data/repositories/metrics_repository.dart';

class _FakeMetricsRepository implements MetricsRepository {
  _FakeMetricsRepository(this.ramTotalGb);

  final double ramTotalGb;

  @override
  Future<MachineInfo> loadInfo() async => MachineInfo(ramTotalGb: ramTotalGb, partitions: []);

  @override
  Future<List<MetricSample>> loadHistory() async => [];

  @override
  Stream<MetricSample> watch() => const Stream.empty();
}

void main() {
  test('usa el repositorio local cuando el modo es local', () async {
    var mode = ConnectionMode.local;
    final repository = ConnectionModeMetricsRepository(
      connectionMode: () => mode,
      local: _FakeMetricsRepository(16),
      iroh: _FakeMetricsRepository(32),
    );

    expect((await repository.loadInfo()).ramTotalGb, 16);
  });

  test('cambia al repositorio iroh en la siguiente llamada tras cambiar el modo', () async {
    var mode = ConnectionMode.local;
    final repository = ConnectionModeMetricsRepository(
      connectionMode: () => mode,
      local: _FakeMetricsRepository(16),
      iroh: _FakeMetricsRepository(32),
    );

    mode = ConnectionMode.iroh;

    expect((await repository.loadInfo()).ramTotalGb, 32);
  });
}
