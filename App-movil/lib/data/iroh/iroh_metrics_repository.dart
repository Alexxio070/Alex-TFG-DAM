import 'dart:convert';

import '../agent_metrics_repository.dart';
import '../repositories/metrics_repository.dart';
import 'iroh_connection.dart';

export 'iroh_connection.dart' show IrohConnector, IrohLink;

final _request = buildRawHttpRequest('GET', '/metrics');

/// Pide `/metrics` al agente a través de un túnel iroh: la misma petición
/// HTTP que [HttpMetricsRepository], enviada por un *stream* de iroh.
class IrohMetricsRepository extends AgentMetricsRepository {
  IrohMetricsRepository(
    String Function() endpointId, {
    IrohConnector? connector,
    IrohConnection? connection,
  }) : _connection = connection ?? IrohConnection(endpointId, connector: connector);

  final IrohConnection _connection;

  @override
  Future<Map<String, dynamic>> fetch() async {
    final response = parseRawHttpResponse(await _connection.request(_request));
    if (response.status != 200) {
      throw AgentUnavailableException('El agente respondió con un formato inesperado');
    }
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw AgentUnavailableException('Respuesta del agente con formato inesperado');
    }
  }
}
