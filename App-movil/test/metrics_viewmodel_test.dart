import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sysmote/data/models/metrics.dart';
import 'package:sysmote/data/repositories/metrics_repository.dart';
import 'package:sysmote/features/metrics/metrics_viewmodel.dart';

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

/// Cada `loadInfo()` queda pendiente hasta que el test lo completa.
class _SlowMetricsRepository implements MetricsRepository {
  final infoCalls = <Completer<MachineInfo>>[];
  int watchCalls = 0;

  @override
  Future<MachineInfo> loadInfo() {
    final call = Completer<MachineInfo>();
    infoCalls.add(call);
    return call.future;
  }

  @override
  Future<List<MetricSample>> loadHistory() async =>
      List.generate(60, (_) => const MetricSample(cpu: 10, tempC: 40, ramGb: 5));

  @override
  Stream<MetricSample> watch() {
    watchCalls++;
    return const Stream.empty();
  }
}

const _info = MachineInfo(ramTotalGb: 16, partitions: []);

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

  test('salir y volver rápido no deja dos suscripciones a watch()', () async {
    final repository = _SlowMetricsRepository();
    final vm = MetricsViewModel(repository);

    vm.start();
    await pumpEventQueue();
    vm.stop();
    vm.start();
    await pumpEventQueue();
    expect(repository.infoCalls, hasLength(2));

    repository.infoCalls[1].complete(_info);
    repository.infoCalls[0].complete(_info);
    await pumpEventQueue();

    expect(repository.watchCalls, 1);
  });

  test('retry() con una carga en curso descarta la anterior', () async {
    final repository = _SlowMetricsRepository();
    final vm = MetricsViewModel(repository);

    vm.start();
    await pumpEventQueue();
    vm.retry();
    await pumpEventQueue();

    repository.infoCalls[0].complete(_info);
    repository.infoCalls[1].complete(_info);
    await pumpEventQueue();

    expect(repository.watchCalls, 1);
  });
}
