import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/metrics.dart';
import '../repositories/metrics_repository.dart';

class HttpMetricsRepository implements MetricsRepository {
  HttpMetricsRepository(this.address, {http.Client? client}) : _client = client ?? http.Client();

  final String address;
  final http.Client _client;

  Future<Map<String, dynamic>> _fetch() async {
    final response = await _client.get(Uri.parse('http://$address/metrics'));
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Partition _partition(Map<String, dynamic> json) => Partition(
        id: json['id'] as String,
        mount: json['mount'] as String,
        device: json['device'] as String,
        usedGb: (json['used_gb'] as num).toDouble(),
        totalGb: (json['total_gb'] as num).toDouble(),
      );

  Future<MetricSample> _sample(Map<String, dynamic> json) async => MetricSample(
        cpu: (json['cpu_percent'] as num).toDouble(),
        tempC: (json['cpu_temp_c'] as num?)?.toDouble(),
        ramGb: (json['ram_used_gb'] as num).toDouble(),
      );

  @override
  Future<MachineInfo> loadInfo() async {
    final json = await _fetch();
    return MachineInfo(
      ramTotalGb: (json['ram_total_gb'] as num).toDouble(),
      partitions: [
        for (final p in json['partitions'] as List) _partition(p as Map<String, dynamic>),
      ],
    );
  }

  @override
  Future<List<MetricSample>> loadHistory() async {
    final sample = await _sample(await _fetch());
    return List.generate(60, (_) => sample);
  }

  @override
  Stream<MetricSample> watch() => Stream.periodic(const Duration(seconds: 1))
      .asyncMap((_) async => _sample(await _fetch()));
}
