import 'dart:convert';

import 'package:iroh_flutter/iroh_flutter.dart';

import '../agent_metrics_repository.dart';
import '../models/settings.dart';
import '../repositories/metrics_repository.dart';

const _alpn = 'sysmote/tunnel/0';
const _connectTimeout = Duration(seconds: 5);
const _fetchTimeout = Duration(seconds: 3);
const _request = 'GET /metrics HTTP/1.1\r\nHost: sysmote\r\nConnection: close\r\n\r\n';

/// Conexión abierta con un agente: lo único que el repositorio necesita de ella.
abstract class IrohLink {
  /// Envía una petición HTTP cruda por un *stream* nuevo y devuelve la respuesta.
  Future<String> exchange(String request);

  void close();
}

typedef IrohConnector = Future<IrohLink> Function(String endpointId);

class _NativeIrohLink implements IrohLink {
  _NativeIrohLink(this._connection);

  final Connection _connection;

  @override
  Future<String> exchange(String request) async {
    final (send, recv) = await _connection.openBi();
    await send.writeAll(utf8.encode(request));
    await send.finish();
    return utf8.decode(await recv.readToEnd(1000000));
  }

  @override
  void close() => _connection.close();
}

/// Pide `/metrics` al agente a través de un túnel iroh: la misma petición
/// HTTP que [HttpMetricsRepository], enviada por un *stream* de iroh.
class IrohMetricsRepository extends AgentMetricsRepository {
  IrohMetricsRepository(this._endpointId, {IrohConnector? connector}) {
    _connector = connector ?? _connectNative;
  }

  final String Function() _endpointId;
  late final IrohConnector _connector;
  Endpoint? _endpoint;
  IrohLink? _link;
  String? _linkId;
  Future<IrohLink>? _attempt;
  String? _attemptId;
  Object? _attemptToken;

  // Un solo Endpoint para todas las conexiones: crear uno por reconexión
  // los iba dejando sin cerrar.
  Future<IrohLink> _connectNative(String endpointId) async {
    await Iroh.init();
    final endpoint = _endpoint ??= await Endpoint.bind(alpns: [utf8.encode(_alpn)]);
    final addr = EndpointAddr(PublicKey.fromHex(endpointId));
    return _NativeIrohLink(await endpoint.connect(addr, utf8.encode(_alpn)));
  }

  // El intento de conexión nativo no se puede cancelar: si pasa de
  // [_connectTimeout], sigue vivo por debajo. Por eso solo hay uno a la vez: las
  // peticiones que llegan mientras sigue en marcha lo esperan, cada una con su
  // propio límite, en vez de lanzar otro; y si acaba conectando tarde, la
  // conexión se aprovecha. Si el identificador de Ajustes cambió, la conexión
  // abierta es de otro agente: se cierra y se abre una nueva.
  Future<IrohLink> _connect(String endpointId) {
    if (_link != null && _linkId != endpointId) _drop();
    if (_link case final link?) return Future.value(link);
    if (_attemptId != endpointId) _attempt = _open(endpointId);
    return _attempt!.timeout(_connectTimeout);
  }

  Future<IrohLink> _open(String endpointId) async {
    final token = _attemptToken = Object();
    _attemptId = endpointId;
    try {
      final link = await _connector(endpointId);
      if (!identical(_attemptToken, token)) {
        // Otro identificador lo sustituyó mientras conectaba: nadie lo necesita.
        link.close();
        throw StateError('Intento de conexión sustituido por otro identificador');
      }
      _link = link;
      _linkId = endpointId;
      return link;
    } finally {
      if (identical(_attemptToken, token)) {
        _attempt = null;
        _attemptId = null;
        _attemptToken = null;
      }
    }
  }

  void _drop() {
    _link?.close();
    _link = null;
    _linkId = null;
  }

  @override
  Future<Map<String, dynamic>> fetch() async {
    final endpointId = _endpointId();
    if (!isValidIrohId(endpointId)) throw AgentUnavailableException(kInvalidIrohIdMessage);

    final IrohLink link;
    try {
      link = await _connect(endpointId);
    } catch (_) {
      throw AgentUnavailableException('No se pudo conectar con el agente por iroh');
    }

    final String text;
    try {
      text = await link.exchange(_request).timeout(_fetchTimeout);
    } catch (_) {
      // La conexión puede haber muerto (agente reiniciado, cambio de red). Hay
      // que cerrarla, no solo olvidarla: si no, el Endpoint la sigue viendo
      // activa y la reconexión al mismo agente se queda colgada.
      if (identical(_link, link)) _drop();
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
