import 'package:flutter_test/flutter_test.dart';
import 'package:tfg/data/models/metrics.dart';
import 'package:tfg/data/repositories/metrics_repository.dart';
import 'package:tfg/features/metrics/metrics_viewmodel.dart';

class _FlakyMetricsRepository implements MetricsRepository {
  bool shouldFail = true;

  @override
  Future<MachineInfo> loadInfo() async {
    if (shouldFail) throw AgentUnavailableException('No se pudo conectar con el agente');
    return const MachineInfo(ramTotalGb: 16, partitions: []);
  }

  @override
  Future<List<MetricSample>> loadHistory() async {
    if (shouldFail) throw AgentUnavailableException('No se pudo conectar con el agente');
    return List.generate(60, (_) => const MetricSample(cpu: 10, tempC: 40, ramGb: 5));
  }

  @override
  Stream<MetricSample> watch() => const Stream.empty();
}

void main() {
  test('pasa a error si el repositorio falla al arrancar', () async {
    final repository = _FlakyMetricsRepository();
    final vm = MetricsViewModel(repository);

    vm.start();
    await Future<void>.delayed(Duration.zero);

    expect(vm.error, 'No se pudo conectar con el agente');
    expect(vm.ready, isFalse);
  });

  test('retry() se recupera cuando el agente vuelve a responder', () async {
    final repository = _FlakyMetricsRepository();
    final vm = MetricsViewModel(repository);

    vm.start();
    await Future<void>.delayed(Duration.zero);
    expect(vm.error, isNotNull);

    repository.shouldFail = false;
    vm.retry();
    await Future<void>.delayed(Duration.zero);

    expect(vm.error, isNull);
    expect(vm.ready, isTrue);
  });
}
