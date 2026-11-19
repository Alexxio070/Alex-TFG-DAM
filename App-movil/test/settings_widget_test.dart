// Tests de la pantalla de Ajustes: unidades, límites, tema, acento, conexión y desemparejar.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sysmote/app.dart';
import 'package:sysmote/core/theme/app_tokens.dart';
import 'package:sysmote/features/settings/settings_viewmodel.dart';

import 'helpers/app_harness.dart';

void main() {
  final validIrohId = 'a' * 64;
  final validFingerprint = 'b' * 64;
  late SettingsViewModel settings;

  Future<void> openSettings(WidgetTester tester) async {
    await openSection(tester, 'Ajustes', size: const Size(390, 1600));
    settings = Provider.of<SettingsViewModel>(
      tester.element(find.byType(SysmoteApp)),
      listen: false,
    );
  }

  testWidgets('muestra todos los grupos', (tester) async {
    await openSettings(tester);

    for (final title in ['Unidades', 'Métricas', 'Terminal', 'Apariencia', 'Dispositivo']) {
      expect(find.text(title), findsWidgets);
    }
    expect(find.text('Este móvil tiene una sesión abierta con el PC.'), findsOneWidget);
  });

  testWidgets('cambia las unidades de temperatura y almacenamiento', (tester) async {
    await openSettings(tester);

    await tester.tap(find.text('°F'));
    await tester.tap(find.text('GiB'));
    await tester.pump();

    expect(settings.tempUnit, TempUnit.fahrenheit);
    expect(settings.storageUnit, StorageUnit.gib);
    expect(find.text('185 °F'), findsOneWidget);
  });

  testWidgets('la alerta oculta y muestra el límite y lo cambia de 5 en 5', (tester) async {
    await openSettings(tester);
    expect(find.text('85 °C'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Subir límite'));
    await tester.pump();
    expect(settings.tempLimit, 90);

    await tester.tap(find.bySemanticsLabel('Alerta de temperatura').first);
    await tester.pump();
    expect(settings.tempAlert, isFalse);
    expect(find.text('Límite'), findsNothing);
  });

  testWidgets('el límite no sale de 60–95', (tester) async {
    await openSettings(tester);

    for (var i = 0; i < 10; i++) {
      await tester.tap(find.bySemanticsLabel('Subir límite'));
    }
    await tester.pump();
    expect(settings.tempLimit, 95);
  });

  testWidgets('el tamaño de fuente cambia dentro de 10–22', (tester) async {
    await openSettings(tester);
    expect(find.text('13 px'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Aumentar fuente'));
    await tester.pump();
    expect(find.text('14 px'), findsOneWidget);

    for (var i = 0; i < 20; i++) {
      await tester.tap(find.bySemanticsLabel('Reducir fuente'));
    }
    await tester.pump();
    expect(settings.termFont, 10);
  });

  testWidgets('cambia el tema a oscuro', (tester) async {
    await openSettings(tester);

    await tester.tap(find.text('Oscuro'));
    await pumpFor(tester, 200);

    expect(settings.dark, isTrue);
    expect(Theme.of(tester.element(find.byType(Scaffold).first)).brightness, Brightness.dark);
  });

  testWidgets('elige un color de acento desde la hoja', (tester) async {
    await openSettings(tester);
    expect(find.text('Verde azulado'), findsOneWidget);

    await tester.tap(find.text('Verde azulado'));
    await pumpFor(tester, 200);
    await tester.tap(find.text('Frambuesa'));
    await pumpFor(tester, 200);

    expect(settings.accent, kAccentColors[2]);
    expect(find.text('Frambuesa'), findsOneWidget);
  });

  String addressFieldText(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField).at(0)).controller!.text;

  testWidgets('guarda la dirección del agente en modo local', (tester) async {
    await openSettings(tester);
    expect(addressFieldText(tester), '127.0.0.1:8443');

    await tester.enterText(find.byType(TextField).at(0), '192.168.1.50:8443');
    await tester.enterText(find.byType(TextField).at(1), validFingerprint);
    await tester.tap(find.text('Guardar'));
    await pumpFor(tester, 200);

    expect(settings.agentAddress, '192.168.1.50:8443');
    expect(settings.fingerprint, validFingerprint);
    expect(find.text('Formato esperado: host:puerto'), findsNothing);
    expect(find.text('Guardado'), findsOneWidget);
  });

  testWidgets('rechaza una dirección con formato inválido', (tester) async {
    await openSettings(tester);

    await tester.enterText(find.byType(TextField).at(0), 'no es una dirección');
    await tester.tap(find.text('Guardar'));
    await pumpFor(tester, 200);

    expect(find.text('Formato esperado: host:puerto'), findsOneWidget);
    expect(settings.agentAddress, '127.0.0.1:8443');
  });

  testWidgets('cambiar a iroh muestra el campo de identificador y lo guarda', (tester) async {
    await openSettings(tester);

    await tester.tap(find.text('iroh'));
    await pumpFor(tester, 200);
    expect(find.text('127.0.0.1:8443'), findsNothing);

    await tester.enterText(find.byType(TextField), validIrohId);
    await tester.tap(find.text('Guardar'));
    await pumpFor(tester, 200);

    expect(settings.connectionMode, ConnectionMode.iroh);
    expect(settings.irohId, validIrohId);
  });

  testWidgets('rechaza un identificador iroh que no son 64 caracteres hexadecimales', (
    tester,
  ) async {
    await openSettings(tester);
    await tester.tap(find.text('iroh'));
    await pumpFor(tester, 200);

    await tester.enterText(find.byType(TextField), 'nodeid-de-prueba');
    await tester.tap(find.text('Guardar'));
    await pumpFor(tester, 200);

    expect(find.text(kInvalidIrohIdMessage), findsOneWidget);
    expect(find.text('Guardado'), findsNothing);
    expect(settings.irohId, '');
  });

  testWidgets('desemparejar pide confirmación, olvida el equipo y vuelve al login', (tester) async {
    await openSettings(tester);

    await tester.tap(find.text('Desemparejar'));
    await pumpFor(tester, 200);
    expect(find.text('¿Desemparejar este móvil?'), findsOneWidget);

    await tester.tap(find.text('Desemparejar').last);
    await pumpFor(tester, 300);

    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsNothing);
    expect(settings.agentAddress, kDefaultAgentAddress);
    expect(settings.fingerprint, '');
  });

  testWidgets('cancelar el diálogo mantiene el emparejado', (tester) async {
    await openSettings(tester);

    await tester.tap(find.text('Desemparejar'));
    await pumpFor(tester, 200);
    await tester.tap(find.text('Cancelar'));
    await pumpFor(tester, 200);

    expect(find.text('Este móvil tiene una sesión abierta con el PC.'), findsOneWidget);
  });
}
