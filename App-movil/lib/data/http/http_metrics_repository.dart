import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../agent_metrics_repository.dart';
import '../repositories/metrics_repository.dart';

class HttpMetricsRepository extends AgentMetricsRepository {
  HttpMetricsRepository(this.address, {http.Client? client}) : _client = client ?? http.Client();

  final String Function() address;
  final http.Client _client;

  @override
  Future<Map<String, dynamic>> fetch() async {
    http.Response response;
    try {
      response = await _client
          .get(Uri.parse('http://${address()}/metrics'))
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
}
