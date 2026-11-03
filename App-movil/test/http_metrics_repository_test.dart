import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sysmote/data/http/http_metrics_repository.dart';
import 'package:sysmote/data/repositories/metrics_repository.dart';

const _body = '''
{
  "cpu_percent": 42.5,
  "cpu_temp_c": 55.0,
  "ram_used_gb": 9.1,
  "ram_total_gb": 16.0,
  "partitions": [
    {"id": "/", "mount": "/", "device": "/dev/nvme0n1p2", "used_gb": 64.2, "total_gb": 120.0}
  ]
}
''';

const _bodyWithoutTemp = '''
{
  "cpu_percent": 10.0,
  "cpu_temp_c": null,
  "ram_used_gb": 5.0,
  "ram_total_gb": 16.0,
  "partitions": []
}
''';

void main() {
  test('loadInfo parsea las particiones y la RAM total del agente', () async {
    final repository = HttpMetricsRepository(
      () => '127.0.0.1:8443',
      client: MockClient((request) async {
        expect(request.url.toString(), 'http://127.0.0.1:8443/metrics');
        return http.Response(_body, 200);
      }),
    );

    final info = await repository.loadInfo();

    expect(info.ramTotalGb, 16.0);
    expect(info.partitions, hasLength(1));
    expect(info.partitions.single.mount, '/');
    expect(info.partitions.single.usedGb, 64.2);
  });

  test('loadHistory parsea la muestra actual del agente', () async {
    final repository = HttpMetricsRepository(
      () => '127.0.0.1:8443',
      client: MockClient((request) async => http.Response(_body, 200)),
    );

    final history = await repository.loadHistory();

    expect(history, hasLength(60));
    expect(history.last.cpu, 42.5);
    expect(history.last.tempC, 55.0);
    expect(history.last.ramGb, 9.1);
  });

  test('una temperatura null en el agente se traduce a tempC null', () async {
    final repository = HttpMetricsRepository(
      () => '127.0.0.1:8443',
      client: MockClient((request) async => http.Response(_bodyWithoutTemp, 200)),
    );

    final history = await repository.loadHistory();

    expect(history.last.tempC, isNull);
  });

  test('watch pide /metrics a cada tick y refleja los nuevos valores', () async {
    final bodies = [_body, _bodyWithoutTemp];
    var call = 0;
    final repository = HttpMetricsRepository(
      () => '127.0.0.1:8443',
      client: MockClient((request) async {
        final body = bodies[call];
        call++;
        return http.Response(body, 200);
      }),
    );

    final samples = await repository.watch().take(2).toList();

    expect(samples[0].tempC, 55.0);
    expect(samples[1].tempC, isNull);
  });

  test('construye la URL con la dirección guardada en los ajustes', () async {
    http.Request? captured;
    final repository = HttpMetricsRepository(
      () => '192.168.1.50:9000',
      client: MockClient((request) async {
        captured = request;
        return http.Response(_body, 200);
      }),
    );

    await repository.loadInfo();

    expect(captured!.url.toString(), 'http://192.168.1.50:9000/metrics');
  });

  test('un código distinto de 200 lanza AgentUnavailableException', () async {
    final repository = HttpMetricsRepository(
      () => '127.0.0.1:8443',
      client: MockClient((request) async => http.Response('error interno', 500)),
    );

    await expectLater(repository.loadInfo(), throwsA(isA<AgentUnavailableException>()));
  });

  test('un JSON malformado lanza AgentUnavailableException', () async {
    final repository = HttpMetricsRepository(
      () => '127.0.0.1:8443',
      client: MockClient((request) async => http.Response('no es json', 200)),
    );

    await expectLater(repository.loadInfo(), throwsA(isA<AgentUnavailableException>()));
  });

  test('un timeout lanza AgentUnavailableException', () async {
    final repository = HttpMetricsRepository(
      () => '127.0.0.1:8443',
      client: MockClient((request) async {
        await Future<void>.delayed(const Duration(seconds: 5));
        return http.Response(_body, 200);
      }),
    );

    await expectLater(repository.loadInfo(), throwsA(isA<AgentUnavailableException>()));
  }, timeout: const Timeout(Duration(seconds: 10)));

  test('un campo con un tipo inesperado lanza AgentUnavailableException', () async {
    final repository = HttpMetricsRepository(
      () => '127.0.0.1:8443',
      client: MockClient((request) async => http.Response('{"cpu_percent": "no es un número"}', 200)),
    );

    await expectLater(repository.loadHistory(), throwsA(isA<AgentUnavailableException>()));
  });
}
