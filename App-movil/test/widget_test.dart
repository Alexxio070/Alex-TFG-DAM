import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tfg/app.dart';
import 'package:tfg/core/theme/app_tokens.dart';
import 'package:tfg/data/fake/fake_macro_repository.dart';
import 'package:tfg/data/fake/fake_metrics_repository.dart';
import 'package:tfg/data/fake/fake_notes_repository.dart';
import 'package:tfg/data/fake/fake_pairing_repository.dart';
import 'package:tfg/data/fake/fake_terminal_repository.dart';
import 'package:tfg/data/fake/in_memory_settings_repository.dart';
import 'package:tfg/data/repositories/macro_repository.dart';
import 'package:tfg/data/repositories/metrics_repository.dart';
import 'package:tfg/data/repositories/notes_repository.dart';
import 'package:tfg/data/repositories/pairing_repository.dart';
import 'package:tfg/data/repositories/settings_repository.dart';
import 'package:tfg/data/repositories/terminal_repository.dart';
import 'package:tfg/features/home/home_viewmodel.dart';
import 'package:tfg/features/metrics/metrics_viewmodel.dart';
import 'package:tfg/features/notes/note_form_view.dart';
import 'package:tfg/features/notes/notes_viewmodel.dart';
import 'package:tfg/features/settings/settings_viewmodel.dart';
import 'package:tfg/features/shell/shell_viewmodel.dart';
import 'package:tfg/features/terminal/terminal_viewmodel.dart';
import 'package:xterm/xterm.dart';

