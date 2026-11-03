import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sysmote/app.dart';
import 'package:sysmote/features/terminal/terminal_tabs_viewmodel.dart';
import 'package:sysmote/features/terminal/terminal_viewmodel.dart';
import 'package:xterm/xterm.dart';

import 'helpers/app_harness.dart';

void main() {
  TerminalTabsViewModel tabsOf(WidgetTester tester) => Provider.of<TerminalTabsViewModel>(
        tester.element(find.byType(SysmoteApp)),
        listen: false,
      );

  Future<TerminalViewModel> openTerminal(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Abrir menú'));
    await pumpFor(tester, 500);
    await tester.tap(find.text('Terminal'));
    await pumpFor(tester, 600);
    await tester.tap(find.text('Toca para abrir una terminal en tu PC'));
    await pumpFor(tester, 700);
    return tabsOf(tester).active;
  }

  String screen(TerminalViewModel vm) => vm.terminal.buffer.getText();

  testWidgets('empieza vacía con el aviso y pasa al prompt real al tocarla', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Abrir menú'));
    await pumpFor(tester, 500);
    await tester.tap(find.text('Terminal'));
    await pumpFor(tester, 600);

    expect(find.text('Toca para abrir una terminal en tu PC'), findsOneWidget);

    await tester.tap(find.text('Toca para abrir una terminal en tu PC'));
    await tester.pump();

    expect(find.text('Abriendo terminal…'), findsOneWidget);

    await pumpFor(tester, 700);

    expect(find.text('Toca para abrir una terminal en tu PC'), findsNothing);
    expect(find.text('Abriendo terminal…'), findsNothing);
  });

  testWidgets('las teclas escritas mientras se crea la sesión no se pierden', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Abrir menú'));
    await pumpFor(tester, 500);
    await tester.tap(find.text('Terminal'));
    await pumpFor(tester, 600);

    await tester.tap(find.text('Toca para abrir una terminal en tu PC'));
    await tester.pump();
    final vm = tabsOf(tester).active;
    vm.terminal.textInput('whoami\r');
    await pumpFor(tester, 700);

    expect(screen(vm), contains('whoami'));
    expect(screen(vm), contains('usuario\n'));
  });

  testWidgets('escribir exit cierra la pestaña y vuelve al aviso', (tester) async {
    final vm = await openTerminal(tester);

    vm.terminal.textInput('exit\r');
    await pumpFor(tester, 200);

    expect(vm.state, TerminalSessionState.empty);
    expect(tabsOf(tester).tabs, isEmpty);
    expect(find.text('Toca para abrir una terminal en tu PC'), findsOneWidget);
  });

  testWidgets('muestra el mensaje de conexión y el prompt', (tester) async {
    final vm = await openTerminal(tester);

    expect(screen(vm), contains('Conectado a pc mediante el agente.'));
    expect(screen(vm), contains(r'usuario@pc:~$'));
  });

  testWidgets('ejecuta un comando y muestra su salida', (tester) async {
    final vm = await openTerminal(tester);

    vm.terminal.textInput('whoami\r');
    await pumpFor(tester, 200);

    expect(screen(vm), contains('whoami'));
    expect(screen(vm), contains('usuario\n'));
  });

  testWidgets('un comando desconocido da error', (tester) async {
    final vm = await openTerminal(tester);

    vm.terminal.textInput('foo\r');
    await pumpFor(tester, 200);

    expect(screen(vm), contains('bash: foo: orden no encontrada'));
  });

  testWidgets('la flecha arriba recupera el comando anterior', (tester) async {
    final vm = await openTerminal(tester);

    vm.terminal.textInput('echo hola\r');
    await pumpFor(tester, 200);
    vm.pressKey(TerminalKey.arrowUp);
    await pumpFor(tester, 200);

    expect(screen(vm).trimRight().split('\n').last, endsWith('echo hola'));
  });

  testWidgets('CTRL + c cancela la línea', (tester) async {
    final vm = await openTerminal(tester);

    vm.terminal.textInput('sleep 10');
    vm.toggleCtrl();
    expect(vm.ctrl, isTrue);
    vm.terminal.textInput('c');
    await pumpFor(tester, 200);

    expect(vm.ctrl, isFalse);
    expect(screen(vm), contains('^C'));
  });

  testWidgets('clear limpia la pantalla', (tester) async {
    final vm = await openTerminal(tester);

    vm.terminal.textInput('clear\r');
    await pumpFor(tester, 200);

    expect(screen(vm), isNot(contains('Conectado a pc')));
  });

  testWidgets('el botón + abre una pestaña nueva ya lista', (tester) async {
    await openTerminal(tester);

    await tester.tap(find.bySemanticsLabel('Nueva pestaña'));
    await pumpFor(tester, 700);

    final tabs = tabsOf(tester);
    expect(tabs.tabs, hasLength(2));
    expect(tabs.activeIndex, 1);
    expect(find.text('Terminal 1'), findsOneWidget);
    expect(find.text('Terminal 2'), findsOneWidget);
  });

  testWidgets('tocar una pestaña la activa', (tester) async {
    await openTerminal(tester);
    await tester.tap(find.bySemanticsLabel('Nueva pestaña'));
    await pumpFor(tester, 700);

    await tester.tap(find.text('Terminal 1'));
    await tester.pump();

    expect(tabsOf(tester).activeIndex, 0);
  });

  testWidgets('cerrar una pestaña pide confirmación', (tester) async {
    await openTerminal(tester);

    await tester.tap(find.bySemanticsLabel('Cerrar Terminal 1'));
    await pumpFor(tester, 200);
    expect(find.text('¿Cerrar esta pestaña?'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await pumpFor(tester, 200);
    expect(tabsOf(tester).tabs, hasLength(1));

    await tester.tap(find.bySemanticsLabel('Cerrar Terminal 1'));
    await pumpFor(tester, 200);
    await tester.tap(find.text('Cerrar'));
    await pumpFor(tester, 200);

    expect(tabsOf(tester).tabs, isEmpty);
    expect(find.text('Toca para abrir una terminal en tu PC'), findsOneWidget);
  });

  testWidgets('no deja abrir más de 6 pestañas', (tester) async {
    await openTerminal(tester);
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.bySemanticsLabel('Nueva pestaña'));
      await pumpFor(tester, 700);
    }
    expect(tabsOf(tester).tabs, hasLength(6));

    await tester.tap(find.bySemanticsLabel('Nueva pestaña'));
    await tester.pump();

    expect(tabsOf(tester).tabs, hasLength(6));
    expect(find.text('No caben más pestañas'), findsOneWidget);
  });

  testWidgets('cerrar una pestaña mientras se crea la sesión no falla', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Abrir menú'));
    await pumpFor(tester, 500);
    await tester.tap(find.text('Terminal'));
    await pumpFor(tester, 600);
    await tester.tap(find.text('Toca para abrir una terminal en tu PC'));
    await tester.pump();

    expect(tabsOf(tester).active.state, TerminalSessionState.creating);

    await tester.tap(find.bySemanticsLabel('Cerrar Terminal 1'));
    await pumpFor(tester, 200);
    await tester.tap(find.text('Cerrar'));
    await pumpFor(tester, 700);

    expect(tester.takeException(), isNull);
    expect(tabsOf(tester).tabs, isEmpty);
  });

  testWidgets('cerrar una pestaña por instancia no cierra la equivocada', (tester) async {
    await openTerminal(tester);
    final tabs = tabsOf(tester);
    final tab1 = tabs.tabs[0];

    tabs.addTab();
    await pumpFor(tester, 700);
    tabs.addTab();
    await pumpFor(tester, 700);
    final tab3 = tabs.tabs[2];

    // Se cierra la pestaña 1 (índice 0): tab3 pasa de índice 2 a 1.
    tabs.closeTab(tab1);
    await tester.pump();
    expect(tabs.tabs, hasLength(2));
    expect(tabs.tabs.contains(tab3), isTrue);

    // "Cerrar" tab3 por instancia, aunque su índice cambiara mientras tanto.
    tabs.closeTab(tab3);
    await tester.pump();

    expect(tabs.tabs.contains(tab3), isFalse);
    expect(tabs.tabs, hasLength(1));
  });
}
