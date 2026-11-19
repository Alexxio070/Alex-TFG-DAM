// ViewModel del login: única fuente de verdad sobre si hay sesión con el agente y dueño del token.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/auth.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/agent_exceptions.dart';
import '../../data/repositories/token_storage.dart';

/// En qué punto está el login; [LoginView] muestra una pantalla distinta para cada uno.
enum AuthStage {
  loading,
  unreachable,
  noAccount,
  needsRegistration,
  registering,
  needsLogin,
  submitting,
  blocked,
  pendingConfirmation,
  loggedIn,
}

/// Comprueba el agente al arrancar, registra la cuenta, inicia y cierra sesión, espera la
/// confirmación en la TUI cuando ya hay otra sesión y guarda el token en el móvil y en memoria.
class AuthViewModel extends ChangeNotifier {
  AuthViewModel(
    this._repository,
    this._tokenStorage, {
    this.pollInterval = const Duration(seconds: 2),
    this.onForgetDevice,
  }) {
    start();
  }

  final AuthRepository _repository;
  final TokenStorage _tokenStorage;
  final Duration pollInterval;

  /// Borra lo que la app sabe del equipo (dirección, huella, identificador
  /// iroh) cuando se desempareja o el agente avisa de que ya no está emparejado.
  final Future<void> Function()? onForgetDevice;

  String? _token;
  AuthStage _stage = AuthStage.loading;
  bool _sesionActivaAviso = false;
  String? _error;
  String? _pendingSolicitudId;
  String? _pendingSesionActivaEn;
  int _pendingSecondsLeft = 0;
  int _blockedSecondsLeft = 0;
  Timer? _pollTimer;
  Timer? _countdownTimer;

  String? get token => _token;
  AuthStage get stage => _stage;
  bool get sesionActivaAviso => _sesionActivaAviso;
  String? get error => _error;
  String? get pendingSesionActivaEn => _pendingSesionActivaEn;
  int get pendingSecondsLeft => _pendingSecondsLeft;
  int get blockedSecondsLeft => _blockedSecondsLeft;

  /// Entra con el token guardado si el agente lo acepta; si no, pregunta al agente en qué estado
  /// está para mostrar el formulario que toque.
  Future<void> start() async {
    _stage = AuthStage.loading;
    notifyListeners();
    final token = await _tokenStorage.read();
    if (token != null) {
      try {
        await _repository.session();
        _token = token;
        _stage = AuthStage.loggedIn;
        notifyListeners();
        return;
      } on NotAuthenticatedException {
        await _tokenStorage.clear();
      } on UnpairedException {
        await _forgetDevice();
      } on AgentUnavailableException catch (e) {
        _unreachable(e);
        return;
      }
    }
    await _checkStatus();
  }

  /// Vuelve a comprobar el agente tras fallar la conexión o cambiar la
  /// dirección, la huella o el identificador en Ajustes.
  Future<void> retry() => start();

  void _unreachable(AgentUnavailableException e) {
    _error = e.message;
    _stage = AuthStage.unreachable;
    notifyListeners();
  }

  Future<void> _checkStatus() async {
    final AgentStatus status;
    try {
      status = await _repository.status();
    } on AgentUnavailableException catch (e) {
      _unreachable(e);
      return;
    }
    _sesionActivaAviso = status.sesionActiva;
    _stage = status.configurado
        ? AuthStage.needsLogin
        : status.registroAbierto
            ? AuthStage.needsRegistration
            : AuthStage.noAccount;
    notifyListeners();
  }

  /// Crea la cuenta con el código de registro de la TUI y entra en sesión.
  Future<void> register({
    required String codigo,
    required String usuario,
    required String contrasena,
    required String dispositivo,
  }) async {
    _stage = AuthStage.registering;
    _error = null;
    notifyListeners();
    try {
      final session = await _repository.register(
        codigo: codigo,
        usuario: usuario,
        contrasena: contrasena,
        dispositivo: dispositivo,
      );
      await _enterSession(session.token);
      return;
    } on RegistrationClosedException {
      _error = 'El registro no está abierto. Pulsa configuración inicial en la TUI.';
    } on CodeExpiredException {
      _error = 'El código de registro ha caducado. '
          'Pulsa configuración inicial en la TUI para generar otro.';
    } on InvalidCodeException {
      _error = 'El código de registro no es válido';
    } on WeakPasswordException catch (e) {
      _error = 'Contraseña débil: ${e.motivos.join(', ')}';
    } on AgentUnavailableException catch (e) {
      _error = e.message;
    } on AgentErrorException catch (e) {
      _error = e.message;
    }
    _stage = AuthStage.needsRegistration;
    notifyListeners();
  }

