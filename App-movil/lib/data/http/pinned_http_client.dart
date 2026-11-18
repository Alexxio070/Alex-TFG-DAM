import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

const kFingerprintMismatchMessage =
    'El certificado del agente no coincide con la huella guardada. Compárala con la de la TUI';

/// Huella de un certificado: SHA-256 de su DER en hexadecimal minúscula.
String certificateFingerprint(Uint8List der) => sha256.convert(der).toString();

bool fingerprintMatches(Uint8List der, String expected) =>
    expected.isNotEmpty && certificateFingerprint(der) == expected.trim().toLowerCase();

/// Cliente HTTPS que solo confía en el certificado cuya huella devuelve
/// [fingerprint]. El contexto vacío no trae ninguna CA: todos los
/// certificados, también los que firmaría una CA pública, llegan al
/// callback y se comparan con la huella; si no coincide, se rechaza.
http.Client buildPinnedHttpClient(String Function() fingerprint) {
  final inner = HttpClient(context: SecurityContext())
    ..badCertificateCallback =
        (certificate, host, port) => fingerprintMatches(certificate.der, fingerprint());
  return IOClient(inner);
}
