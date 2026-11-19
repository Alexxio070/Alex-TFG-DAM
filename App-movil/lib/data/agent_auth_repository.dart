import 'models/auth.dart';
import 'repositories/auth_repository.dart';
import 'repositories/metrics_repository.dart' show AgentUnavailableException, kUnexpectedFormatMessage;
import 'repositories/token_storage.dart';

class AgentResponse {
  AgentResponse(this.status, this.body);

  final int status;
  final Map<String, dynamic> body;
}

/// Parte común de los repositorios de autenticación del agente: cada uno
/// solo decide cómo enviar la petición ([send]), por HTTPS o por iroh, y esta
/// clase traduce las respuestas del contrato de la fase 3 a los modelos y
/// excepciones de la app.
abstract class AgentAuthRepository implements AuthRepository {
  AgentAuthRepository(this._tokenStorage);

  final TokenStorage _tokenStorage;

  /// Devuelve la respuesta del agente o lanza [AgentUnavailableException]
  /// si no se puede hablar con él.
  Future<AgentResponse> send(
    String method,
    String path, {
    Map<String, Object?>? body,
    String? token,
  });

  Future<AgentResponse> _sendWithToken(String method, String path) async =>
      send(method, path, token: await _tokenStorage.read());

  @override
  Future<AgentStatus> status() => _parsed(() async {
    final response = await send('GET', '/estado');
    _expect(response, 200);
    final json = response.body;
    return AgentStatus(
      api: json['api'] as int,
      configurado: json['configurado'] as bool,
      registroAbierto: json['registro_abierto'] as bool,
      sesionActiva: json['sesion_activa'] as bool,
    );
  });

  @override
  Future<LoginOutcome> login({
    required String usuario,
    required String contrasena,
    required String dispositivo,
  }) => _parsed(() async {
    final response = await send(
      'POST',
      '/login',
      body: {'usuario': usuario, 'contrasena': contrasena, 'dispositivo': dispositivo},
    );
    if (response.status == 202) {
      final json = response.body;
      return LoginPending(
        solicitudId: json['solicitud'] as String,
        sesionActivaEn: json['sesion_activa_en'] as String,
        caducaEnS: json['caduca_en_s'] as int,
      );
    }
    _expect(response, 200);
    return _loggedIn(response.body);
  });

  @override
  Future<LoggedIn> register({
    required String codigo,
    required String usuario,
    required String contrasena,
    required String dispositivo,
  }) => _parsed(() async {
    final response = await send(
      'POST',
      '/registro',
      body: {
        'codigo': codigo,
        'usuario': usuario,
        'contrasena': contrasena,
        'dispositivo': dispositivo,
      },
    );
    _expect(response, 201);
    return _loggedIn(response.body);
  });

  @override
  Future<LoginRequestStatus> checkLoginRequest(String solicitudId) => _parsed(() async {
    final response = await send('GET', '/login/solicitud/$solicitudId');
    _expect(response, 200);
    final json = response.body;
    return switch (json['estado']) {
      'pendiente' => const LoginRequestPending(),
      'aprobada' => LoginRequestApproved(
          token: json['token'] as String,
          usuario: json['usuario'] as String,
        ),
      'rechazada' => const LoginRequestRejected(),
      'caducada' => const LoginRequestExpired(),
      _ => throw AgentErrorException('Estado de solicitud desconocido'),
    };
  });

  @override
  Future<SessionInfo> session() => _parsed(() async {
    final response = await _sendWithToken('GET', '/sesion');
    _expect(response, 200);
    final json = response.body;
    return SessionInfo(
      usuario: json['usuario'] as String,
      dispositivo: json['dispositivo'] as String,
      creada: DateTime.parse(json['creada'] as String),
    );
  });

  @override
  Future<void> logout() async => _expect(await _sendWithToken('POST', '/logout'), 204);

  @override
  Future<void> unpair() async => _expect(await _sendWithToken('POST', '/desemparejar'), 204);

  Future<T> _parsed<T>(Future<T> Function() parse) async {
    try {
      return await parse();
    } on TypeError {
      throw AgentUnavailableException(kUnexpectedFormatMessage);
    } on FormatException {
      throw AgentUnavailableException(kUnexpectedFormatMessage);
    }
  }

  LoggedIn _loggedIn(Map<String, dynamic> json) =>
      LoggedIn(token: json['token'] as String, usuario: json['usuario'] as String);

  void _expect(AgentResponse response, int status) {
    if (response.status == status) return;
    throwIfSessionError(response.status, response.body);
    final error = response.body['error'];
    final mensaje = response.body['mensaje'] as String?;
    switch ((response.status, error)) {
      case (401, 'credenciales_invalidas'):
        throw InvalidCredentialsException();
      case (403, 'registro_cerrado'):
        throw RegistrationClosedException();
      case (403, 'codigo_caducado'):
        throw CodeExpiredException();
      case (403, 'codigo_invalido'):
        throw InvalidCodeException();
      case (422, 'contrasena_debil'):
        throw WeakPasswordException([
          for (final motivo in response.body['motivos'] as List? ?? const []) motivo as String,
        ]);
      case (429, 'demasiados_intentos'):
        throw TooManyAttemptsException(response.body['espera_s'] as int);
    }
    throw AgentErrorException(mensaje ?? 'El agente respondió con el código ${response.status}');
  }
}
