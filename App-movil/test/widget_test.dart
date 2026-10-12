import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tfg/app.dart';
import 'package:tfg/data/fake/fake_macro_repository.dart';
import 'package:tfg/data/fake/fake_pairing_repository.dart';
import 'package:tfg/data/repositories/macro_repository.dart';
import 'package:tfg/data/repositories/pairing_repository.dart';
import 'package:tfg/features/home/home_viewmodel.dart';
import 'package:tfg/features/settings/settings_viewmodel.dart';
import 'package:tfg/features/shell/shell_viewmodel.dart';

Widget _app() => MultiProvider(
      providers: [
        Provider<PairingRepository>(create: (_) => FakePairingRepository()),
        Provider<MacroRepository>(create: (_) => FakeMacroRepository()),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        ChangeNotifierProvider(
          create: (context) => ShellViewModel(context.read<PairingRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => HomeViewModel(context.read<MacroRepository>()),
        ),
      ],
      child: const TfgApp(),
    );

Future<void> _pumpFor(WidgetTester tester, int milliseconds) async {
  for (var elapsed = 0; elapsed < milliseconds; elapsed += 100) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('arranca en Inicio con el drawer cerrado', (tester) async {
    await tester.pumpWidget(_app());

    expect(find.text('Inicio'), findsWidgets);
    expect(find.text('Conectado'), findsNothing);
  });

  testWidgets('el drawer cambia de sección y se cierra', (tester) async {
    await tester.pumpWidget(_app());

    await tester.tap(find.bySemanticsLabel('Abrir menú'));
    await tester.pumpAndSettle();
    expect(find.text('Conectado'), findsOneWidget);

    await tester.tap(find.text('Métricas'));
    await _pumpFor(tester, 500);

    expect(find.text('Conectado'), findsNothing);
    expect(find.text('Métricas'), findsWidgets);
  });

  testWidgets('el engranaje abre Ajustes', (tester) async {
    await tester.pumpWidget(_app());

    await tester.tap(find.bySemanticsLabel('Abrir menú'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Ajustes'));
    await tester.pumpAndSettle();

    expect(find.text('Ajustes'), findsWidgets);
  });

  group('Inicio', () {
    Future<void> pumpHome(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
    }

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

    testWidgets('arrastrar una macro a la papelera la elimina', (tester) async {
      await pumpHome(tester);

      final gesture = await tester.startGesture(const Offset(103, 171));
      await tester.pump(const Duration(milliseconds: 450));
      await gesture.moveTo(const Offset(195, 64 + 708));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('Silenciar'), findsNothing);
    });

    testWidgets('soltar una macro sobre otra crea una carpeta', (tester) async {
      await pumpHome(tester);

      final gesture = await tester.startGesture(const Offset(103, 171));
      await tester.pump(const Duration(milliseconds: 450));
      await gesture.moveTo(const Offset(287, 171));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('Carpeta'), findsOneWidget);
      expect(find.text('2 macros'), findsOneWidget);
    });
  });
}
