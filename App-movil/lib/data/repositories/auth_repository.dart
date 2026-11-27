// Interfaz de autenticación con el agente y las excepciones de su contrato.

import '../models/auth.dart';

/// Login, registro y sesión con el agente.
abstract class AuthRepository {
  /// Pregunta al agente si tiene cuenta, si el registro está abierto y si hay sesión activa.
  Future<AgentStatus> status();

  /// Inicia sesión. Lanza [InvalidCredentialsException] o [TooManyAttemptsException].
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

  /// Consulta cómo va una solicitud de login pendiente.
  Future<LoginRequestStatus> checkLoginRequest(String solicitudId);

  /// Comprueba que el token guardado sigue siendo válido, sin pedir la
  /// contraseña. Lanza [NotAuthenticatedException], [SessionExpiredException]
  /// o [UnpairedException] si no lo es.
  Future<SessionInfo> session();

  /// Cierra la sesión en el agente.
  Future<void> logout();

  /// Desempareja este móvil del agente.
  Future<void> unpair();
}

/// Usuario o contraseña incorrectos.
class InvalidCredentialsException implements Exception {}

/// El agente no tiene el registro abierto.
class RegistrationClosedException implements Exception {}

/// El código de registro ha caducado.
class CodeExpiredException implements Exception {}

/// El código de registro no es el que muestra la TUI.
class InvalidCodeException implements Exception {}

/// La contraseña no cumple los requisitos; [motivos] dice cuáles.
class WeakPasswordException implements Exception {
  WeakPasswordException(this.motivos);

  final List<String> motivos;
}

/// Demasiados intentos fallidos: hay que esperar [esperaS] segundos.
class TooManyAttemptsException implements Exception {
  TooManyAttemptsException(this.esperaS);

  final int esperaS;
}

/// Error del agente que no tiene una excepción propia, con su mensaje.
class AgentErrorException implements Exception {
  AgentErrorException(this.message);

  final String message;

  @override
  String toString() => message;
}
