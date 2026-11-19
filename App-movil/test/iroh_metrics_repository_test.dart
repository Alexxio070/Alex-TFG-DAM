/// Tests de [IrohMetricsRepository]: lo que añade sobre la conexión iroh
/// compartida (la petición `/metrics`, el token y los errores). La conexión
/// en sí se prueba en `iroh_connection_test.dart`.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:sysmote/data/iroh/iroh_connection.dart';
import 'package:sysmote/data/iroh/iroh_metrics_repository.dart';
import 'package:sysmote/data/repositories/agent_exceptions.dart';

const _okResponse = 'HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n{"cpu_percent": 10}';

class _FakeLink implements IrohLink {
  _FakeLink([this.response = _okResponse]);

  final String response;
  String? lastRequest;

  @override
  Future<String> exchange(String request) async {
    lastRequest = request;
    return response;
  }

  @override
  void close() {}
}

IrohMetricsRepository _repository(_FakeLink link, {String? token}) => IrohMetricsRepository(
  IrohConnection(() => 'a' * 64, connector: (_) async => link),
  () => token,
);

Matcher _unavailable(String message) =>
    throwsA(isA<AgentUnavailableException>().having((e) => e.message, 'message', message));

void main() {
  test('pide /metrics y devuelve su JSON', () async {
    final link = _FakeLink();

    expect(await _repository(link).fetch(), {'cpu_percent': 10});
    expect(link.lastRequest, startsWith('GET /metrics HTTP/1.1\r\n'));
  });

  test('manda el token de sesión como Bearer', () async {
    final link = _FakeLink();

    await _repository(link, token: 't0k3n').fetch();

    expect(link.lastRequest, contains('Authorization: Bearer t0k3n\r\n'));
  });

  test('sin token no manda la cabecera Authorization', () async {
    final link = _FakeLink();

    await _repository(link).fetch();

    expect(link.lastRequest, isNot(contains('Authorization')));
  });

  test('un 401 no_autenticado o desemparejado lanza la excepción de sesión', () async {
    String respuesta(String error) =>
        'HTTP/1.1 401 Unauthorized\r\n\r\n{"error": "$error", "mensaje": "x"}';

    await expectLater(
      _repository(_FakeLink(respuesta('no_autenticado'))).fetch(),
      throwsA(isA<NotAuthenticatedException>()),
    );
    await expectLater(
      _repository(_FakeLink(respuesta('desemparejado'))).fetch(),
      throwsA(isA<UnpairedException>()),
    );
  });

  test('otro código o un cuerpo que no es JSON avisan de formato inesperado', () async {
    await expectLater(
      _repository(_FakeLink('HTTP/1.1 500 Internal Server Error\r\n\r\n{}')).fetch(),
      _unavailable('El agente respondió con un formato inesperado'),
    );
    await expectLater(
      _repository(_FakeLink('HTTP/1.1 200 OK\r\n\r\nno es json')).fetch(),
      _unavailable('Respuesta del agente con formato inesperado'),
    );
  });
}
