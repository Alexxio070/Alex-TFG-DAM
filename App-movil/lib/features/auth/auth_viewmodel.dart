// ViewModel del login: única fuente de verdad sobre si hay sesión con el agente y dueño del token.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/auth.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/agent_exceptions.dart';
import '../../data/repositories/token_storage.dart';

/// Popups de la bienvenida según el estado del agente y de la sesión.
const kSessionExpiredPopup = 'Tu sesión ha caducado. Inicia sesión de nuevo.';
const kSessionInvalidPopup = 'Tu sesión ya no es válida. Inicia sesión de nuevo.';
const kAccountExistsPopup = 'Este agente ya tiene una cuenta. Inicia sesión.';
const kNoAccountPopup = 'El agente aún no tiene cuenta. Regístrala.';
const kRegistrationClosedPopup = 'El registro está cerrado. Ábrelo desde la TUI del PC.';

/// En qué punto está el login; [LoginView] muestra una pantalla distinta para cada uno.
enum AuthStage {
  loading,
  welcome,
  needsRegistration,
  registering,
  needsLogin,
  submitting,
  blocked,
  pendingConfirmation,
  loggedIn,
}

/// Comprueba el agente al arrancar y desde la bienvenida, registra la cuenta, inicia y cierra sesión, espera la
/// confirmación en la TUI cuando ya hay otra sesión y guarda el token en el móvil y en memoria.
class AuthViewModel extends ChangeNotifier {
  AuthViewModel(
    this._repository,
    this._tokenStorage, {
    this.pollInterval = const Duration(seconds: 2),
    this.onForgetDevice,
    this.isPaired,
    this.markPaired,
  }) {
    start();
  }

  final AuthRepository _repository;
  final TokenStorage _tokenStorage;
  final Duration pollInterval;

  /// Borra lo que la app sabe del equipo (dirección, huella, identificador
  /// iroh) cuando se desempareja o el agente avisa de que ya no está emparejado.
  final Future<void> Function()? onForgetDevice;

  /// Lee y pone la marca de emparejada, que vive en los ajustes.
  final bool Function()? isPaired;
  final Future<void> Function()? markPaired;

  String? _token;
  AuthStage _stage = AuthStage.loading;
  bool _sesionActivaAviso = false;
  bool _checking = false;
  String? _sessionNotice;
  AgentUnavailableCause? _unreachableCause;
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
  bool get paired => isPaired?.call() ?? false;
  bool get checking => _checking;

  /// Devuelve el popup pendiente de que la sesión haya caducado o ya no sea válida, una sola vez;
  /// `null` si no hay ninguno.
  String? takeSessionNotice() {
    final notice = _sessionNotice;
    _sessionNotice = null;
    return notice;
  }

  bool get hasSessionNotice => _sessionNotice != null;

  /// Por qué no responde el PC; `null` si respondió o no hay nada que avisar.
  AgentUnavailableCause? get unreachableCause => _unreachableCause;
  String? get error => _error;
  String? get pendingSesionActivaEn => _pendingSesionActivaEn;
  int get pendingSecondsLeft => _pendingSecondsLeft;
  int get blockedSecondsLeft => _blockedSecondsLeft;

  /// Entra con el token guardado si el agente lo acepta; si no, muestra la bienvenida. Sin
  /// emparejar no avisa de que el PC no responde.
  Future<void> start() async {
    _stage = AuthStage.loading;
    notifyListeners();
    await _check();
    if (_stage == AuthStage.loggedIn) return;
    if (!paired) _unreachableCause = null;
    _toWelcome();
  }

  /// Comprueba el agente tras guardar la hoja de conexión; si responde, queda emparejada.
  Future<void> connect() => _checkFromWelcome();

  /// Vuelve a comprobar el agente al volver la app a primer plano.
  Future<void> refresh() async {
    if (_stage != AuthStage.welcome || _checking || !paired) return;
    await _checkFromWelcome();
  }

  /// Abre el formulario de login si el agente tiene cuenta; si no, devuelve el popup que toca.
  Future<String?> openLogin() => _openForm(login: true);

  /// Abre el formulario de registro si está abierto; si no, devuelve el popup que toca.
  Future<String?> openRegistration() => _openForm(login: false);

  Future<String?> _openForm({required bool login}) async {
    final status = await _checkFromWelcome();
    if (status == null) return null;
    final popup = login ? _loginPopup(status) : _registrationPopup(status);
    if (popup != null) return popup;
    _error = null;
    _sesionActivaAviso = status.sesionActiva;
    _stage = login ? AuthStage.needsLogin : AuthStage.needsRegistration;
    notifyListeners();
    return null;
  }

