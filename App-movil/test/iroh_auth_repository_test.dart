// Tests de IrohAuthRepository con una conexión iroh falsa, y del HTTP crudo que viaja por ella.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sysmote/data/iroh/iroh_auth_repository.dart';
import 'package:sysmote/data/iroh/iroh_connection.dart';
import 'package:sysmote/data/models/auth.dart';
import 'package:sysmote/data/repositories/agent_exceptions.dart';
import 'package:sysmote/data/repositories/auth_repository.dart';

import 'fakes/in_memory_token_storage.dart';

final _id = 'a' * 64;

class _FakeLink implements IrohLink {
  _FakeLink(this.response);

  String response;
  final requests = <String>[];

  @override
  Future<String> exchange(String request) async {
    requests.add(request);
    return response;
  }

  @override
  void close() {}
}

String _http(int status, [Map<String, Object?>? body]) =>
    'HTTP/1.1 $status X\r\nContent-Type: application/json\r\n\r\n${body == null ? '' : jsonEncode(body)}';

void main() {
  late InMemoryTokenStorage storage;
  late _FakeLink link;

  IrohAuthRepository repoReplying(String response) {
    link = _FakeLink(response);
    return IrohAuthRepository(
      IrohConnection(() => _id, connector: (_) async => link),
      storage,
    );
  }

  setUp(() => storage = InMemoryTokenStorage());

  test('login manda un POST /login con el cuerpo y su Content-Length en bytes', () async {
    final repo = repoReplying(_http(200, {'token': 't0k3n', 'usuario': 'alex'}));

    final outcome = await repo.login(usuario: 'alex', contrasena: 'ñandú1A', dispositivo: 'Pixel 8');

    expect((outcome as LoggedIn).token, 't0k3n');
    final request = link.requests.single;
    final body = request.substring(request.indexOf('\r\n\r\n') + 4);
    expect(request, startsWith('POST /login HTTP/1.1\r\n'));
    expect(request, contains('Content-Length: ${utf8.encode(body).length}\r\n'));
    expect(request, isNot(contains('Authorization')));
    expect(jsonDecode(body)['contrasena'], 'ñandú1A');
  });

  test('las rutas protegidas mandan el token guardado como Bearer', () async {
    await storage.write('t0k3n');
    final repo = repoReplying(_http(200, {
      'usuario': 'alex',
      'dispositivo': 'Pixel 8',
      'creada': '2026-12-20T18:30:00+01:00',
    }));

    final session = await repo.session();

    expect(session.usuario, 'alex');
    expect(link.requests.single, startsWith('GET /sesion HTTP/1.1\r\n'));
    expect(link.requests.single, contains('Authorization: Bearer t0k3n\r\n'));
  });

  test('un 204 sin cuerpo se acepta en logout y unpair', () async {
    await storage.write('t0k3n');
    final repo = repoReplying(_http(204));

    await repo.logout();
    await repo.unpair();

    expect(link.requests[0], startsWith('POST /logout'));
    expect(link.requests[1], startsWith('POST /desemparejar'));
  });

  test('traduce los errores del contrato igual que por HTTPS', () async {
    final repo = repoReplying(_http(401, {'error': 'desemparejado', 'mensaje': 'x'}));
    await expectLater(repo.session(), throwsA(isA<UnpairedException>()));

    link.response = _http(429, {'error': 'demasiados_intentos', 'mensaje': 'x', 'espera_s': 40});
    await expectLater(
      repo.login(usuario: 'a', contrasena: 'b', dispositivo: 'c'),
      throwsA(isA<TooManyAttemptsException>().having((e) => e.esperaS, 'esperaS', 40)),
    );
  });

  test('una respuesta sin formato HTTP o con un cuerpo roto lanza AgentUnavailableException', () async {
    final sinFormato = repoReplying('basura');
    final cuerpoRoto = repoReplying('HTTP/1.1 200 OK\r\n\r\nno es json');

    expect(() => sinFormato.status(), throwsA(isA<AgentUnavailableException>()));
    expect(() => cuerpoRoto.status(), throwsA(isA<AgentUnavailableException>()));
  });

  test('un identificador iroh inválido avisa sin conectar', () async {
    final repo = IrohAuthRepository(
      IrohConnection(() => 'no-valido', connector: (_) async => throw StateError('no debe conectar')),
      storage,
    );

    await expectLater(
      repo.status(),
      throwsA(isA<AgentUnavailableException>().having((e) => e.message, 'message', contains('64'))),
    );
  });

  group('HTTP crudo', () {
    test('buildRawHttpRequest sin cuerpo ni token', () {
      expect(
        buildRawHttpRequest('GET', '/metrics'),
        'GET /metrics HTTP/1.1\r\nHost: sysmote\r\nConnection: close\r\n\r\n',
      );
    });

    test('parseRawHttpResponse separa el código y el cuerpo', () {
      final response = parseRawHttpResponse('HTTP/1.1 202 Accepted\r\nA: b\r\n\r\n{"x":1}');

      expect(response.status, 202);
      expect(response.body, '{"x":1}');
    });
  });
}
