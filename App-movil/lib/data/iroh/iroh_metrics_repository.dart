import 'dart:convert';

import '../agent_metrics_repository.dart';
import '../repositories/agent_exceptions.dart';
import 'iroh_connection.dart';

export 'iroh_connection.dart' show IrohConnector, IrohLink;

/// Pide `/metrics` al agente a través de un túnel iroh: la misma petición
/// HTTP que [HttpMetricsRepository], enviada por un *stream* de iroh.
class IrohMetricsRepository extends AgentMetricsRepository {
  IrohMetricsRepository(
    String Function() endpointId,
    this._token, {
    IrohConnector? connector,
    IrohConnection? connection,
  }) : _connection = connection ?? IrohConnection(endpointId, connector: connector);

  final String? Function() _token;
  final IrohConnection _connection;

  @override
  Future<Map<String, dynamic>> fetch() async {
    final request = buildRawHttpRequest('GET', '/metrics', token: _token());
    final response = parseRawHttpResponse(await _connection.request(request));
    if (response.status == 401) {
      try {
        throwIfSessionError(401, jsonDecode(response.body));
      } on FormatException {
        // Un 401 sin cuerpo de sesión se trata como cualquier otro código.
      }
    }
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
