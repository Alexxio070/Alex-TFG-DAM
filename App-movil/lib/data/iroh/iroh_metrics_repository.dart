import 'dart:convert';

import 'package:iroh_flutter/iroh_flutter.dart';

import '../agent_metrics_repository.dart';
import '../repositories/metrics_repository.dart';

const _alpn = 'sysmote/tunnel/0';
const _connectTimeout = Duration(seconds: 5);
const _fetchTimeout = Duration(seconds: 3);

/// Pide `/metrics` al agente a través de un túnel iroh: la misma petición
/// HTTP que [HttpMetricsRepository], enviada por un *stream* de iroh.
class IrohMetricsRepository extends AgentMetricsRepository {
  IrohMetricsRepository(this._endpointId);

  final String Function() _endpointId;
  Endpoint? _endpoint;
  Connection? _connection;

  // Un solo Endpoint para todas las conexiones: crear uno por reconexión
  // los iba dejando sin cerrar.
  Future<Connection> _connect() async {
    if (_connection case final connection?) return connection;
    await Iroh.init();
    final endpoint = _endpoint ??= await Endpoint.bind(alpns: [utf8.encode(_alpn)]);
    final addr = EndpointAddr(PublicKey.fromHex(_endpointId()));
    return _connection = await endpoint.connect(addr, utf8.encode(_alpn)).timeout(_connectTimeout);
  }

  Future<String> _exchange(Connection connection) async {
    final (send, recv) = await connection.openBi();
    await send.writeAll(
      utf8.encode('GET /metrics HTTP/1.1\r\nHost: sysmote\r\nConnection: close\r\n\r\n'),
    );
    await send.finish();
    return utf8.decode(await recv.readToEnd(1000000));
  }

  @override
  Future<Map<String, dynamic>> fetch() async {
    final Connection connection;
    try {
      connection = await _connect();
    } catch (_) {
      throw AgentUnavailableException('No se pudo conectar con el agente por iroh');
    }

    final String text;
    try {
      text = await _exchange(connection).timeout(_fetchTimeout);
    } catch (_) {
      // La conexión puede haber muerto (agente reiniciado, cambio de red). Hay
      // que cerrarla, no solo olvidarla: si no, el Endpoint la sigue viendo
      // activa y la reconexión al mismo agente se queda colgada.
      _connection = null;
      connection.close();
      throw AgentUnavailableException('El agente no respondió a tiempo');
    }

    final headersEnd = text.indexOf('\r\n\r\n');
    if (headersEnd == -1 || !text.startsWith('HTTP/1.1 200')) {
      throw AgentUnavailableException('El agente respondió con un formato inesperado');
    }
    try {
      return jsonDecode(text.substring(headersEnd + 4)) as Map<String, dynamic>;
    } on FormatException {
      throw AgentUnavailableException('Respuesta del agente con formato inesperado');
    }
  }
}
