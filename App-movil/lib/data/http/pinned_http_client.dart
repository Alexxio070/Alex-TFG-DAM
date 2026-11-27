// Cliente HTTPS con certificate pinning y envío común de peticiones al agente.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../repositories/agent_exceptions.dart';

const _timeout = Duration(seconds: 3);

/// Mensaje que se muestra cuando el certificado del agente no coincide con la huella guardada.
const kFingerprintMismatchMessage =
    'El certificado del agente no coincide con la huella guardada. Compárala con la de la TUI';

/// Huella de un certificado: SHA-256 de su DER en hexadecimal minúscula.
String certificateFingerprint(Uint8List der) => sha256.convert(der).toString();

/// Indica si el certificado [der] tiene la huella [expected], sin distinguir mayúsculas ni espacios
/// alrededor.
bool fingerprintMatches(Uint8List der, String expected) =>
    expected.isNotEmpty && certificateFingerprint(der) == expected.trim().toLowerCase();

/// Cliente HTTPS que solo confía en el certificado cuya huella devuelve
/// [fingerprint]. El contexto vacío no trae ninguna CA: todos los
/// certificados, también los que firmaría una CA pública, llegan al
/// callback y se comparan con la huella; si no coincide, se rechaza.
http.Client buildPinnedHttpClient(String Function() fingerprint) {
  final inner = HttpClient(context: SecurityContext())
    ..badCertificateCallback = (certificate, host, port) =>
        fingerprintMatches(certificate.der, fingerprint());
  return IOClient(inner);
}

/// Envía [request] al agente con un límite de 3 s para toda la respuesta y
/// traduce cualquier fallo de red a [AgentUnavailableException].
Future<http.Response> sendToAgent(http.Client client, http.BaseRequest request) async {
  try {
    return await client.send(request).then(http.Response.fromStream).timeout(_timeout);
  } on TimeoutException {
    throw AgentUnavailableException(
      'El agente no respondió a tiempo',
      cause: AgentUnavailableCause.timeout,
    );
  } on HandshakeException {
    throw AgentUnavailableException(
      kFingerprintMismatchMessage,
      cause: AgentUnavailableCause.fingerprint,
    );
  } catch (_) {
    throw AgentUnavailableException(
      'No se pudo conectar con el agente',
      cause: AgentUnavailableCause.unreachable,
    );
  }
}
