import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sysmote/data/iroh/iroh_metrics_repository.dart';
import 'package:sysmote/data/models/settings.dart';
import 'package:sysmote/data/repositories/auth_repository.dart';
import 'package:sysmote/data/repositories/metrics_repository.dart';

final _idA = 'a' * 64;
final _idB = 'b' * 64;
const _okResponse = 'HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n{"cpu_percent": 10}';

class _FakeLink implements IrohLink {
  _FakeLink([Future<String> Function()? onExchange])
    : _onExchange = onExchange ?? (() async => _okResponse);

  final Future<String> Function() _onExchange;
  bool closed = false;
  String? lastRequest;

  @override
  Future<String> exchange(String request) {
    lastRequest = request;
    return _onExchange();
  }

  @override
  void close() => closed = true;
}

class _Harness {
  _Harness({Future<IrohLink> Function(String id)? connect}) {
    repository = IrohMetricsRepository(
      () => id,
      () => token,
      connector: (endpointId) {
        connectedIds.add(endpointId);
        return connect != null ? connect(endpointId) : Future.value(_FakeLink());
      },
    );
  }

  late final IrohMetricsRepository repository;
  String id = _idA;
  String? token;
  final connectedIds = <String>[];
}

Matcher _unavailable(String message) =>
    throwsA(isA<AgentUnavailableException>().having((e) => e.message, 'message', message));

