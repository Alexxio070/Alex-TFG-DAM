import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_harness.dart';

void main() {
  testWidgets('arranca en Inicio con el drawer cerrado', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump();

    expect(find.text('Inicio'), findsWidgets);
    expect(find.text('Conectado'), findsNothing);
  });

  testWidgets('el drawer cambia de sección y se cierra', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('Abrir menú'));
    await tester.pumpAndSettle();
    expect(find.text('Conectado'), findsOneWidget);

    await tester.tap(find.text('Métricas'));
    await pumpFor(tester, 500);

    expect(find.text('Conectado'), findsNothing);
    expect(find.text('Métricas'), findsWidgets);
  });

  testWidgets('el engranaje abre Ajustes', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('Abrir menú'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Ajustes'));
    await tester.pumpAndSettle();

    expect(find.text('Ajustes'), findsWidgets);
  });

  testWidgets('el drawer se abre arrastrando desde el borde izquierdo', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump();
    expect(find.text('Conectado'), findsNothing);

    await tester.dragFrom(const Offset(8, 300), const Offset(250, 0));
    await tester.pumpAndSettle();

    expect(find.text('Conectado'), findsOneWidget);
  });

  testWidgets('un arrastre corto desde el borde deja el drawer cerrado', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump();

    await tester.dragFrom(const Offset(8, 300), const Offset(60, 0));
    await tester.pumpAndSettle();

    expect(find.text('Conectado'), findsNothing);
  });

  testWidgets('el drawer se cierra arrastrando hacia la izquierda', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Abrir menú'));
    await tester.pumpAndSettle();
    expect(find.text('Conectado'), findsOneWidget);

    await tester.dragFrom(const Offset(250, 300), const Offset(-200, 0));
    await tester.pumpAndSettle();

    expect(find.text('Conectado'), findsNothing);
  });
}
