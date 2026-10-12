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

  List<MetricSample> get history => _history;
  MachineInfo? get info => _info;
  bool get ready => _info != null && _history.isNotEmpty;

  Partition? get partition {
    final partitions = _info?.partitions;
    if (partitions == null || partitions.isEmpty) return null;
    return partitions.firstWhere(
      (p) => p.id == _partitionId,
      orElse: () => partitions.firstWhere((p) => p.mount == '/', orElse: () => partitions.first),
    );
  }

  Future<void> _start() async {
    _info = await _repository.loadInfo();
    _history = await _repository.loadHistory();
    notifyListeners();
    _subscription = _repository.watch().listen((sample) {
      _history = [..._history.skip(1), sample];
      notifyListeners();
    });
  }

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
