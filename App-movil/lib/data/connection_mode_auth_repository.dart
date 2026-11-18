import 'models/auth.dart';
import 'models/settings.dart';
import 'repositories/auth_repository.dart';

/// Elige entre dos [AuthRepository] según el modo de conexión actual, leído
/// en cada llamada (igual que [ConnectionModeMetricsRepository]): cambiar el
/// modo en Ajustes se nota en la siguiente petición.
class ConnectionModeAuthRepository implements AuthRepository {
  ConnectionModeAuthRepository({
    required this.connectionMode,
    required this.local,
    required this.iroh,
  });

  final ConnectionMode Function() connectionMode;
  final AuthRepository local;
  final AuthRepository iroh;

  AuthRepository get _active => connectionMode() == ConnectionMode.iroh ? iroh : local;

  @override
  Future<AgentStatus> status() => _active.status();

  @override
  Future<LoginOutcome> login({
    required String usuario,
    required String contrasena,
    required String dispositivo,
  }) =>
      _active.login(usuario: usuario, contrasena: contrasena, dispositivo: dispositivo);

  @override
  Future<LoggedIn> register({
    required String codigo,
    required String usuario,
    required String contrasena,
    required String dispositivo,
  }) =>
      _active.register(
        codigo: codigo,
        usuario: usuario,
        contrasena: contrasena,
        dispositivo: dispositivo,
      );

  @override
  Future<LoginRequestStatus> checkLoginRequest(String solicitudId) =>
      _active.checkLoginRequest(solicitudId);

  @override
  Future<SessionInfo> session() => _active.session();

  @override
  Future<void> logout() => _active.logout();

  @override
  Future<void> unpair() => _active.unpair();
}
