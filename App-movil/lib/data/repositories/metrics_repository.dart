import '../models/metrics.dart';

abstract class MetricsRepository {
  Future<MachineInfo> loadInfo();
  Future<List<MetricSample>> loadHistory();
  Stream<MetricSample> watch();
}

class AgentUnavailableException implements Exception {
  AgentUnavailableException(this.message);

  final String message;

  @override
  String toString() => message;
}