void main() {
  test('devuelve el JSON de /metrics y reutiliza la conexión entre peticiones', () async {
    final harness = _Harness();

    expect(await harness.repository.fetch(), {'cpu_percent': 10});
    await harness.repository.fetch();

    expect(harness.connectedIds, [_idA]);
  });

  test('un identificador inválido avisa con su propio mensaje y no intenta conectar', () async {
    final harness = _Harness()..id = 'no-es-un-identificador';

    await expectLater(harness.repository.fetch(), _unavailable(kInvalidIrohIdMessage));

    expect(harness.connectedIds, isEmpty);
  });

  test('si cambia el identificador de Ajustes, cierra la conexión vieja y abre otra', () async {
    final links = <String, _FakeLink>{};
    final harness = _Harness(connect: (id) async => links[id] = _FakeLink());

    await harness.repository.fetch();
    harness.id = _idB;
    await harness.repository.fetch();

    expect(harness.connectedIds, [_idA, _idB]);
    expect(links[_idA]!.closed, isTrue);
    expect(links[_idB]!.closed, isFalse);
  });

  test('si la petición falla, cierra la conexión y la siguiente reconecta', () async {
    final links = <_FakeLink>[];
    final harness = _Harness(
      connect: (_) async {
        final link = links.isEmpty
            ? _FakeLink(() async => throw StateError('conexión muerta'))
            : _FakeLink();
        links.add(link);
        return link;
      },
    );

    await expectLater(harness.repository.fetch(), _unavailable('El agente no respondió a tiempo'));
    expect(links.single.closed, isTrue);

    expect(await harness.repository.fetch(), {'cpu_percent': 10});
    expect(harness.connectedIds, [_idA, _idA]);
  });

  test('si falla al conectar, avisa y la siguiente petición lo vuelve a intentar', () async {
    var attempts = 0;
    final harness = _Harness(
      connect: (_) async {
        if (++attempts == 1) throw StateError('sin red');
        return _FakeLink();
      },
    );

    await expectLater(
      harness.repository.fetch(),
      _unavailable('No se pudo conectar con el agente por iroh'),
    );
    expect(await harness.repository.fetch(), {'cpu_percent': 10});
    expect(harness.connectedIds, [_idA, _idA]);
  });

  test('dos peticiones a la vez comparten el mismo intento de conexión', () async {
    final connecting = Completer<IrohLink>();
    final harness = _Harness(connect: (_) => connecting.future);

    final first = harness.repository.fetch();
    final second = harness.repository.fetch();
    connecting.complete(_FakeLink());

    expect(await first, {'cpu_percent': 10});
    expect(await second, {'cpu_percent': 10});
    expect(harness.connectedIds, [_idA]);
  });

  testWidgets('conectar tiene un límite de 5 s', (tester) async {
    final harness = _Harness(connect: (_) => Completer<IrohLink>().future);
    Object? error;
    harness.repository.fetch().then<void>((_) {}, onError: (Object e) => error = e);

    await tester.pump(const Duration(seconds: 4));
    expect(error, isNull);
    await tester.pump(const Duration(seconds: 1));

    expect(error, isA<AgentUnavailableException>());
  });

  testWidgets('la petición tiene un límite de 3 s y cierra la conexión', (tester) async {
    final link = _FakeLink(() => Completer<String>().future);
    final harness = _Harness(connect: (_) async => link);
    Object? error;
    harness.repository.fetch().then<void>((_) {}, onError: (Object e) => error = e);

    await tester.pump(const Duration(seconds: 2));
    expect(error, isNull);
    await tester.pump(const Duration(seconds: 1));

    expect(error, isA<AgentUnavailableException>());
    expect(link.closed, isTrue);
  });

  testWidgets('pasado el límite de 5 s, la siguiente petición espera el mismo intento', (tester) async {
    final connecting = Completer<IrohLink>();
    final harness = _Harness(connect: (_) => connecting.future);
    final errors = <Object>[];
    Map<String, dynamic>? result;

    harness.repository.fetch().then<void>((_) {}, onError: errors.add);
    await tester.pump(const Duration(seconds: 5));
    expect(errors, hasLength(1));

    harness.repository.fetch().then<void>((value) {
      result = value;
    }, onError: errors.add);
    await tester.pump();
    expect(harness.connectedIds, [_idA]);

    connecting.complete(_FakeLink());
    await tester.pump();

    expect(result, {'cpu_percent': 10});
    expect(errors, hasLength(1));
  });

  testWidgets('si el intento conecta cuando ya nadie espera, la conexión se aprovecha', (tester) async {
    final connecting = Completer<IrohLink>();
    final link = _FakeLink();
    final harness = _Harness(connect: (_) => connecting.future);
    Map<String, dynamic>? result;

    harness.repository.fetch().then<void>((_) {}, onError: (Object _) {});
    await tester.pump(const Duration(seconds: 5));
    connecting.complete(link);
    await tester.pump();

    harness.repository.fetch().then<void>((value) {
      result = value;
    });
    await tester.pump();

    expect(result, {'cpu_percent': 10});
    expect(harness.connectedIds, [_idA]);
    expect(link.closed, isFalse);
  });

  testWidgets('si cambia el identificador con un intento en marcha, el viejo se cierra al llegar', (
    tester,
  ) async {
    final attempts = {_idA: Completer<IrohLink>(), _idB: Completer<IrohLink>()};
    final harness = _Harness(connect: (id) => attempts[id]!.future);
    final linkA = _FakeLink();
    final linkB = _FakeLink();
    Map<String, dynamic>? result;

    harness.repository.fetch().then<void>((_) {}, onError: (Object _) {});
    await tester.pump(const Duration(seconds: 5));

    harness.id = _idB;
    harness.repository.fetch().then<void>((value) {
      result = value;
    }, onError: (Object _) {});
    await tester.pump();
    expect(harness.connectedIds, [_idA, _idB]);

    attempts[_idB]!.complete(linkB);
    await tester.pump();
    attempts[_idA]!.complete(linkA);
    await tester.pump();

    expect(result, {'cpu_percent': 10});
    expect(linkA.closed, isTrue);
    expect(linkB.closed, isFalse);
  });

  test('tras muchas conexiones muertas seguidas solo queda abierta la última', () async {
    final links = <_FakeLink>[];
    final harness = _Harness(
      connect: (_) async {
        final link = links.length < 20
            ? _FakeLink(() async => throw StateError('conexión muerta'))
            : _FakeLink();
        links.add(link);
        return link;
      },
    );

    for (var i = 0; i < 20; i++) {
      await expectLater(harness.repository.fetch(), throwsA(isA<AgentUnavailableException>()));
    }
    expect(await harness.repository.fetch(), {'cpu_percent': 10});

    expect(links, hasLength(21));
    expect(links.where((link) => !link.closed), [links.last]);
  });

  test('manda el token de sesión como Bearer', () async {
    final link = _FakeLink();
    final harness = _Harness(connect: (_) async => link)..token = 't0k3n';

    await harness.repository.fetch();

    expect(link.lastRequest, contains('Authorization: Bearer t0k3n\r\n'));
  });

  test('sin token no manda la cabecera Authorization', () async {
    final link = _FakeLink();
    final harness = _Harness(connect: (_) async => link);

    await harness.repository.fetch();

    expect(link.lastRequest, isNot(contains('Authorization')));
  });

  test('un 401 no_autenticado o desemparejado lanza la excepción de sesión', () async {
    String respuesta(String error) =>
        'HTTP/1.1 401 Unauthorized\r\n\r\n{"error": "$error", "mensaje": "x"}';
    final noAuth = _Harness(connect: (_) async => _FakeLink(() async => respuesta('no_autenticado')));
    final desemp = _Harness(connect: (_) async => _FakeLink(() async => respuesta('desemparejado')));

    await expectLater(noAuth.repository.fetch(), throwsA(isA<NotAuthenticatedException>()));
    await expectLater(desemp.repository.fetch(), throwsA(isA<UnpairedException>()));
  });
}
