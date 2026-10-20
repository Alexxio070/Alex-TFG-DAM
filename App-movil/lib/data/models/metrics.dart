// Cuántas muestras guarda el historial de métricas (60 s a 1 muestra/s).
const kHistoryLength = 60;

class MetricSample {
  const MetricSample({required this.cpu, required this.tempC, required this.ramGb});

  final double cpu;
  final double? tempC;
  final double ramGb;
}

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

class MachineInfo {
  const MachineInfo({required this.ramTotalGb, required this.partitions});

  final double ramTotalGb;
  final List<Partition> partitions;
}
