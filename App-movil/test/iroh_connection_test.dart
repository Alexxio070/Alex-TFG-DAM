/// Tests de [IrohConnection], la conexión iroh compartida con el agente.
///
/// Usan una conexión falsa ([IrohLink]) en lugar de iroh: prueban cuándo se
/// conecta, se reutiliza, se cierra y se reintenta, no la red.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sysmote/data/iroh/iroh_connection.dart';
import 'package:sysmote/data/models/settings.dart';
import 'package:sysmote/data/repositories/agent_exceptions.dart';

final _idA = 'a' * 64;
final _idB = 'b' * 64;
const _request = 'GET /estado HTTP/1.1\r\n\r\n';
const _response = 'HTTP/1.1 200 OK\r\n\r\n{}';

class _FakeLink implements IrohLink {
  _FakeLink([Future<String> Function()? onExchange])
    : _onExchange = onExchange ?? (() async => _response);

  final Future<String> Function() _onExchange;
  bool closed = false;

  @override
  Future<String> exchange(String request) => _onExchange();

  @override
  void close() => closed = true;
}

class _Harness {
  _Harness({Future<IrohLink> Function(String id)? connect}) {
    connection = IrohConnection(
      () => id,
      connector: (endpointId) {
        connectedIds.add(endpointId);
        return connect != null ? connect(endpointId) : Future.value(_FakeLink());
      },
    );
  }

  late final IrohConnection connection;
  String id = _idA;
  final connectedIds = <String>[];

  Future<String> request() => connection.request(_request);
}

Matcher _unavailable(String message) =>
    throwsA(isA<AgentUnavailableException>().having((e) => e.message, 'message', message));

void main() {
  test('reutiliza la conexión entre peticiones', () async {
    final harness = _Harness();

    expect(await harness.request(), _response);
    await harness.request();

    expect(harness.connectedIds, [_idA]);
  });

  test('un identificador inválido avisa con su propio mensaje y no intenta conectar', () async {
    final harness = _Harness()..id = 'no-es-un-identificador';

    await expectLater(harness.request(), _unavailable(kInvalidIrohIdMessage));

    expect(harness.connectedIds, isEmpty);
  });

  test('si cambia el identificador de Ajustes, cierra la conexión vieja y abre otra', () async {
    final links = <String, _FakeLink>{};
    final harness = _Harness(connect: (id) async => links[id] = _FakeLink());

    await harness.request();
    harness.id = _idB;
    await harness.request();

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

    await expectLater(harness.request(), _unavailable('El agente no respondió a tiempo'));
    expect(links.single.closed, isTrue);

    expect(await harness.request(), _response);
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

    await expectLater(harness.request(), _unavailable('No se pudo conectar con el agente por iroh'));
    expect(await harness.request(), _response);
    expect(harness.connectedIds, [_idA, _idA]);
  });

  testWidgets('conectar tiene un límite de 5 s y la siguiente petición espera el mismo intento', (
    tester,
  ) async {
    final connecting = Completer<IrohLink>();
    final harness = _Harness(connect: (_) => connecting.future);
    final errors = <Object>[];
    String? result;

    harness.request().then<void>((_) {}, onError: errors.add);
    await tester.pump(const Duration(seconds: 4));
    expect(errors, isEmpty);
    await tester.pump(const Duration(seconds: 1));
    expect(errors.single, isA<AgentUnavailableException>());

    harness.request().then<void>((value) {
      result = value;
    }, onError: errors.add);
    await tester.pump();
    expect(harness.connectedIds, [_idA]);

    connecting.complete(_FakeLink());
    await tester.pump();

    expect(result, _response);
    expect(errors, hasLength(1));
  });

  testWidgets('la petición tiene un límite de 3 s y cierra la conexión', (tester) async {
    final link = _FakeLink(() => Completer<String>().future);
    final harness = _Harness(connect: (_) async => link);
    Object? error;
    harness.request().then<void>((_) {}, onError: (Object e) => error = e);

    await tester.pump(const Duration(seconds: 2));
    expect(error, isNull);
    await tester.pump(const Duration(seconds: 1));

    expect(error, isA<AgentUnavailableException>());
    expect(link.closed, isTrue);
  });

  testWidgets('si el intento conecta cuando ya nadie espera, la conexión se aprovecha', (tester) async {
    final connecting = Completer<IrohLink>();
    final link = _FakeLink();
    final harness = _Harness(connect: (_) => connecting.future);
    String? result;

    harness.request().then<void>((_) {}, onError: (Object _) {});
    await tester.pump(const Duration(seconds: 5));
    connecting.complete(link);
    await tester.pump();

    harness.request().then<void>((value) {
      result = value;
    });
    await tester.pump();

    expect(result, _response);
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
    String? result;

    harness.request().then<void>((_) {}, onError: (Object _) {});
    await tester.pump(const Duration(seconds: 5));

    harness.id = _idB;
    harness.request().then<void>((value) {
      result = value;
    }, onError: (Object _) {});
    await tester.pump();
    expect(harness.connectedIds, [_idA, _idB]);

    attempts[_idB]!.complete(linkB);
    await tester.pump();
    attempts[_idA]!.complete(linkA);
    await tester.pump();

    expect(result, _response);
    expect(linkA.closed, isTrue);
    expect(linkB.closed, isFalse);
  });
}
