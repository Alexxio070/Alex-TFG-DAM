import 'dart:convert';

import 'package:http/http.dart' as http;

import '../agent_auth_repository.dart';
import '../repositories/metrics_repository.dart' show AgentUnavailableException, kUnexpectedFormatMessage;
import '../repositories/token_storage.dart';
import 'pinned_http_client.dart';

/// Habla con el agente por HTTPS (USB o red local), con la huella del
/// certificado fijada: si no coincide con la guardada en Ajustes, la conexión
/// se rechaza sin alternativa.
class HttpAuthRepository extends AgentAuthRepository {
  HttpAuthRepository(
    this.address,
    this.fingerprint,
    TokenStorage tokenStorage, {
    http.Client? client,
  })  : _client = client ?? buildPinnedHttpClient(fingerprint),
        super(tokenStorage);

  final String Function() address;
  final String Function() fingerprint;
  final http.Client _client;

  @override
  Future<AgentResponse> send(
    String method,
    String path, {
    Map<String, Object?>? body,
    String? token,
  }) async {
    final request = http.Request(method, Uri.parse('https://${address()}$path'));
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.body = jsonEncode(body);
    }
    final response = await sendToAgent(_client, request);
    return AgentResponse(response.statusCode, _json(response));
  }

  Map<String, dynamic> _json(http.Response response) {
    if (response.bodyBytes.isEmpty) return const {};
    try {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } on FormatException {
      throw AgentUnavailableException(kUnexpectedFormatMessage);
    } on TypeError {
      throw AgentUnavailableException(kUnexpectedFormatMessage);
    }
  }
}
