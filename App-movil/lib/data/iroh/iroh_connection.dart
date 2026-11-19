// Conexión iroh compartida con el agente y utilidades para mandar HTTP crudo por ella.

import 'dart:convert';

import 'package:iroh_flutter/iroh_flutter.dart';

import '../models/settings.dart';
import '../repositories/metrics_repository.dart' show AgentUnavailableException;

const _alpn = 'sysmote/tunnel/0';
const _connectTimeout = Duration(seconds: 5);
const _fetchTimeout = Duration(seconds: 3);

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

/// Respuesta HTTP cruda ya separada en código de estado y cuerpo.
class RawHttpResponse {
  RawHttpResponse(this.status, this.body);

  final int status;
  final String body;
}

/// Petición HTTP/1.1 cruda, para enviarla por un *stream* de iroh.
String buildRawHttpRequest(String method, String path, {String? body, String? token}) {
  final bytes = body == null ? null : utf8.encode(body);
  return '$method $path HTTP/1.1\r\n'
      'Host: sysmote\r\n'
      '${token == null ? '' : 'Authorization: Bearer $token\r\n'}'
      '${bytes == null ? '' : 'Content-Type: application/json\r\nContent-Length: ${bytes.length}\r\n'}'
      'Connection: close\r\n\r\n'
      '${body ?? ''}';
}

/// Separa una respuesta HTTP cruda o lanza [AgentUnavailableException] si no
/// tiene el formato esperado.
RawHttpResponse parseRawHttpResponse(String text) {
  final headersEnd = text.indexOf('\r\n\r\n');
  final status = RegExp(r'^HTTP/1\.1 (\d{3})').firstMatch(text)?.group(1);
  if (headersEnd == -1 || status == null) {
    throw AgentUnavailableException('El agente respondió con un formato inesperado');
  }
  return RawHttpResponse(int.parse(status), text.substring(headersEnd + 4));
}

/// Una única conexión iroh con el agente, compartida por todos los
/// repositorios que hablan con él (métricas, autenticación...): crear una por
/// repositorio duplicaría el `Endpoint` y las conexiones sin cerrar.
class IrohConnection {
  IrohConnection(this._endpointId, {IrohConnector? connector}) {
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

  /// Envía una petición HTTP cruda y devuelve la respuesta cruda, o lanza
  /// [AgentUnavailableException] si no se puede hablar con el agente.
  Future<String> request(String rawRequest) async {
    final endpointId = _endpointId();
    if (!isValidIrohId(endpointId)) throw AgentUnavailableException(kInvalidIrohIdMessage);

    final IrohLink link;
    try {
      link = await _connect(endpointId);
    } catch (_) {
      throw AgentUnavailableException('No se pudo conectar con el agente por iroh');
    }

    try {
      return await link.exchange(rawRequest).timeout(_fetchTimeout);
    } catch (_) {
      // La conexión puede haber muerto (agente reiniciado, cambio de red). Hay
      // que cerrarla, no solo olvidarla: si no, el Endpoint la sigue viendo
      // activa y la reconexión al mismo agente se queda colgada.
      if (identical(_link, link)) _drop();
      throw AgentUnavailableException('El agente no respondió a tiempo');
    }
  }
}
