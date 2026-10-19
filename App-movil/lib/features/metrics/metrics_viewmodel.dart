import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/metrics.dart';
import '../../data/repositories/metrics_repository.dart';

class MetricsViewModel extends ChangeNotifier {
  MetricsViewModel(this._repository) {
    _start();
  }

  final MetricsRepository _repository;
  StreamSubscription<MetricSample>? _subscription;
  List<MetricSample> _history = const [];
  MachineInfo? _info;
  String? _partitionId;
  String? _error;

  List<MetricSample> get history => _history;
  MachineInfo? get info => _info;
  bool get ready => _info != null && _history.isNotEmpty;
  String? get error => _error;

  Partition? get partition {
    final partitions = _info?.partitions;
    if (partitions == null || partitions.isEmpty) return null;
    return partitions.firstWhere(
      (p) => p.id == _partitionId,
      orElse: () => partitions.firstWhere((p) => p.mount == '/', orElse: () => partitions.first),
    );
  }

  Future<void> _start() async {
    await _subscription?.cancel();
    _error = null;
    try {
      _info = await _repository.loadInfo();
      _history = await _repository.loadHistory();
      notifyListeners();
      _subscription = _repository.watch().listen(
        (sample) {
          _history = [..._history.skip(1), sample];
          _error = null;
          notifyListeners();
        },
        onError: (Object error) {
          _error = _messageFor(error);
          notifyListeners();
        },
      );
    } catch (error) {
      _error = _messageFor(error);
      notifyListeners();
    }
  }

  String _messageFor(Object error) =>
      error is AgentUnavailableException ? error.message : 'No se puede conectar con el agente';

  void retry() => _start();

  void selectPartition(String id) {
    _partitionId = id;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
