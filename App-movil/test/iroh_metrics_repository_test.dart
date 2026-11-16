import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sysmote/data/iroh/iroh_metrics_repository.dart';
import 'package:sysmote/data/models/settings.dart';
import 'package:sysmote/data/repositories/metrics_repository.dart';

final _idA = 'a' * 64;
final _idB = 'b' * 64;
const _okResponse = 'HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n{"cpu_percent": 10}';

class _FakeLink implements IrohLink {
  _FakeLink([Future<String> Function()? onExchange])
    : _onExchange = onExchange ?? (() async => _okResponse);

  final Future<String> Function() _onExchange;
  bool closed = false;

  @override
  Future<String> exchange(String request) => _onExchange();

  @override
  void close() => closed = true;
}

class _Harness {
  _Harness({Future<IrohLink> Function(String id)? connect}) {
    repository = IrohMetricsRepository(
      () => id,
      connector: (endpointId) {
        connectedIds.add(endpointId);
        return connect != null ? connect(endpointId) : Future.value(_FakeLink());
      },
    );
  }

  late final IrohMetricsRepository repository;
  String id = _idA;
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
}