  /// Inicia sesión; si ya hay una sesión activa en otro dispositivo, pasa a esperar la confirmación
  /// en la TUI.
  Future<void> submit({
    required String usuario,
    required String contrasena,
    required String dispositivo,
  }) async {
    _stage = AuthStage.submitting;
    _error = null;
    notifyListeners();
    try {
      final outcome = await _repository.login(
        usuario: usuario,
        contrasena: contrasena,
        dispositivo: dispositivo,
      );
      switch (outcome) {
        case LoggedIn(:final token):
          await _enterSession(token);
        case LoginPending(:final solicitudId, :final sesionActivaEn, :final caducaEnS):
          _pendingSolicitudId = solicitudId;
          _pendingSesionActivaEn = sesionActivaEn;
          _pendingSecondsLeft = caducaEnS;
          _stage = AuthStage.pendingConfirmation;
          notifyListeners();
          _startPolling();
      }
      return;
    } on InvalidCredentialsException {
      _error = 'Usuario o contraseña incorrectos';
    } on TooManyAttemptsException catch (e) {
      _blockedSecondsLeft = e.esperaS;
      _stage = AuthStage.blocked;
      notifyListeners();
      _startBlockCountdown();
      return;
    } on AgentUnavailableException catch (e) {
      _error = e.message;
    } on AgentErrorException catch (e) {
      _error = e.message;
    }
    _stage = AuthStage.needsLogin;
    notifyListeners();
  }

  Future<void> _enterSession(String token) async {
    await _tokenStorage.write(token);
    _token = token;
    _stage = AuthStage.loggedIn;
    notifyListeners();
  }

  void _startBlockCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _blockedSecondsLeft--;
      if (_blockedSecondsLeft <= 0) {
        _countdownTimer?.cancel();
        _stage = AuthStage.needsLogin;
      }
      notifyListeners();
    });
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_pendingSecondsLeft <= 0) return;
      _pendingSecondsLeft--;
      notifyListeners();
    });
    _pollTimer = Timer.periodic(pollInterval, (_) => _pollPending());
  }

  Future<void> _pollPending() async {
    final id = _pendingSolicitudId;
    if (id == null) return;
    final LoginRequestStatus result;
    try {
      result = await _repository.checkLoginRequest(id);
    } on AgentUnavailableException {
      return;
    } on AgentErrorException catch (e) {
      _stopWaitingWithError(e.message);
      return;
    }
    switch (result) {
      case LoginRequestPending():
        return;
      case LoginRequestApproved(:final token):
        _stopWaiting();
        await _enterSession(token);
      case LoginRequestRejected():
        _stopWaitingWithError('Se mantuvo la sesión anterior');
      case LoginRequestExpired():
        _stopWaitingWithError('Nadie confirmó a tiempo. Vuelve a iniciar sesión.');
    }
  }

  void _stopWaitingWithError(String message) {
    _stopWaiting();
    _error = message;
    _stage = AuthStage.needsLogin;
    notifyListeners();
  }

  /// Deja de esperar la confirmación y vuelve al formulario de login.
  void cancelPending() {
    _stopWaiting();
    _stage = AuthStage.needsLogin;
    notifyListeners();
  }

  void _stopWaiting() {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    _pollTimer = null;
    _countdownTimer = null;
    _pendingSolicitudId = null;
  }

  /// Cierra la sesión en el agente (si responde) y en el móvil.
  Future<void> logout() async {
    await _tryRevoking(_repository.logout);
    await _forgetSession();
    await _checkStatus();
  }

  /// Desempareja el móvil en el agente (si responde) y olvida el equipo en el móvil.
  Future<void> unpair() async {
    await _tryRevoking(_repository.unpair);
    await _forgetDevice();
    await _checkStatus();
  }

  // Si el agente no responde, igualmente se olvida la sesión (o el equipo) en
  // el móvil: el usuario no puede quedarse atrapado por un PC apagado.
  Future<void> _tryRevoking(Future<void> Function() revoke) async {
    try {
      await revoke();
    } on AgentUnavailableException {
      // Se sigue con el olvido local.
    }
  }

  /// Reacciona a un 401 de cualquier petición protegida: sin sesión
  /// (`no_autenticado`) se vuelve al login; si el agente avisa de que ya no
  /// está emparejado (`desemparejado`) se olvida también el equipo. Devuelve
  /// `true` si [error] era de sesión y ya está tratado.
  bool handleSessionError(Object error) {
    if (error is NotAuthenticatedException) {
      _forgetSession().then((_) => _checkStatus());
      return true;
    }
    if (error is UnpairedException) {
      _forgetDevice().then((_) => _checkStatus());
      return true;
    }
    return false;
  }

  Future<void> _forgetSession() async {
    await _tokenStorage.clear();
    _token = null;
  }

  Future<void> _forgetDevice() async {
    await _forgetSession();
    await onForgetDevice?.call();
  }

  @override
  void dispose() {
    _stopWaiting();
    super.dispose();
  }
}
