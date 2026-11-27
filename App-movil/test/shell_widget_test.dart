// Tests de la estructura de la app: menú lateral, navegación y paso entre login y app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_auth_repository.dart';
import 'helpers/app_harness.dart';

void main() {
  testWidgets('arranca en Inicio con el drawer cerrado', (tester) async {
    await startApp(tester);

    expect(find.text('Inicio'), findsWidgets);
    expect(find.text('Conectado'), findsNothing);
  });

  testWidgets('el drawer cambia de sección y se cierra', (tester) async {
    await startApp(tester);

    await tester.tap(find.bySemanticsLabel('Abrir menú'));
    await tester.pumpAndSettle();
    expect(find.text('Conectado'), findsOneWidget);

    await tester.tap(find.text('Métricas'));
    await pumpFor(tester, 500);

    expect(find.text('Conectado'), findsNothing);
    expect(find.text('Métricas'), findsWidgets);
  });

  testWidgets('el engranaje abre Ajustes', (tester) async {
    await startApp(tester);

    await tester.tap(find.bySemanticsLabel('Abrir menú'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Ajustes'));
    await tester.pumpAndSettle();

    expect(find.text('Ajustes'), findsWidgets);
  });

  testWidgets('el drawer se abre arrastrando desde el borde izquierdo', (tester) async {
    await startApp(tester);
    expect(find.text('Conectado'), findsNothing);

    await tester.dragFrom(const Offset(8, 300), const Offset(250, 0));
    await tester.pumpAndSettle();

    expect(find.text('Conectado'), findsOneWidget);
  });

  testWidgets('un arrastre corto desde el borde deja el drawer cerrado', (tester) async {
    await startApp(tester);

    await tester.dragFrom(const Offset(8, 300), const Offset(60, 0));
    await tester.pumpAndSettle();

    expect(find.text('Conectado'), findsNothing);
  });

  testWidgets('el drawer se cierra arrastrando hacia la izquierda', (tester) async {
    await startApp(tester);
    await tester.tap(find.bySemanticsLabel('Abrir menú'));
    await tester.pumpAndSettle();
    expect(find.text('Conectado'), findsOneWidget);

    await tester.dragFrom(const Offset(250, 300), const Offset(-200, 0));
    await tester.pumpAndSettle();

    expect(find.text('Conectado'), findsNothing);
  });

  testWidgets('sin sesión, la app solo muestra el login', (tester) async {
    await startApp(tester, app(authRepository: FakeAuthRepository()));

    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.bySemanticsLabel('Abrir menú'), findsNothing);
  });

  testWidgets('al iniciar sesión pasa a la app y al cerrarla vuelve al login', (tester) async {
    await startApp(tester, app(authRepository: FakeAuthRepository()));
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pump();
    await tester.pump();

    await tester.enterText(find.byType(TextField).at(0), 'alex');
    await tester.enterText(find.byType(TextField).at(1), 'contraseña-valida');
    await tester.enterText(find.byType(TextField).at(2), 'Pixel 8');
    await tester.tap(find.text('Entrar'));
    await tester.pump();
    await tester.pump();

    expect(find.bySemanticsLabel('Abrir menú'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Abrir menú'));
    await pumpFor(tester, 500);
    await tester.tap(find.bySemanticsLabel('Ajustes'));
    await pumpFor(tester, 600);
    await tester.drag(find.byType(ListView).first, const Offset(0, -3000));
    await pumpFor(tester, 300);
    await tester.tap(find.text('Cerrar sesión'));
    await pumpFor(tester, 300);

    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}
