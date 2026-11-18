import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/auth.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/metrics_repository.dart' show AgentUnavailableException;
import '../../data/repositories/token_storage.dart';

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
  String? _usuario;
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
  String? get usuario => _usuario;
  String? get pendingSesionActivaEn => _pendingSesionActivaEn;
  int get pendingSecondsLeft => _pendingSecondsLeft;
  int get blockedSecondsLeft => _blockedSecondsLeft;

  Future<void> start() async {
    _stage = AuthStage.loading;
    notifyListeners();
    final token = await _tokenStorage.read();
    if (token != null) {
      try {
        final session = await _repository.session();
        _token = token;
        _usuario = session.usuario;
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
      await _tokenStorage.write(session.token);
      _token = session.token;
      _usuario = session.usuario;
      _stage = AuthStage.loggedIn;
    } on RegistrationClosedException {
      _error = 'El registro no está abierto. Pulsa configuración inicial en la TUI.';
      _stage = AuthStage.needsRegistration;
    } on CodeExpiredException {
      _error = 'El código de registro ha caducado. '
          'Pulsa configuración inicial en la TUI para generar otro.';
      _stage = AuthStage.needsRegistration;
    } on InvalidCodeException {
      _error = 'El código de registro no es válido';
      _stage = AuthStage.needsRegistration;
    } on WeakPasswordException catch (e) {
      _error = 'Contraseña débil: ${e.motivos.join(', ')}';
      _stage = AuthStage.needsRegistration;
    } on AgentUnavailableException catch (e) {
      _error = e.message;
      _stage = AuthStage.needsRegistration;
    } on AgentErrorException catch (e) {
      _error = e.message;
      _stage = AuthStage.needsRegistration;
    }
    notifyListeners();
  }

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
        case LoggedIn(:final token, :final usuario):
          await _tokenStorage.write(token);
          _token = token;
          _usuario = usuario;
          _stage = AuthStage.loggedIn;
          notifyListeners();
        case LoginPending(:final solicitudId, :final sesionActivaEn, :final caducaEnS):
          _pendingSolicitudId = solicitudId;
          _pendingSesionActivaEn = sesionActivaEn;
          _pendingSecondsLeft = caducaEnS;
          _stage = AuthStage.pendingConfirmation;
          notifyListeners();
          _startPolling();
      }
    } on InvalidCredentialsException {
      _error = 'Usuario o contraseña incorrectos';
      _stage = AuthStage.needsLogin;
      notifyListeners();
    } on TooManyAttemptsException catch (e) {
      _blockedSecondsLeft = e.esperaS;
      _stage = AuthStage.blocked;
      notifyListeners();
      _startBlockCountdown();
    } on AgentUnavailableException catch (e) {
      _error = e.message;
      _stage = AuthStage.needsLogin;
      notifyListeners();
    } on AgentErrorException catch (e) {
      _error = e.message;
      _stage = AuthStage.needsLogin;
      notifyListeners();
    }
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
      _stopWaiting();
      _error = e.message;
      _stage = AuthStage.needsLogin;
      notifyListeners();
      return;
    }
    switch (result) {
      case LoginRequestPending():
        return;
      case LoginRequestApproved(:final token, :final usuario):
        _stopWaiting();
        await _tokenStorage.write(token);
        _token = token;
        _usuario = usuario;
        _stage = AuthStage.loggedIn;
        notifyListeners();
      case LoginRequestRejected():
        _stopWaiting();
        _error = 'Se mantuvo la sesión anterior';
        _stage = AuthStage.needsLogin;
        notifyListeners();
      case LoginRequestExpired():
        _stopWaiting();
        _error = 'Nadie confirmó a tiempo. Vuelve a iniciar sesión.';
        _stage = AuthStage.needsLogin;
        notifyListeners();
    }
  }

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

  Future<void> logout() async {
    await _tryRevoking(_repository.logout);
    await _forgetSession();
    await _checkStatus();
  }

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
    _usuario = null;
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
