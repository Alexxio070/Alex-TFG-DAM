import 'dart:convert';

import 'package:iroh_flutter/iroh_flutter.dart';

import '../models/metrics.dart';
import '../repositories/metrics_repository.dart';

const _alpn = 'sysmote/tunnel/0';
const _connectTimeout = Duration(seconds: 5);
const _fetchTimeout = Duration(seconds: 3);

/// Pide /metrics al agente a través de un túnel iroh, igual que
/// [HttpMetricsRepository] lo pide por HTTP directo.
class IrohMetricsRepository implements MetricsRepository {
  IrohMetricsRepository(this._endpointId);

  final String Function() _endpointId;
  Connection? _connection;

  Future<Connection> _ensureConnection() async {
    final existing = _connection;
    if (existing != null) return existing;
    await Iroh.init();
    final endpoint = await Endpoint.bind(alpns: [utf8.encode(_alpn)]);
    final addr = EndpointAddr(PublicKey.fromHex(_endpointId()));
    final connection = await endpoint.connect(addr, utf8.encode(_alpn)).timeout(_connectTimeout);
    _connection = connection;
    return connection;
  }

  Future<String> _exchange(Connection connection) async {
    final (send, recv) = await connection.openBi();
    await send.writeAll(
      utf8.encode('GET /metrics HTTP/1.1\r\nHost: sysmote\r\nConnection: close\r\n\r\n'),
    );
    await send.finish();
    return utf8.decode(await recv.readToEnd(1000000));
  }

  Future<Map<String, dynamic>> _fetch() async {
    Connection connection;
    try {
      connection = await _ensureConnection();
    } catch (_) {
      _connection = null;
      throw AgentUnavailableException('No se pudo conectar con el agente por iroh');
    }

    String text;
    try {
      text = await _exchange(connection).timeout(_fetchTimeout);
    } catch (_) {
      // La conexión puede haber muerto (agente reiniciado, cambio de red):
      // se descarta para que el próximo intento abra una nueva.
      _connection = null;
      throw AgentUnavailableException('El agente no respondió a tiempo');
    }

    final headersEnd = text.indexOf('\r\n\r\n');
    if (headersEnd == -1 || !text.startsWith('HTTP/1.1 200')) {
      throw AgentUnavailableException('El agente respondió con un formato inesperado');
    }
    try {
      return jsonDecode(text.substring(headersEnd + 4)) as Map<String, dynamic>;
    } on FormatException {
      throw AgentUnavailableException('Respuesta del agente con formato inesperado');
    }
  }

  Future<T> _parsed<T>(T Function(Map<String, dynamic>) parse) async {
    final json = await _fetch();
    try {
      return parse(json);
    } on TypeError {
      throw AgentUnavailableException('Respuesta del agente con formato inesperado');
    }
  }

  Partition _partition(Map<String, dynamic> json) => Partition(
    id: json['id'] as String,
    mount: json['mount'] as String,
    device: json['device'] as String,
    usedGb: (json['used_gb'] as num).toDouble(),
    totalGb: (json['total_gb'] as num).toDouble(),
  );

  MetricSample _sample(Map<String, dynamic> json) => MetricSample(
    cpu: (json['cpu_percent'] as num).toDouble(),
    tempC: (json['cpu_temp_c'] as num?)?.toDouble(),
    ramGb: (json['ram_used_gb'] as num).toDouble(),
  );

  @override
  Future<MachineInfo> loadInfo() => _parsed(
    (json) => MachineInfo(
      ramTotalGb: (json['ram_total_gb'] as num).toDouble(),
      partitions: [
        for (final p in json['partitions'] as List) _partition(p as Map<String, dynamic>),
      ],
    ),
  );

  @override
  Future<List<MetricSample>> loadHistory() async {
    final sample = await _parsed(_sample);
    return List.generate(kHistoryLength, (_) => sample);
  }

  @override
  Stream<MetricSample> watch() =>
      Stream.periodic(const Duration(seconds: 1)).asyncMap((_) => _parsed(_sample));
}
