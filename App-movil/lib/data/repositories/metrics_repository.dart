// Interfaz de las métricas del PC.

import '../models/metrics.dart';

/// Métricas del PC: datos fijos, historial inicial y una muestra por segundo.
abstract class MetricsRepository {
  Future<MachineInfo> loadInfo();
  Future<List<MetricSample>> loadHistory();
  Stream<MetricSample> watch();
}
