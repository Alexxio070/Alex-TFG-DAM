import 'models/metrics.dart';
import 'repositories/metrics_repository.dart';

/// Parte común de los repositorios que piden `/metrics` al agente: cada uno
/// solo decide cómo traer el JSON ([fetch]), por HTTP directo o por iroh.
abstract class AgentMetricsRepository implements MetricsRepository {
  /// Devuelve el JSON de `/metrics` o lanza [AgentUnavailableException].
  Future<Map<String, dynamic>> fetch();

  Future<T> _parsed<T>(T Function(Map<String, dynamic>) parse) async {
    final json = await fetch();
    try {
      return parse(json);
    } on TypeError {
      throw AgentUnavailableException('Respuesta del agente con formato inesperado');
    }
  }

  Partition _partition(Map<String, dynamic> json) => Partition(
    id: json['id'] as String,
    mount: json['mount'] as String,
    device: json['device'] as String,
    usedGb: (json['used_gb'] as num).toDouble(),
    totalGb: (json['total_gb'] as num).toDouble(),
  );

  MetricSample _sample(Map<String, dynamic> json) => MetricSample(
    cpu: (json['cpu_percent'] as num).toDouble(),
    tempC: (json['cpu_temp_c'] as num?)?.toDouble(),
    ramGb: (json['ram_used_gb'] as num).toDouble(),
  );

  @override
  Future<MachineInfo> loadInfo() => _parsed(
    (json) => MachineInfo(
      ramTotalGb: (json['ram_total_gb'] as num).toDouble(),
      partitions: [
        for (final p in json['partitions'] as List) _partition(p as Map<String, dynamic>),
      ],
    ),
  );

  @override
  Future<List<MetricSample>> loadHistory() async {
    final sample = await _parsed(_sample);
    return List.generate(kHistoryLength, (_) => sample);
  }

  @override
  Stream<MetricSample> watch() =>
      Stream.periodic(const Duration(seconds: 1)).asyncMap((_) => _parsed(_sample));
}
