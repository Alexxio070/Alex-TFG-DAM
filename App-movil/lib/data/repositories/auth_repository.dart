import '../models/auth.dart';

abstract class AuthRepository {
  Future<AgentStatus> status();

  Future<LoginOutcome> login({
    required String usuario,
    required String contrasena,
    required String dispositivo,
  });

  /// Crea la cuenta del agente la primera vez y abre ya la sesión. Lanza
  /// [RegistrationClosedException], [CodeExpiredException],
  /// [InvalidCodeException] o [WeakPasswordException].
  Future<LoggedIn> register({
    required String codigo,
    required String usuario,
    required String contrasena,
    required String dispositivo,
  });

  Future<LoginRequestStatus> checkLoginRequest(String solicitudId);

  /// Comprueba que el token guardado sigue siendo válido, sin pedir la
  /// contraseña. Lanza [NotAuthenticatedException] o [UnpairedException] si
  /// no lo es.
  Future<SessionInfo> session();

  Future<void> logout();

  Future<void> unpair();
}

class InvalidCredentialsException implements Exception {}

class RegistrationClosedException implements Exception {}

class CodeExpiredException implements Exception {}

class InvalidCodeException implements Exception {}

class WeakPasswordException implements Exception {
  WeakPasswordException(this.motivos);

  final List<String> motivos;
}

class TooManyAttemptsException implements Exception {
  TooManyAttemptsException(this.esperaS);

  final int esperaS;
}

class AgentErrorException implements Exception {
  AgentErrorException(this.message);

  final String message;

  @override
  String toString() => message;
}

class NotAuthenticatedException implements Exception {}

class UnpairedException implements Exception {}

/// Lanza [NotAuthenticatedException] o [UnpairedException] si la respuesta es
/// un 401 de sesión del agente; con cualquier otra respuesta no hace nada.
void throwIfSessionError(int status, Object? body) {
  if (status != 401 || body is! Map) return;
  switch (body['error']) {
    case 'no_autenticado':
      throw NotAuthenticatedException();
    case 'desemparejado':
      throw UnpairedException();
  }
}
