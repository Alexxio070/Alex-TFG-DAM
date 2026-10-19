import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/metrics.dart';
import '../repositories/metrics_repository.dart';

class HttpMetricsRepository implements MetricsRepository {
  HttpMetricsRepository(this.address, {http.Client? client}) : _client = client ?? http.Client();

  final String address;
  final http.Client _client;

  Future<Map<String, dynamic>> _fetch() async {
    http.Response response;
    try {
      response = await _client
          .get(Uri.parse('http://$address/metrics'))
          .timeout(const Duration(seconds: 3));
    } on TimeoutException {
      throw AgentUnavailableException('El agente no respondió a tiempo');
    } catch (_) {
      throw AgentUnavailableException('No se pudo conectar con el agente');
    }
    if (response.statusCode != 200) {
      throw AgentUnavailableException('El agente respondió con el código ${response.statusCode}');
    }
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw AgentUnavailableException('Respuesta del agente con formato inesperado');
    }
  }

  Future<T> _parsed<T>(T Function(Map<String, dynamic>) parse) async {
    final json = await _fetch();
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
    return List.generate(60, (_) => sample);
  }

  @override
  Stream<MetricSample> watch() =>
      Stream.periodic(const Duration(seconds: 1)).asyncMap((_) => _parsed(_sample));
}
