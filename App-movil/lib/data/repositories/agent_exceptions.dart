// Errores comunes al hablar con el agente, sea cual sea el repositorio: agente inalcanzable y
// sesión perdida (401).

/// Mensaje para una respuesta del agente que no se puede interpretar.
const kUnexpectedFormatMessage = 'Respuesta del agente con formato inesperado';

/// Por qué no se puede hablar con el agente.
enum AgentUnavailableCause { timeout, unreachable, fingerprint, invalidIrohId, unexpected }

/// No se puede hablar con el agente (red, timeout, huella o respuesta ilegible).
class AgentUnavailableException implements Exception {
  AgentUnavailableException(this.message, {this.cause = AgentUnavailableCause.unexpected});

  final String message;
  final AgentUnavailableCause cause;

  @override
  String toString() => message;
}

/// El token ya no vale (401 `no_autenticado`): hay que volver a iniciar sesión.
class NotAuthenticatedException implements Exception {}

/// El token ha pasado sus 7 días (401 `sesion_caducada`): hay que volver a iniciar sesión.
class SessionExpiredException implements Exception {}

/// El agente ya no reconoce este móvil (401 `desemparejado`).
class UnpairedException implements Exception {}

/// Lanza [NotAuthenticatedException], [SessionExpiredException] o [UnpairedException]
/// si la respuesta es un 401 de sesión del agente; con cualquier otra respuesta no hace nada.
void throwIfSessionError(int status, Object? body) {
  if (status != 401 || body is! Map) return;
  switch (body['error']) {
    case 'no_autenticado':
      throw NotAuthenticatedException();
    case 'sesion_caducada':
      throw SessionExpiredException();
    case 'desemparejado':
      throw UnpairedException();
  }
}
