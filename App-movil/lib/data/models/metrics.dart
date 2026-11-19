// Modelos de las métricas del PC.

/// Cuántas muestras guarda el historial de métricas (60 s a 1 muestra/s).
const kHistoryLength = 60;

/// Una muestra por segundo: CPU en %, temperatura (null si no hay sensor) y RAM usada en GB.
class MetricSample {
  const MetricSample({required this.cpu, required this.tempC, required this.ramGb});

  final double cpu;
  final double? tempC;
  final double ramGb;
}

/// Una partición del PC con su espacio usado y total en GB.
class Partition {
  const Partition({
    required this.id,
    required this.mount,
    required this.device,
    required this.usedGb,
    required this.totalGb,
  });

  final String id;
  final String mount;
  final String device;
  final double usedGb;
  final double totalGb;
}

/// Datos fijos del PC (RAM total y particiones): se leen al abrir Métricas, no en cada muestra.
class MachineInfo {
  const MachineInfo({required this.ramTotalGb, required this.partitions});

  final double ramTotalGb;
  final List<Partition> partitions;
}
