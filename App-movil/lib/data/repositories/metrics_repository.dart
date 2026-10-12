import '../models/metrics.dart';

abstract class MetricsRepository {
  Future<MachineInfo> loadInfo();
  Future<List<MetricSample>> loadHistory();
  Stream<MetricSample> watch();
}
