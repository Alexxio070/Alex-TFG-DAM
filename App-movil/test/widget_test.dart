import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tfg/app.dart';
import 'package:tfg/data/fake/fake_macro_repository.dart';
import 'package:tfg/data/fake/fake_metrics_repository.dart';
import 'package:tfg/data/fake/fake_pairing_repository.dart';
import 'package:tfg/data/repositories/macro_repository.dart';
import 'package:tfg/data/repositories/metrics_repository.dart';
import 'package:tfg/data/repositories/pairing_repository.dart';
import 'package:tfg/features/home/home_viewmodel.dart';
import 'package:tfg/features/metrics/metrics_viewmodel.dart';
import 'package:tfg/features/settings/settings_viewmodel.dart';
import 'package:tfg/features/shell/shell_viewmodel.dart';

Widget _app() => MultiProvider(
      providers: [
        Provider<PairingRepository>(create: (_) => FakePairingRepository()),
        Provider<MacroRepository>(create: (_) => FakeMacroRepository()),
        Provider<MetricsRepository>(create: (_) => FakeMetricsRepository()),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        ChangeNotifierProvider(
          create: (context) => ShellViewModel(context.read<PairingRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => HomeViewModel(context.read<MacroRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => MetricsViewModel(context.read<MetricsRepository>()),
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

  group('Métricas', () {
    Future<void> openMetrics(WidgetTester tester) async {
      tester.view.physicalSize = const Size(700 * 3, 1400 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app());
      await tester.tap(find.bySemanticsLabel('Abrir menú'));
      await _pumpFor(tester, 500);
      await tester.tap(find.text('Métricas'));
      await _pumpFor(tester, 600);
    }

    Future<void> closeApp(WidgetTester tester) => tester.pumpWidget(const SizedBox());

    testWidgets('muestra las cuatro tarjetas con la partición del sistema', (tester) async {
      await openMetrics(tester);

      expect(find.text('Uso de CPU'), findsOneWidget);
      expect(find.text('Temperatura de CPU'), findsOneWidget);
      expect(find.text('Uso de RAM'), findsOneWidget);
      expect(find.text('Uso de disco'), findsOneWidget);
      expect(find.text('/'), findsOneWidget);
      await closeApp(tester);
    });

    testWidgets('cambia de partición desde el selector', (tester) async {
      await openMetrics(tester);

      await tester.tap(find.text('/'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('/mnt/datos'), findsOneWidget);

      await tester.tap(find.text('/home'));
      await _pumpFor(tester, 300);

      expect(find.text('/mnt/datos'), findsNothing);
      expect(find.text('/home'), findsOneWidget);
      await closeApp(tester);
    });

    testWidgets('mantener pulsada la tarjeta de disco abre las particiones', (tester) async {
      await openMetrics(tester);

      final gesture = await tester.startGesture(tester.getCenter(find.text('Uso de disco')));
      await tester.pump(const Duration(milliseconds: 1100));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('/mnt/datos'), findsOneWidget);
      await closeApp(tester);
    });

    testWidgets('muestra temperatura en Fahrenheit y GiB según ajustes', (tester) async {
      await openMetrics(tester);
      final settings = Provider.of<SettingsViewModel>(
        tester.element(find.byType(TfgApp)),
        listen: false,
      );

      settings.setTempUnit(TempUnit.fahrenheit);
      settings.setStorageUnit(StorageUnit.gib);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Escala 86–212 °F'), findsOneWidget);
      expect(find.textContaining('GiB'), findsWidgets);
      await closeApp(tester);
    });
  });
}
