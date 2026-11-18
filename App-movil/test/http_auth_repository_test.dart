import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sysmote/data/http/http_auth_repository.dart';
import 'package:sysmote/data/http/pinned_http_client.dart';
import 'package:sysmote/data/models/auth.dart';
import 'package:sysmote/data/repositories/auth_repository.dart';
import 'package:sysmote/data/repositories/metrics_repository.dart';

import 'fakes/in_memory_token_storage.dart';

http.Response _json(int status, Map<String, Object?> body) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  late InMemoryTokenStorage storage;
  late http.Request lastRequest;

  HttpAuthRepository repoWith(http.Response Function(http.Request) respond) {
    return HttpAuthRepository(
      () => '192.168.1.20:8443',
      () => 'a' * 64,
      storage,
      client: MockClient((request) async {
        lastRequest = request;
        return respond(request);
      }),
    );
  }

  setUp(() => storage = InMemoryTokenStorage());

  test('status() pide /estado por HTTPS y sin token', () async {
    final repo = repoWith((_) => _json(200, {
          'api': 1,
          'configurado': true,
          'registro_abierto': false,
          'sesion_activa': true,
        }));

    final status = await repo.status();

    expect(lastRequest.url.toString(), 'https://192.168.1.20:8443/estado');
    expect(lastRequest.headers.containsKey('Authorization'), isFalse);
    expect(status.configurado, isTrue);
    expect(status.registroAbierto, isFalse);
    expect(status.sesionActiva, isTrue);
  });

  test('login con 200 devuelve el token y manda usuario, contraseña y dispositivo', () async {
    final repo = repoWith((_) => _json(200, {'token': 't0k3n', 'usuario': 'alex'}));

    final outcome = await repo.login(usuario: 'alex', contrasena: 'Abcd1', dispositivo: 'Pixel 8');

    expect(outcome, isA<LoggedIn>());
    expect((outcome as LoggedIn).token, 't0k3n');
    expect(lastRequest.method, 'POST');
    expect(lastRequest.url.path, '/login');
    expect(jsonDecode(lastRequest.body), {
      'usuario': 'alex',
      'contrasena': 'Abcd1',
      'dispositivo': 'Pixel 8',
    });
  });

  test('login con 202 devuelve la solicitud pendiente', () async {
    final repo = repoWith((_) => _json(202, {
          'estado': 'pendiente',
          'solicitud': 'abc123',
          'sesion_activa_en': 'iPhone 15',
          'caduca_en_s': 300,
        }));

    final outcome = await repo.login(usuario: 'alex', contrasena: 'Abcd1', dispositivo: 'Pixel 8');

    final pending = outcome as LoginPending;
    expect(pending.solicitudId, 'abc123');
    expect(pending.sesionActivaEn, 'iPhone 15');
    expect(pending.caducaEnS, 300);
  });

  test('login con 401 credenciales_invalidas lanza InvalidCredentialsException', () async {
    final repo = repoWith((_) => _json(401, {'error': 'credenciales_invalidas', 'mensaje': 'x'}));

    expect(
      () => repo.login(usuario: 'alex', contrasena: 'mala', dispositivo: 'Pixel 8'),
      throwsA(isA<InvalidCredentialsException>()),
    );
  });

  test('login con 429 lanza TooManyAttemptsException con la espera', () async {
    final repo = repoWith((_) => _json(429, {
          'error': 'demasiados_intentos',
          'mensaje': 'x',
          'espera_s': 40,
        }));

    await expectLater(
      repo.login(usuario: 'alex', contrasena: 'Abcd1', dispositivo: 'Pixel 8'),
      throwsA(isA<TooManyAttemptsException>().having((e) => e.esperaS, 'esperaS', 40)),
    );
  });

  test('register con 201 devuelve el token', () async {
    final repo = repoWith((_) => _json(201, {'token': 't0k3n', 'usuario': 'alex'}));

    final outcome = await repo.register(
      codigo: 'K7QX-M2PD-9WTR-4HNB',
      usuario: 'alex',
      contrasena: 'Abcd1',
      dispositivo: 'Pixel 8',
    );

    expect(outcome.token, 't0k3n');
    expect(lastRequest.url.path, '/registro');
    expect(jsonDecode(lastRequest.body)['codigo'], 'K7QX-M2PD-9WTR-4HNB');
  });

  test('register traduce los tres 403 y el 422 de contraseña débil', () async {
    Future<Object?> fallo(int status, Map<String, Object?> body) async {
      final repo = repoWith((_) => _json(status, {'mensaje': 'x', ...body}));
      try {
        await repo.register(codigo: 'c', usuario: 'u', contrasena: 'p', dispositivo: 'd');
      } catch (e) {
        return e;
      }
      return null;
    }

    expect(await fallo(403, {'error': 'registro_cerrado'}), isA<RegistrationClosedException>());
    expect(await fallo(403, {'error': 'codigo_caducado'}), isA<CodeExpiredException>());
    expect(await fallo(403, {'error': 'codigo_invalido'}), isA<InvalidCodeException>());
    final debil = await fallo(422, {
      'error': 'contrasena_debil',
      'motivos': ['Mínimo 5 caracteres'],
    });
    expect((debil as WeakPasswordException).motivos, ['Mínimo 5 caracteres']);
  });

  test('checkLoginRequest traduce los cuatro estados', () async {
    Future<LoginRequestStatus> estado(Map<String, Object?> body) =>
        repoWith((_) => _json(200, body)).checkLoginRequest('abc123');

    expect(await estado({'estado': 'pendiente'}), isA<LoginRequestPending>());
    expect(await estado({'estado': 'rechazada'}), isA<LoginRequestRejected>());
    expect(await estado({'estado': 'caducada'}), isA<LoginRequestExpired>());
    final aprobada = await estado({'estado': 'aprobada', 'token': 't', 'usuario': 'alex'});
    expect((aprobada as LoginRequestApproved).token, 't');
    expect(lastRequest.url.path, '/login/solicitud/abc123');
  });

  test('session() manda el token guardado como Bearer', () async {
    await storage.write('t0k3n');
    final repo = repoWith((_) => _json(200, {
          'usuario': 'alex',
          'dispositivo': 'Pixel 8',
          'creada': '2026-12-20T18:30:00+01:00',
        }));

    final session = await repo.session();

    expect(lastRequest.headers['Authorization'], 'Bearer t0k3n');
    expect(session.dispositivo, 'Pixel 8');
    expect(session.creada.toUtc(), DateTime.utc(2026, 12, 20, 17, 30));
  });

  test('un 401 no_autenticado o desemparejado se distingue', () async {
    final noAuth = repoWith((_) => _json(401, {'error': 'no_autenticado', 'mensaje': 'x'}));
    final desemp = repoWith((_) => _json(401, {'error': 'desemparejado', 'mensaje': 'x'}));

    expect(() => noAuth.session(), throwsA(isA<NotAuthenticatedException>()));
    expect(() => desemp.session(), throwsA(isA<UnpairedException>()));
  });

  test('logout() y unpair() mandan el Bearer a su ruta y aceptan el 204', () async {
    await storage.write('t0k3n');
    final repo = repoWith((_) => http.Response('', 204));

    await repo.logout();
    expect(lastRequest.url.path, '/logout');
    expect(lastRequest.headers['Authorization'], 'Bearer t0k3n');

    await repo.unpair();
    expect(lastRequest.url.path, '/desemparejar');
  });

  test('un error 5xx sin formato conocido lanza AgentErrorException con el mensaje', () async {
    final repo = repoWith((_) => _json(500, {'error': 'error_interno', 'mensaje': 'Fallo del agente'}));

    await expectLater(
      repo.status(),
      throwsA(isA<AgentErrorException>().having((e) => e.message, 'message', 'Fallo del agente')),
    );
  });

  test('sin conexión, un JSON roto o un campo de otro tipo lanzan AgentUnavailableException', () async {
    final sinConexion = HttpAuthRepository(
      () => 'x:1',
      () => '',
      storage,
      client: MockClient((_) async => throw Exception('sin red')),
    );
    final roto = repoWith((_) => http.Response('no es json', 200));
    final tipoMalo = repoWith((_) => _json(200, {'api': 'uno'}));

    expect(() => sinConexion.status(), throwsA(isA<AgentUnavailableException>()));
    expect(() => roto.status(), throwsA(isA<AgentUnavailableException>()));
    expect(() => tipoMalo.status(), throwsA(isA<AgentUnavailableException>()));
  });

  test('un certificado que no coincide con la huella avisa de la huella', () async {
    final repo = HttpAuthRepository(
      () => 'x:1',
      () => '',
      storage,
      client: MockClient((_) async => throw const HandshakeException('CERTIFICATE_VERIFY_FAILED')),
    );

    await expectLater(
      repo.status(),
      throwsA(isA<AgentUnavailableException>().having((e) => e.message, 'message', kFingerprintMismatchMessage)),
    );
  });

  test('un timeout lanza AgentUnavailableException', () async {
    final repo = HttpAuthRepository(
      () => 'x:1',
      () => '',
      storage,
      client: MockClient((_) async {
        await Future<void>.delayed(const Duration(seconds: 5));
        return http.Response('{}', 200);
      }),
    );

    await expectLater(repo.status(), throwsA(isA<AgentUnavailableException>()));
  }, timeout: const Timeout(Duration(seconds: 10)));

  group('huella del certificado', () {
    final abc = Uint8List.fromList(utf8.encode('abc'));
    const sha256Abc = 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad';

    test('es el SHA-256 del DER en hexadecimal minúscula', () {
      expect(certificateFingerprint(abc), sha256Abc);
    });

    test('coincide sin distinguir mayúsculas ni espacios alrededor', () {
      expect(fingerprintMatches(abc, ' ${sha256Abc.toUpperCase()} '), isTrue);
    });

    test('una huella distinta o vacía no coincide', () {
      expect(fingerprintMatches(abc, 'b' * 64), isFalse);
      expect(fingerprintMatches(abc, ''), isFalse);
    });
  });
}
