import 'dart:math';

import 'package:sysmote/data/models/metrics.dart';
import 'package:sysmote/data/repositories/metrics_repository.dart';

class FakeMetricsRepository implements MetricsRepository {
  final _random = Random();
  double _cpu = 30;
  double _ram = 9.2;

  MetricSample _next() {
    _cpu = (_cpu + _random.nextDouble() * 16 - 8).clamp(4, 96);
    _ram = (_ram + _random.nextDouble() * 0.6 - 0.3).clamp(6, 13.5);
    return MetricSample(
      cpu: _cpu,
      tempC: 40 + _cpu * 0.42 + _random.nextDouble() * 3,
      ramGb: _ram,
    );
  }

  @override
  Future<MachineInfo> loadInfo() async => const MachineInfo(
        ramTotalGb: 16,
        partitions: [
          Partition(id: 'root', mount: '/', device: 'nvme0n1p2', usedGb: 64.2, totalGb: 120),
          Partition(id: 'home', mount: '/home', device: 'nvme0n1p3', usedGb: 310.5, totalGb: 800),
          Partition(id: 'datos', mount: '/mnt/datos', device: 'sda1', usedGb: 1210, totalGb: 2000),
        ],
      );

  @override
  Future<List<MetricSample>> loadHistory() async => List.generate(kHistoryLength, (_) => _next());

  @override
  Stream<MetricSample> watch() => Stream.periodic(const Duration(seconds: 1), (_) => _next());
}
