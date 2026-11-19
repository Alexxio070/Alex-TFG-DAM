// Autenticación contra el agente por un túnel iroh, con HTTP crudo sobre la conexión.

import 'dart:convert';

import '../agent_auth_repository.dart';
import '../repositories/metrics_repository.dart' show AgentUnavailableException, kUnexpectedFormatMessage;
import '../repositories/token_storage.dart';
import 'iroh_connection.dart';

/// Habla con el agente a través de un túnel iroh. Sin TLS propio: la
/// conexión de iroh ya va cifrada y autentica al agente por su identificador.
class IrohAuthRepository extends AgentAuthRepository {
  IrohAuthRepository(this._connection, TokenStorage tokenStorage) : super(tokenStorage);

  final IrohConnection _connection;

  @override
  Future<AgentResponse> send(
    String method,
    String path, {
    Map<String, Object?>? body,
    String? token,
  }) async {
    final raw = buildRawHttpRequest(
      method,
      path,
      body: body == null ? null : jsonEncode(body),
      token: token,
    );
    final response = parseRawHttpResponse(await _connection.request(raw));
    if (response.body.isEmpty) return AgentResponse(response.status, const {});
    try {
      return AgentResponse(
        response.status,
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } on FormatException {
      throw AgentUnavailableException(kUnexpectedFormatMessage);
    } on TypeError {
      throw AgentUnavailableException(kUnexpectedFormatMessage);
    }
  }
}
