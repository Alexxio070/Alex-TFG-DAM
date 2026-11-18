import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../agent_metrics_repository.dart';
import '../repositories/auth_repository.dart';
import '../repositories/metrics_repository.dart';
import 'pinned_http_client.dart';

/// Pide `/metrics` al agente por HTTPS (USB o red local), con la huella del
/// certificado fijada y el token de sesión como `Bearer`.
class HttpMetricsRepository extends AgentMetricsRepository {
  HttpMetricsRepository(this.address, this.fingerprint, this.token, {http.Client? client})
      : _client = client ?? buildPinnedHttpClient(fingerprint);

  final String Function() address;
  final String Function() fingerprint;
  final String? Function() token;
  final http.Client _client;

  @override
  Future<Map<String, dynamic>> fetch() async {
    http.Response response;
    try {
      final bearer = token();
      response = await _client
          .get(
            Uri.parse('https://${address()}/metrics'),
            headers: {if (bearer != null) 'Authorization': 'Bearer $bearer'},
          )
          .timeout(const Duration(seconds: 3));
    } on TimeoutException {
      throw AgentUnavailableException('El agente no respondió a tiempo');
    } on HandshakeException {
      throw AgentUnavailableException(kFingerprintMismatchMessage);
    } catch (_) {
      throw AgentUnavailableException('No se pudo conectar con el agente');
    }
    final Object? decoded;
    try {
      decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    } on FormatException {
      if (response.statusCode != 200) {
        throw AgentUnavailableException('El agente respondió con el código ${response.statusCode}');
      }
      throw AgentUnavailableException('Respuesta del agente con formato inesperado');
    }
    throwIfSessionError(response.statusCode, decoded);
    if (response.statusCode != 200) {
      throw AgentUnavailableException('El agente respondió con el código ${response.statusCode}');
    }
    if (decoded is! Map<String, dynamic>) {
      throw AgentUnavailableException('Respuesta del agente con formato inesperado');
    }
    return decoded;
  }
}
