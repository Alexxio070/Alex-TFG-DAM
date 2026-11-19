// Doble de pruebas del agente para el login: simula el contrato de la fase 3 en memoria.

import 'package:sysmote/data/models/auth.dart';
import 'package:sysmote/data/repositories/agent_exceptions.dart';
import 'package:sysmote/data/repositories/auth_repository.dart';

/// Agente simulado con credenciales, código de registro, límite de intentos y solicitudes
/// pendientes configurables.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.configurado = true,
    this.registroAbierto = false,
    this.usuarioValido = 'alex',
    this.contrasenaValida = 'contraseña-valida',
    this.codigoRegistro,
    this.codigoCaducado = false,
    this.intentosPermitidos = 5,
    this.bloqueoS = 600,
  });

  /// Con una sesión ya abierta, para los sitios que todavía no prueban el
  /// login en sí y solo necesitan la app como si ya hubiera iniciado sesión.
  factory FakeAuthRepository.loggedIn({String dispositivo = 'Pixel 8'}) {
    final repo = FakeAuthRepository()
      .._token = 'token-fake'
      .._dispositivo = dispositivo;
    return repo;
  }

  bool configurado;
  bool registroAbierto;
  String usuarioValido;
  String contrasenaValida;

  /// Código de registro guardado por el agente, sin guiones y en mayúsculas.
  /// Si es null, nunca se abrió el registro.
  String? codigoRegistro;
  bool codigoCaducado;

  /// Si no es null, el próximo login() con credenciales válidas crea una
  /// solicitud pendiente en vez de abrir sesión directamente, como si ya
  /// hubiera una sesión activa en el dispositivo indicado.
  String? sesionActivaEnDispositivo;

  /// Si no es null, login() lanza esta excepción en vez de comprobar nada.
  TooManyAttemptsException? bloqueadoPor;

  /// Fallos seguidos que el agente deja pasar con 401: el último permitido
  /// todavía da 401 y el siguiente intento ya recibe 429 durante [bloqueoS].
  int intentosPermitidos;
  int bloqueoS;

  int _fallos = 0;
  bool _bloqueado = false;

  /// Simula que ha pasado el tiempo de bloqueo.
  void levantarBloqueo() {
    _bloqueado = false;
    _fallos = 0;
  }

  int logoutCalls = 0;
  int unpairCalls = 0;

  String? _token;
  String? _dispositivo;
  _Pending? _pending;

  @override
  Future<AgentStatus> status() async => AgentStatus(
    api: 1,
    configurado: configurado,
    registroAbierto: registroAbierto,
    sesionActiva: sesionActivaEnDispositivo != null || _token != null,
  );

  @override
  Future<LoginOutcome> login({
    required String usuario,
    required String contrasena,
    required String dispositivo,
  }) async {
    if (bloqueadoPor case final e?) throw e;
    if (_bloqueado) throw TooManyAttemptsException(bloqueoS);
    if (usuario != usuarioValido || contrasena != contrasenaValida) {
      _fallos++;
      if (_fallos >= intentosPermitidos) _bloqueado = true;
      throw InvalidCredentialsException();
    }
    _fallos = 0;
    if (sesionActivaEnDispositivo case final otroDispositivo?) {
      _pending = _Pending(usuario: usuario, dispositivo: dispositivo);
      return LoginPending(
        solicitudId: 'solicitud-fake',
        sesionActivaEn: otroDispositivo,
        caducaEnS: 300,
      );
    }
    _token = 'token-fake';
    _dispositivo = dispositivo;
    return LoggedIn(token: _token!, usuario: usuario);
  }

  @override
  Future<LoggedIn> register({
    required String codigo,
    required String usuario,
    required String contrasena,
    required String dispositivo,
  }) async {
    if (configurado) throw RegistrationClosedException();
    final guardado = codigoRegistro;
    if (_normalizar(codigo) == guardado && guardado != null) {
      if (codigoCaducado) throw CodeExpiredException();
    } else {
      throw guardado == null ? RegistrationClosedException() : InvalidCodeException();
    }
    final motivos = [
      if (contrasena.length < 5) 'Mínimo 5 caracteres',
      if (!contrasena.contains(RegExp(r'\d'))) 'Debe tener un número',
      if (!contrasena.contains(RegExp(r'[A-Z]'))) 'Debe tener una mayúscula',
    ];
    if (motivos.isNotEmpty) throw WeakPasswordException(motivos);
    configurado = true;
    registroAbierto = false;
    usuarioValido = usuario;
    contrasenaValida = contrasena;
    _token = 'token-fake';
    _dispositivo = dispositivo;
    return LoggedIn(token: _token!, usuario: usuario);
  }

  String _normalizar(String codigo) =>
      codigo.replaceAll('-', '').toUpperCase().replaceAll('O', '0').replaceAll('I', '1');

  @override
  Future<LoginRequestStatus> checkLoginRequest(String solicitudId) async {
    final pending = _pending;
    if (pending == null || solicitudId != 'solicitud-fake') {
      throw AgentErrorException('solicitud_desconocida');
    }
    return pending.resolution ?? const LoginRequestPending();
  }

  /// Simula que en la TUI se acepta sobrescribir la sesión anterior.
  void approvePending() {
    final pending = _pending!;
    _token = 'token-fake';
    _dispositivo = pending.dispositivo;
    sesionActivaEnDispositivo = null;
    pending.resolution = LoginRequestApproved(token: _token!, usuario: pending.usuario);
  }

  /// Simula que en la TUI se rechaza la solicitud.
  void rejectPending() => _pending!.resolution = const LoginRequestRejected();

  /// Simula que nadie decide en la TUI y pasan los 5 minutos.
  void expirePending() => _pending!.resolution = const LoginRequestExpired();

  @override
  Future<SessionInfo> session() async {
    final token = _token;
    if (token == null) throw NotAuthenticatedException();
    return SessionInfo(usuario: usuarioValido, dispositivo: _dispositivo!, creada: DateTime.now());
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
    _token = null;
    _dispositivo = null;
  }

  @override
  Future<void> unpair() async {
    unpairCalls++;
    _token = null;
    _dispositivo = null;
  }
}

class _Pending {
  _Pending({required this.usuario, required this.dispositivo});

  final String usuario;
  final String dispositivo;
  LoginRequestStatus? resolution;
}
