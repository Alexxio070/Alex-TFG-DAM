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

sealed class LoginOutcome {}

class LoggedIn extends LoginOutcome {
  LoggedIn({required this.token, required this.usuario});

  final String token;
  final String usuario;
}

class LoginPending extends LoginOutcome {
  LoginPending({required this.solicitudId, required this.sesionActivaEn, required this.caducaEnS});

  final String solicitudId;
  final String sesionActivaEn;
  final int caducaEnS;
}

sealed class LoginRequestStatus {
  const LoginRequestStatus();
}

class LoginRequestPending extends LoginRequestStatus {
  const LoginRequestPending();
}

class LoginRequestApproved extends LoginRequestStatus {
  const LoginRequestApproved({required this.token, required this.usuario});

  final String token;
  final String usuario;
}

class LoginRequestRejected extends LoginRequestStatus {
  const LoginRequestRejected();
}

class LoginRequestExpired extends LoginRequestStatus {
  const LoginRequestExpired();
}

class SessionInfo {
  const SessionInfo({required this.usuario, required this.dispositivo, required this.creada});

  final String usuario;
  final String dispositivo;
  final DateTime creada;
}
