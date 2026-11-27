// Tests de que los botones flotantes y la papelera quedan por encima de la barra de navegación del
// sistema.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_harness.dart';

void main() {
  const bar = 48.0;

  Future<void> withNavigationBar(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    tester.view.padding = const FakeViewPadding(bottom: bar * 3);
    tester.view.viewPadding = const FakeViewPadding(bottom: bar * 3);
    addTearDown(tester.view.reset);
    await startApp(tester);
    await tester.pumpAndSettle();
  }

  testWidgets('el botón de añadir macro queda por encima de la barra', (tester) async {
    await withNavigationBar(tester);

    final bottom = tester.getBottomLeft(find.bySemanticsLabel('Añadir macro')).dy;

    expect(bottom, lessThanOrEqualTo(844 - bar - 28 + 0.5));
  });

  testWidgets('el botón de nueva nota queda por encima de la barra', (tester) async {
    await withNavigationBar(tester);
    await tester.tap(find.bySemanticsLabel('Abrir menú'));
    await pumpFor(tester, 500);
    await tester.tap(find.text('Notas'));
    await pumpFor(tester, 600);

    final bottom = tester.getBottomLeft(find.bySemanticsLabel('Nueva nota')).dy;

    expect(bottom, lessThanOrEqualTo(844 - bar - 28 + 0.5));
  });

  testWidgets('la papelera sube con la barra y sigue funcionando', (tester) async {
    await withNavigationBar(tester);

    final gesture = await tester.startGesture(const Offset(103, 171));
    await tester.pump(const Duration(milliseconds: 450));
    await gesture.moveTo(const Offset(195, 64 + 708 - bar));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('Silenciar'), findsNothing);
  });
}
