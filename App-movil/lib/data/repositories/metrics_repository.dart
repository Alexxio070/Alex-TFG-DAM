// Interfaz de las métricas del PC y el error de agente inalcanzable.

import '../models/metrics.dart';

/// Métricas del PC: datos fijos, historial inicial y una muestra por segundo.
abstract class MetricsRepository {
  Future<MachineInfo> loadInfo();
  Future<List<MetricSample>> loadHistory();
  Stream<MetricSample> watch();
}

/// Mensaje para una respuesta del agente que no se puede interpretar.
const kUnexpectedFormatMessage = 'Respuesta del agente con formato inesperado';

/// No se puede hablar con el agente (red, timeout, huella o respuesta ilegible).
class AgentUnavailableException implements Exception {
  AgentUnavailableException(this.message);

  final String message;

  @override
  String toString() => message;
}
