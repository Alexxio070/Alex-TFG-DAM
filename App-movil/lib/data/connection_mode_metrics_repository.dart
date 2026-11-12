import 'models/metrics.dart';
import 'models/settings.dart';
import 'repositories/metrics_repository.dart';

/// Elige entre dos [MetricsRepository] según el modo de conexión actual,
/// leído en cada llamada (igual que [HttpMetricsRepository] lee la dirección
/// del agente en cada petición): cambiar el modo en Ajustes se nota la
/// próxima vez que la pantalla de métricas vuelve a pedir datos.
class ConnectionModeMetricsRepository implements MetricsRepository {
  ConnectionModeMetricsRepository({
    required this.connectionMode,
    required this.local,
    required this.iroh,
  });

  final ConnectionMode Function() connectionMode;
  final MetricsRepository local;
  final MetricsRepository iroh;

  MetricsRepository get _active => connectionMode() == ConnectionMode.iroh ? iroh : local;

  @override
  Future<MachineInfo> loadInfo() => _active.loadInfo();

  @override
  Future<List<MetricSample>> loadHistory() => _active.loadHistory();

  @override
  Stream<MetricSample> watch() => _active.watch();
}
