// Tests de la pantalla de Inicio: ejecutar y crear macros, y arrastrar a carpetas y a la papelera.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sysmote/features/home/widgets/item_tile.dart';
import 'package:sysmote/features/home/widgets/trash_indicator.dart';

import 'helpers/app_harness.dart';

void main() {
  Future<void> pumpHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.pumpAndSettle();
  }

  Offset tileCenter(WidgetTester tester, String label) =>
      tester.getCenter(find.ancestor(of: find.text(label), matching: find.byType(ItemTile)).first);

  Offset trashCenter(WidgetTester tester) => tester.getCenter(find.byType(TrashIndicator));

  // Mantiene pulsada la ficha [label] hasta levantarla y la suelta en [target],
  // que se calcula ya con el arrastre en marcha (la papelera solo aparece entonces).
  Future<void> dragTile(WidgetTester tester, String label, Offset Function() target) async {
    final gesture = await tester.startGesture(tileCenter(tester, label));
    await tester.pump(const Duration(milliseconds: 450));
    await gesture.moveTo(target());
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
  }

  Future<void> makeFolder(WidgetTester tester) =>
      dragTile(tester, 'Silenciar', () => tileCenter(tester, 'Bloquear'));

  Future<void> dragFolderToTrash(WidgetTester tester) =>
      dragTile(tester, 'Carpeta', () => trashCenter(tester));

  testWidgets('muestra las macros y ejecuta una al tocarla', (tester) async {
    await pumpHome(tester);

    expect(find.text('Silenciar'), findsOneWidget);
    await tester.tap(find.text('Silenciar'));
    await tester.pump();

    expect(find.text('Ejecutando «Silenciar»'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });

  testWidgets('crea una macro desde el botón añadir', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.bySemanticsLabel('Añadir macro'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Reiniciar');
    await tester.enterText(find.byType(TextField).at(1), 'systemctl reboot');
    await tester.pump();
    await tester.tap(find.text('Crear'));
    await tester.pumpAndSettle();

    expect(find.text('Reiniciar'), findsOneWidget);
  });

  testWidgets('no deja crear una macro con un nombre repetido', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.bySemanticsLabel('Añadir macro'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Silenciar');
    await tester.enterText(find.byType(TextField).at(1), 'otro comando');
    await tester.pump();

    expect(find.text('Ya hay un elemento con ese nombre'), findsOneWidget);

    await tester.tap(find.text('Crear'));
    await tester.pumpAndSettle();

    expect(find.text('Nueva macro'), findsOneWidget);
  });

  testWidgets('elige un icono para la macro nueva', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.bySemanticsLabel('Añadir macro'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Modo avión');
    await tester.enterText(find.byType(TextField).at(1), 'nmcli radio all off');
    await tester.tap(find.bySemanticsLabel('Candado'));
    await tester.pump();
    await tester.tap(find.text('Crear'));
    await tester.pumpAndSettle();

    expect(find.text('Modo avión'), findsOneWidget);
  });

  testWidgets('arrastrar una macro a la papelera la elimina', (tester) async {
    await pumpHome(tester);

    await dragTile(tester, 'Silenciar', () => trashCenter(tester));

    expect(find.text('Silenciar'), findsNothing);
  });

  testWidgets('soltar una macro sobre otra crea una carpeta', (tester) async {
    await pumpHome(tester);

    await makeFolder(tester);

    expect(find.text('Carpeta'), findsOneWidget);
    expect(find.text('2 macros'), findsOneWidget);
  });

  testWidgets('arrastrar una carpeta con macros a la papelera pregunta qué hacer', (tester) async {
    await pumpHome(tester);
    await makeFolder(tester);

    await dragFolderToTrash(tester);

    expect(find.text('¿Qué hacer con «Carpeta»?'), findsOneWidget);
    expect(find.text('Tiene 2 macros dentro.'), findsOneWidget);
  });

  testWidgets('mover a Sin grupo deshace la carpeta y conserva las macros', (tester) async {
    await pumpHome(tester);
    await makeFolder(tester);

    await dragFolderToTrash(tester);
    await tester.tap(find.text('Mover a Sin grupo'));
    await tester.pumpAndSettle();

    expect(find.text('Carpeta'), findsNothing);
    expect(find.text('Silenciar'), findsOneWidget);
    expect(find.text('Bloquear'), findsOneWidget);
  });

  testWidgets('borrar en el diálogo elimina la carpeta y sus macros', (tester) async {
    await pumpHome(tester);
    await makeFolder(tester);

    await dragFolderToTrash(tester);
    await tester.tap(find.text('Borrar'));
    await tester.pumpAndSettle();

    expect(find.text('Carpeta'), findsNothing);
    expect(find.text('Silenciar'), findsNothing);
    expect(find.text('Bloquear'), findsNothing);
  });
}
