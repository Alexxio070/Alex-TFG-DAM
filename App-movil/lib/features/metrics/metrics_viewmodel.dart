import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/metrics.dart';
import '../../data/repositories/metrics_repository.dart';
import '../auth/auth_viewmodel.dart';

class MetricsViewModel extends ChangeNotifier {
  MetricsViewModel(this._repository, this._auth);

  final MetricsRepository _repository;
  final AuthViewModel _auth;
  StreamSubscription<MetricSample>? _subscription;
  List<MetricSample> _history = const [];
  MachineInfo? _info;
  String? _partitionId;
  String? _error;
  bool _active = false;
  // Cada refresco y cada parada lo incrementan: un refresco que sigue cargando
  // cuando llega otro (volver rápido a la pantalla, «Reintentar») se descarta.
  int _generation = 0;

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

  void start() {
    if (_active) return;
    _active = true;
    _refresh();
  }

  void stop() {
    _active = false;
    _generation++;
    _subscription?.cancel();
    _subscription = null;
  }

  void retry() {
    _active = true;
    _refresh();
  }

  Future<void> _refresh() async {
    final generation = ++_generation;
    await _subscription?.cancel();
    _error = null;
    try {
      final info = await _repository.loadInfo();
      final history = await _repository.loadHistory();
      if (!_active || generation != _generation) return;
      _info = info;
      _history = history;
      notifyListeners();
      _subscription = _repository.watch().listen(
        (sample) {
          if (!_active) return;
          _history = [..._history.skip(1), sample];
          _error = null;
          notifyListeners();
        },
        onError: (Object error) {
          if (!_active || _sessionLost(error)) return;
          _error = _messageFor(error);
          notifyListeners();
        },
      );
    } catch (error) {
      if (!_active || generation != _generation || _sessionLost(error)) return;
      _error = _messageFor(error);
      notifyListeners();
    }
  }

  // Un 401 de sesión no es un fallo de conexión: AuthViewModel lleva al login
  // y aquí se deja de sondear.
  bool _sessionLost(Object error) {
    if (!_auth.handleSessionError(error)) return false;
    stop();
    return true;
  }

  String _messageFor(Object error) =>
      error is AgentUnavailableException ? error.message : 'No se puede conectar con el agente';

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