Widget _app() => MultiProvider(
      providers: [
        Provider<PairingRepository>(create: (_) => FakePairingRepository()),
        Provider<MacroRepository>(create: (_) => FakeMacroRepository()),
        Provider<MetricsRepository>(create: (_) => FakeMetricsRepository()),
        Provider<NotesRepository>(create: (_) => FakeNotesRepository()),
        Provider<TerminalRepository>(create: (_) => FakeTerminalRepository()),
        Provider<SettingsRepository>(create: (_) => InMemorySettingsRepository()),
        ChangeNotifierProvider(
          create: (context) => SettingsViewModel(context.read<SettingsRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => ShellViewModel(context.read<PairingRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => HomeViewModel(context.read<MacroRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => MetricsViewModel(context.read<MetricsRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => NotesViewModel(
            context.read<NotesRepository>(),
            context.read<PairingRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => TerminalViewModel(context.read<TerminalRepository>()),
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
    await tester.pump();

    expect(find.text('Inicio'), findsWidgets);
    expect(find.text('Conectado'), findsNothing);
  });

  testWidgets('el drawer cambia de sección y se cierra', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();

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
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('Abrir menú'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Ajustes'));
    await tester.pumpAndSettle();

    expect(find.text('Ajustes'), findsWidgets);
  });

  testWidgets('el drawer se abre arrastrando desde el borde izquierdo', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();
    expect(find.text('Conectado'), findsNothing);

    await tester.dragFrom(const Offset(8, 300), const Offset(250, 0));
    await tester.pumpAndSettle();

    expect(find.text('Conectado'), findsOneWidget);
  });

  testWidgets('un arrastre corto desde el borde deja el drawer cerrado', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    await tester.dragFrom(const Offset(8, 300), const Offset(60, 0));
    await tester.pumpAndSettle();

    expect(find.text('Conectado'), findsNothing);
  });

  testWidgets('el drawer se cierra arrastrando hacia la izquierda', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Abrir menú'));
    await tester.pumpAndSettle();
    expect(find.text('Conectado'), findsOneWidget);

    await tester.dragFrom(const Offset(250, 300), const Offset(-200, 0));
    await tester.pumpAndSettle();

    expect(find.text('Conectado'), findsNothing);
  });

  group('Inicio', () {
    Future<void> pumpHome(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app());
      await tester.pump();
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
      await tester.tap(find.bySemanticsLabel('lock'));
      await tester.pump();
      await tester.tap(find.text('Crear'));
      await tester.pumpAndSettle();

      expect(find.text('Modo avión'), findsOneWidget);
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

    Future<void> makeFolder(WidgetTester tester) async {
      final gesture = await tester.startGesture(const Offset(103, 171));
      await tester.pump(const Duration(milliseconds: 450));
      await gesture.moveTo(const Offset(287, 171));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
    }

    Future<void> dragFolderToTrash(WidgetTester tester) async {
      final gesture = await tester.startGesture(const Offset(103, 171));
      await tester.pump(const Duration(milliseconds: 450));
      await gesture.moveTo(const Offset(195, 64 + 708));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
    }

    testWidgets('arrastrar una carpeta con macros a la papelera pregunta qué hacer', (
      tester,
    ) async {
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
  });

  group('Métricas', () {
    Future<void> openMetrics(WidgetTester tester) async {
      tester.view.physicalSize = const Size(700 * 3, 1400 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app());
      await tester.pump();
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

  group('Notas', () {
    Future<void> openNotes(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app());
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Abrir menú'));
      await _pumpFor(tester, 500);
      await tester.tap(find.text('Notas'));
      await _pumpFor(tester, 600);
    }

    Finder note(String text) => find.textContaining(text, findRichText: true);
    Finder formField() => find.descendant(
          of: find.byType(NoteFormView),
          matching: find.byType(TextField),
        );

    testWidgets('lista las notas de ejemplo con su origen', (tester) async {
      await openNotes(tester);

      expect(note('docs.flutter.dev'), findsOneWidget);
      expect(note('systemctl restart nginx'), findsOneWidget);
      expect(find.textContaining('Desde el PC'), findsOneWidget);
      expect(find.textContaining('Desde el móvil'), findsNWidgets(2));
    });

    testWidgets('crea una nota y la muestra en la lista', (tester) async {
      await openNotes(tester);

      await tester.tap(find.bySemanticsLabel('Nueva nota'));
      await _pumpFor(tester, 500);
      expect(find.text('Nueva nota'), findsOneWidget);

      await tester.enterText(formField(), 'Comprar cable HDMI');
      await tester.pump();
      await tester.tap(find.text('Guardar'));
      await _pumpFor(tester, 600);

      expect(note('Comprar cable HDMI'), findsOneWidget);
    });

    testWidgets('no permite guardar una nota vacía', (tester) async {
      await openNotes(tester);

      await tester.tap(find.bySemanticsLabel('Nueva nota'));
      await _pumpFor(tester, 500);
      await tester.tap(find.text('Guardar'));
      await _pumpFor(tester, 300);

      expect(find.text('Nueva nota'), findsOneWidget);
    });

    testWidgets('edita una nota existente', (tester) async {
      await openNotes(tester);

      await tester.tap(find.bySemanticsLabel('Editar nota').first);
      await _pumpFor(tester, 500);
      expect(find.text('Editar nota'), findsOneWidget);

      await tester.enterText(formField(), 'texto cambiado');
      await tester.pump();
      await tester.tap(find.text('Guardar'));
      await _pumpFor(tester, 600);

      expect(note('texto cambiado'), findsOneWidget);
    });

    testWidgets('elimina una nota tras confirmar', (tester) async {
      await openNotes(tester);

      await tester.tap(find.bySemanticsLabel('Editar nota').first);
      await _pumpFor(tester, 500);
      await tester.tap(find.text('Eliminar'));
      await _pumpFor(tester, 200);
      expect(find.text('¿Eliminar esta nota?'), findsOneWidget);

      await tester.tap(find.text('Eliminar').last);
      await _pumpFor(tester, 600);

      expect(note('docs.flutter.dev'), findsNothing);
    });

    testWidgets('filtra al buscar', (tester) async {
      await openNotes(tester);

      await tester.enterText(find.byType(TextField), 'nginx');
      await _pumpFor(tester, 500);

      expect(note('systemctl restart nginx'), findsOneWidget);
      expect(note('docs.flutter.dev'), findsNothing);
    });

    testWidgets('avisa cuando la búsqueda no tiene resultados', (tester) async {
      await openNotes(tester);

      await tester.enterText(find.byType(TextField), 'zzz');
      await _pumpFor(tester, 500);

      expect(find.text('Sin resultados para «zzz»'), findsOneWidget);
    });

    testWidgets('copiar muestra el aviso', (tester) async {
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
      await openNotes(tester);

      await tester.tap(find.bySemanticsLabel('Copiar nota').first);
      await _pumpFor(tester, 200);

      expect(find.text('Copiado'), findsOneWidget);
      await _pumpFor(tester, 2500);
    });
  });

  group('Terminal', () {
    Future<TerminalViewModel> openTerminal(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app());
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Abrir menú'));
      await _pumpFor(tester, 500);
      await tester.tap(find.text('Terminal'));
      await _pumpFor(tester, 600);
      await tester.tap(find.text('Toca para abrir una terminal en tu PC'));
      await _pumpFor(tester, 700);
      return Provider.of<TerminalViewModel>(
        tester.element(find.byType(TfgApp)),
        listen: false,
      );
    }

    String screen(TerminalViewModel vm) => vm.terminal.buffer.getText();

    testWidgets('empieza vacía con el aviso y pasa al prompt real al tocarla', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app());
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Abrir menú'));
      await _pumpFor(tester, 500);
      await tester.tap(find.text('Terminal'));
      await _pumpFor(tester, 600);

      expect(find.text('Toca para abrir una terminal en tu PC'), findsOneWidget);

      await tester.tap(find.text('Toca para abrir una terminal en tu PC'));
      await tester.pump();

      expect(find.text('Abriendo terminal…'), findsOneWidget);

      await _pumpFor(tester, 700);

      expect(find.text('Toca para abrir una terminal en tu PC'), findsNothing);
      expect(find.text('Abriendo terminal…'), findsNothing);
    });

    testWidgets('las teclas escritas mientras se crea la sesión no se pierden', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app());
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Abrir menú'));
      await _pumpFor(tester, 500);
      await tester.tap(find.text('Terminal'));
      await _pumpFor(tester, 600);
      final vm = Provider.of<TerminalViewModel>(
        tester.element(find.byType(TfgApp)),
        listen: false,
      );

      await tester.tap(find.text('Toca para abrir una terminal en tu PC'));
      await tester.pump();
      vm.terminal.textInput('whoami\r');
      await _pumpFor(tester, 700);

      expect(screen(vm), contains('whoami'));
      expect(screen(vm), contains('usuario\n'));
    });

    testWidgets('escribir exit cierra la sesión y vuelve al aviso', (tester) async {
      final vm = await openTerminal(tester);

      vm.terminal.textInput('exit\r');
      await _pumpFor(tester, 200);

      expect(vm.state, TerminalSessionState.empty);
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
      await _pumpFor(tester, 200);

      expect(screen(vm), contains('whoami'));
      expect(screen(vm), contains('usuario\n'));
    });

    testWidgets('un comando desconocido da error', (tester) async {
      final vm = await openTerminal(tester);

      vm.terminal.textInput('foo\r');
      await _pumpFor(tester, 200);

      expect(screen(vm), contains('bash: foo: orden no encontrada'));
    });

    testWidgets('la flecha arriba recupera el comando anterior', (tester) async {
      final vm = await openTerminal(tester);

      vm.terminal.textInput('echo hola\r');
      await _pumpFor(tester, 200);
      vm.pressKey(TerminalKey.arrowUp);
      await _pumpFor(tester, 200);

      expect(screen(vm).trimRight().split('\n').last, endsWith('echo hola'));
    });

    testWidgets('CTRL + c cancela la línea', (tester) async {
      final vm = await openTerminal(tester);

      vm.terminal.textInput('sleep 10');
      vm.toggleCtrl();
      expect(vm.ctrl, isTrue);
      vm.terminal.textInput('c');
      await _pumpFor(tester, 200);

      expect(vm.ctrl, isFalse);
      expect(screen(vm), contains('^C'));
    });

    testWidgets('clear limpia la pantalla', (tester) async {
      final vm = await openTerminal(tester);

      vm.terminal.textInput('clear\r');
      await _pumpFor(tester, 200);

      expect(screen(vm), isNot(contains('Conectado a pc')));
    });
  });

  group('Ajustes', () {
    late SettingsViewModel settings;

    Future<void> openSettings(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 1600 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app());
      await tester.pump();
      settings = Provider.of<SettingsViewModel>(
        tester.element(find.byType(TfgApp)),
        listen: false,
      );
      await tester.tap(find.bySemanticsLabel('Abrir menú'));
      await _pumpFor(tester, 500);
      await tester.tap(find.bySemanticsLabel('Ajustes'));
      await _pumpFor(tester, 600);
    }

    testWidgets('muestra todos los grupos', (tester) async {
      await openSettings(tester);

      for (final title in ['Unidades', 'Métricas', 'Terminal', 'Apariencia', 'Dispositivo']) {
        expect(find.text(title), findsWidgets);
      }
      expect(find.text('Este móvil está emparejado con el PC.'), findsOneWidget);
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
      await _pumpFor(tester, 200);

      expect(settings.dark, isTrue);
      expect(
        Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
        Brightness.dark,
      );
    });

    testWidgets('elige un color de acento desde la hoja', (tester) async {
      await openSettings(tester);
      expect(find.text('Verde azulado'), findsOneWidget);

      await tester.tap(find.text('Verde azulado'));
      await _pumpFor(tester, 200);
      await tester.tap(find.text('Frambuesa'));
      await _pumpFor(tester, 200);

      expect(settings.accent, kAccentColors[2]);
      expect(find.text('Frambuesa'), findsOneWidget);
    });

    testWidgets('desemparejar pide confirmación y actualiza el estado', (tester) async {
      await openSettings(tester);

      await tester.tap(find.text('Desemparejar'));
      await _pumpFor(tester, 200);
      expect(find.text('¿Desemparejar este móvil?'), findsOneWidget);

      await tester.tap(find.text('Desemparejar').last);
      await _pumpFor(tester, 300);

      expect(find.text('Este móvil no está emparejado con ningún PC.'), findsOneWidget);
      expect(find.text('Emparejar'), findsOneWidget);
    });

    testWidgets('cancelar el diálogo mantiene el emparejado', (tester) async {
      await openSettings(tester);

      await tester.tap(find.text('Desemparejar'));
      await _pumpFor(tester, 200);
      await tester.tap(find.text('Cancelar'));
      await _pumpFor(tester, 200);

      expect(find.text('Este móvil está emparejado con el PC.'), findsOneWidget);
    });
  });

  group('Barra de navegación del sistema', () {
    const bar = 48.0;

    Future<void> withNavigationBar(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      tester.view.padding = const FakeViewPadding(bottom: bar * 3);
      tester.view.viewPadding = const FakeViewPadding(bottom: bar * 3);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app());
      await tester.pump();
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
      await _pumpFor(tester, 500);
      await tester.tap(find.text('Notas'));
      await _pumpFor(tester, 600);

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
  });
}