  String? _loginPopup(AgentStatus status) => status.configurado
      ? null
      : status.registroAbierto
      ? kNoAccountPopup
      : kRegistrationClosedPopup;

  String? _registrationPopup(AgentStatus status) => status.configurado
      ? kAccountExistsPopup
      : status.registroAbierto
      ? null
      : kRegistrationClosedPopup;

  /// Deja el formulario y vuelve a la bienvenida.
  void backToWelcome() {
    _stopWaiting();
    _error = null;
    _toWelcome();
  }

  void _toWelcome() {
    _stage = AuthStage.welcome;
    notifyListeners();
  }

  Future<AgentStatus?> _checkFromWelcome() async {
    _checking = true;
    notifyListeners();
    final status = await _check();
    _checking = false;
    notifyListeners();
    return status;
  }

  // Entra si el token guardado sigue valiendo; si no, consulta /estado. Devuelve el estado, o
  // `null` si ya ha entrado o el agente no responde. Un fallo de red no borra el token.
  Future<AgentStatus?> _check() async {
    try {
      if (await _enterWithSavedToken()) return null;
      final status = await _repository.status();
      _unreachableCause = null;
      await _markPaired();
      return status;
    } on AgentUnavailableException catch (e) {
      _unreachableCause = e.cause;
    } on AgentErrorException {
      _unreachableCause = AgentUnavailableCause.unexpected;
    }
    return null;
  }

  Future<bool> _enterWithSavedToken() async {
    final token = await _tokenStorage.read();
    if (token == null) return false;
    try {
      await _repository.session();
    } on NotAuthenticatedException {
      await _tokenStorage.clear();
      _sessionNotice = kSessionInvalidPopup;
      return false;
    } on SessionExpiredException {
      await _tokenStorage.clear();
      _sessionNotice = kSessionExpiredPopup;
      return false;
    } on UnpairedException {
      await _forgetDevice();
      return false;
    }
    _unreachableCause = null;
    await _markPaired();
    _token = token;
    _stage = AuthStage.loggedIn;
    notifyListeners();
    return true;
  }

  Future<void> _markPaired() async {
    if (!paired) await markPaired?.call();
  }

  /// Crea la cuenta con el código de registro de la TUI y entra en sesión. Si otro móvil se ha
  /// adelantado (`registro_cerrado`), vuelve a la bienvenida y devuelve el popup que toca.
  Future<String?> register({
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
      return null;
    } on RegistrationClosedException {
      _toWelcome();
      return kAccountExistsPopup;
    } on CodeExpiredException {
      _error =
          'El código de registro ha caducado. '
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
    return null;
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
    _toWelcome();
  }

  /// Desempareja el móvil en el agente (si responde) y olvida el equipo en el móvil.
  Future<void> unpair() async {
    await _tryRevoking(_repository.unpair);
    await _forgetDevice();
    _toWelcome();
  }

  // Si el agente no responde o ya no reconoce el token, igualmente se olvida la
  // sesión (o el equipo) en el móvil: el usuario no puede quedarse atrapado por
  // un PC apagado ni por un token que ya no vale.
  Future<void> _tryRevoking(Future<void> Function() revoke) async {
    try {
      await revoke();
    } catch (e) {
      final nothingToRevoke =
          e is AgentUnavailableException ||
          e is NotAuthenticatedException ||
          e is SessionExpiredException ||
          e is UnpairedException;
      if (!nothingToRevoke) rethrow;
    }
  }

  /// Reacciona a un 401 de cualquier petición protegida: sin sesión
  /// (`no_autenticado`) o con el token pasado de los 7 días
  /// (`sesion_caducada`) se vuelve a la bienvenida con su popup; si el agente
  /// avisa de que ya no está emparejado (`desemparejado`) se olvida también el
  /// equipo, sin popup. Devuelve `true` si [error] era de sesión y ya está
  /// tratado.
  bool handleSessionError(Object error) {
    if (error is NotAuthenticatedException) {
      _sessionNotice = kSessionInvalidPopup;
      _forgetSession().then((_) => _toWelcome());
      return true;
    }
    if (error is SessionExpiredException) {
      _sessionNotice = kSessionExpiredPopup;
      _forgetSession().then((_) => _toWelcome());
      return true;
    }
    if (error is UnpairedException) {
      _forgetDevice().then((_) => _toWelcome());
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
