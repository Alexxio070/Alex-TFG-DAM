// Tests del doble FakeAuthRepository: que simula fielmente el contrato de login de la fase 3,
// porque los demás tests de login dependen de él.

import 'package:flutter_test/flutter_test.dart';
import 'package:sysmote/data/models/auth.dart';
import 'package:sysmote/data/repositories/agent_exceptions.dart';
import 'package:sysmote/data/repositories/auth_repository.dart';

import 'fakes/fake_auth_repository.dart';

void main() {
  test('status() refleja configurado, registroAbierto y sesionActiva', () async {
    final repo = FakeAuthRepository(configurado: false, registroAbierto: true);

    final status = await repo.status();

    expect(status.api, 1);
    expect(status.configurado, isFalse);
    expect(status.registroAbierto, isTrue);
    expect(status.sesionActiva, isFalse);
  });

  test('login con credenciales correctas abre sesión directamente', () async {
    final repo = FakeAuthRepository();

    final outcome = await repo.login(
      usuario: 'alex',
      contrasena: 'contraseña-valida',
      dispositivo: 'Pixel 8',
    );

    expect(outcome, isA<LoggedIn>());
    expect((outcome as LoggedIn).usuario, 'alex');
    expect((await repo.status()).sesionActiva, isTrue);
  });

  test('login con credenciales incorrectas lanza InvalidCredentialsException', () async {
    final repo = FakeAuthRepository();

    expect(
      () => repo.login(usuario: 'alex', contrasena: 'mala', dispositivo: 'Pixel 8'),
      throwsA(isA<InvalidCredentialsException>()),
    );
  });

  test('login bloqueado lanza TooManyAttemptsException', () async {
    final repo = FakeAuthRepository()..bloqueadoPor = TooManyAttemptsException(40);

    expect(
      () => repo.login(usuario: 'alex', contrasena: 'contraseña-valida', dispositivo: 'Pixel 8'),
      throwsA(isA<TooManyAttemptsException>()),
    );
  });

  Future<void> fallar(FakeAuthRepository repo, int veces) async {
    for (var i = 0; i < veces; i++) {
      await expectLater(
        repo.login(usuario: 'alex', contrasena: 'mala', dispositivo: 'Pixel 8'),
        throwsA(isA<InvalidCredentialsException>()),
      );
    }
  }

  test('el 5.º fallo todavía da 401 y el 6.º intento ya recibe 429', () async {
    final repo = FakeAuthRepository(bloqueoS: 120);

    await fallar(repo, 5);

    await expectLater(
      repo.login(usuario: 'alex', contrasena: 'contraseña-valida', dispositivo: 'Pixel 8'),
      throwsA(isA<TooManyAttemptsException>().having((e) => e.esperaS, 'esperaS', 120)),
    );
  });

  test('un login correcto pone a cero el contador de fallos', () async {
    final repo = FakeAuthRepository();
    await fallar(repo, 4);
    await repo.login(usuario: 'alex', contrasena: 'contraseña-valida', dispositivo: 'Pixel 8');

    await fallar(repo, 4);

    expect(
      await repo.login(usuario: 'alex', contrasena: 'contraseña-valida', dispositivo: 'Pixel 8'),
      isA<LoggedIn>(),
    );
  });

  test('intentosPermitidos cambia cuántos fallos aguanta el agente', () async {
    final repo = FakeAuthRepository(intentosPermitidos: 2);

    await fallar(repo, 2);

    await expectLater(
      repo.login(usuario: 'alex', contrasena: 'contraseña-valida', dispositivo: 'Pixel 8'),
      throwsA(isA<TooManyAttemptsException>()),
    );
  });

  test('levantarBloqueo() deja volver a entrar', () async {
    final repo = FakeAuthRepository(intentosPermitidos: 1);
    await fallar(repo, 1);

    repo.levantarBloqueo();

    expect(
      await repo.login(usuario: 'alex', contrasena: 'contraseña-valida', dispositivo: 'Pixel 8'),
      isA<LoggedIn>(),
    );
  });

  test('login con una sesión ya activa crea una solicitud pendiente', () async {
    final repo = FakeAuthRepository()..sesionActivaEnDispositivo = 'iPhone 15';

    final outcome = await repo.login(
      usuario: 'alex',
      contrasena: 'contraseña-valida',
      dispositivo: 'Pixel 8',
    );

    expect(outcome, isA<LoginPending>());
    final pending = outcome as LoginPending;
    expect(pending.sesionActivaEn, 'iPhone 15');
    expect(pending.caducaEnS, 300);
    expect(await repo.checkLoginRequest(pending.solicitudId), isA<LoginRequestPending>());
  });

  test('approvePending() aprueba la solicitud y entrega el token', () async {
    final repo = FakeAuthRepository()..sesionActivaEnDispositivo = 'iPhone 15';
    final pending = await repo.login(
          usuario: 'alex',
          contrasena: 'contraseña-valida',
          dispositivo: 'Pixel 8',
        )
        as LoginPending;

    repo.approvePending();

    final status = await repo.checkLoginRequest(pending.solicitudId);
    expect(status, isA<LoginRequestApproved>());
    expect((status as LoginRequestApproved).usuario, 'alex');
    expect((await repo.session()).dispositivo, 'Pixel 8');
  });

  test('rejectPending() deja la sesión anterior intacta', () async {
    final repo = FakeAuthRepository()..sesionActivaEnDispositivo = 'iPhone 15';
    final pending = await repo.login(
          usuario: 'alex',
          contrasena: 'contraseña-valida',
          dispositivo: 'Pixel 8',
        )
        as LoginPending;

    repo.rejectPending();

    expect(await repo.checkLoginRequest(pending.solicitudId), isA<LoginRequestRejected>());
    expect(() => repo.session(), throwsA(isA<NotAuthenticatedException>()));
  });

  test('expirePending() marca la solicitud como caducada', () async {
    final repo = FakeAuthRepository()..sesionActivaEnDispositivo = 'iPhone 15';
    final pending = await repo.login(
          usuario: 'alex',
          contrasena: 'contraseña-valida',
          dispositivo: 'Pixel 8',
        )
        as LoginPending;

    repo.expirePending();

    expect(await repo.checkLoginRequest(pending.solicitudId), isA<LoginRequestExpired>());
  });

  test('checkLoginRequest con un id desconocido lanza AgentErrorException', () async {
    final repo = FakeAuthRepository();

    expect(
      () => repo.checkLoginRequest('no-existe'),
      throwsA(isA<AgentErrorException>()),
    );
  });

  FakeAuthRepository sinCuenta({bool caducado = false}) => FakeAuthRepository(
        configurado: false,
        registroAbierto: true,
        codigoRegistro: 'K7QXM2PD9WTR4HNB',
        codigoCaducado: caducado,
      );

  test('register con un código vigente crea la cuenta y abre sesión', () async {
    final repo = sinCuenta();

    final outcome = await repo.register(
      codigo: 'k7qx-m2pd-9wtr-4hnb',
      usuario: 'alex',
      contrasena: 'Abcd1',
      dispositivo: 'Pixel 8',
    );

    expect(outcome.usuario, 'alex');
    final status = await repo.status();
    expect(status.configurado, isTrue);
    expect(status.registroAbierto, isFalse);
    expect((await repo.session()).dispositivo, 'Pixel 8');
  });

  test('register acepta 0 y 1 en lugar de O e I', () async {
    final repo = FakeAuthRepository(
      configurado: false,
      registroAbierto: true,
      codigoRegistro: 'K7QX012PD9WTR4HN',
    );

    final outcome = await repo.register(
      codigo: 'K7QXOI2PD9WTR4HN',
      usuario: 'alex',
      contrasena: 'Abcd1',
      dispositivo: 'Pixel 8',
    );

    expect(outcome, isA<LoggedIn>());
  });

  test('register con una cuenta ya creada lanza RegistrationClosedException', () async {
    final repo = FakeAuthRepository(codigoRegistro: 'K7QXM2PD9WTR4HNB');

    expect(
      () => repo.register(
        codigo: 'K7QXM2PD9WTR4HNB',
        usuario: 'alex',
        contrasena: 'Abcd1',
        dispositivo: 'Pixel 8',
      ),
      throwsA(isA<RegistrationClosedException>()),
    );
  });

  test('register sin haber abierto nunca el registro lanza RegistrationClosedException', () async {
    final repo = FakeAuthRepository(configurado: false);

    expect(
      () => repo.register(
        codigo: 'K7QXM2PD9WTR4HNB',
        usuario: 'alex',
        contrasena: 'Abcd1',
        dispositivo: 'Pixel 8',
      ),
      throwsA(isA<RegistrationClosedException>()),
    );
  });

  test('register con un código distinto lanza InvalidCodeException', () async {
    final repo = sinCuenta();

    expect(
      () => repo.register(
        codigo: 'AAAA-AAAA-AAAA-AAAA',
        usuario: 'alex',
        contrasena: 'Abcd1',
        dispositivo: 'Pixel 8',
      ),
      throwsA(isA<InvalidCodeException>()),
    );
  });

  test('register con un código caducado lanza CodeExpiredException', () async {
    final repo = sinCuenta(caducado: true);

    expect(
      () => repo.register(
        codigo: 'K7QXM2PD9WTR4HNB',
        usuario: 'alex',
        contrasena: 'Abcd1',
        dispositivo: 'Pixel 8',
      ),
      throwsA(isA<CodeExpiredException>()),
    );
  });

  test('register con una contraseña débil lanza WeakPasswordException con los motivos', () async {
    final repo = sinCuenta();

    await expectLater(
      repo.register(
        codigo: 'K7QXM2PD9WTR4HNB',
        usuario: 'alex',
        contrasena: 'abc',
        dispositivo: 'Pixel 8',
      ),
      throwsA(
        isA<WeakPasswordException>().having((e) => e.motivos, 'motivos', hasLength(3)),
      ),
    );
    expect((await repo.status()).configurado, isFalse);
  });

  test('session() sin haber iniciado sesión lanza NotAuthenticatedException', () async {
    final repo = FakeAuthRepository();

    expect(() => repo.session(), throwsA(isA<NotAuthenticatedException>()));
  });

  test('logout() y unpair() cierran la sesión', () async {
    final repo = FakeAuthRepository();
    await repo.login(usuario: 'alex', contrasena: 'contraseña-valida', dispositivo: 'Pixel 8');

    await repo.logout();

    expect(repo.logoutCalls, 1);
    expect(() => repo.session(), throwsA(isA<NotAuthenticatedException>()));

    await repo.login(usuario: 'alex', contrasena: 'contraseña-valida', dispositivo: 'Pixel 8');
    await repo.unpair();

    expect(repo.unpairCalls, 1);
    expect(() => repo.session(), throwsA(isA<NotAuthenticatedException>()));
  });
}
