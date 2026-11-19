// Modelos del contrato de login, registro y sesión con el agente (fase 3).

/// Respuesta de `/estado`: si el agente ya tiene cuenta, si el registro está abierto y si hay una
/// sesión activa en otro dispositivo. [api] es la versión del contrato; se lee para validar la
/// respuesta.
class AgentStatus {
  const AgentStatus({
    required this.api,
    required this.configurado,
    required this.registroAbierto,
    required this.sesionActiva,
  });

  final int api;
  final bool configurado;
  final bool registroAbierto;
  final bool sesionActiva;
}

/// Resultado de un login: sesión abierta ([LoggedIn]) o pendiente de confirmar en la TUI
/// ([LoginPending]).
sealed class LoginOutcome {}

/// Login aceptado: el token de la nueva sesión.
class LoggedIn extends LoginOutcome {
  LoggedIn({required this.token, required this.usuario});

  final String token;
  final String usuario;
}

/// Ya había una sesión activa: el login espera a que se confirme en la TUI antes de [caducaEnS]
/// segundos.
class LoginPending extends LoginOutcome {
  LoginPending({required this.solicitudId, required this.sesionActivaEn, required this.caducaEnS});

  final String solicitudId;
  final String sesionActivaEn;
  final int caducaEnS;
}

/// Estado de una solicitud de login pendiente.
sealed class LoginRequestStatus {
  const LoginRequestStatus();
}

/// Todavía nadie la ha confirmado ni rechazado.
class LoginRequestPending extends LoginRequestStatus {
  const LoginRequestPending();
}

/// Se aprobó en la TUI: trae el token de la nueva sesión.
class LoginRequestApproved extends LoginRequestStatus {
  const LoginRequestApproved({required this.token, required this.usuario});

  final String token;
  final String usuario;
}

/// Se rechazó en la TUI y se mantuvo la sesión anterior.
class LoginRequestRejected extends LoginRequestStatus {
  const LoginRequestRejected();
}

/// Nadie la confirmó a tiempo.
class LoginRequestExpired extends LoginRequestStatus {
  const LoginRequestExpired();
}

/// Respuesta de `/sesion`. Solo se usa para comprobar que el token sigue valiendo; los campos se
/// leen para validar la respuesta.
class SessionInfo {
  const SessionInfo({required this.usuario, required this.dispositivo, required this.creada});

  final String usuario;
  final String dispositivo;
  final DateTime creada;
}
