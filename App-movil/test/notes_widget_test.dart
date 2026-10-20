import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tfg/data/fake/fake_notes_repository.dart';
import 'package:tfg/data/models/note.dart';
import 'package:tfg/data/repositories/notes_repository.dart';
import 'package:tfg/features/notes/note_form_view.dart';

import 'helpers/app_harness.dart';

void main() {
  Future<void> openNotes(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Abrir menú'));
    await pumpFor(tester, 500);
    await tester.tap(find.text('Notas'));
    await pumpFor(tester, 600);
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
    await pumpFor(tester, 500);
    expect(find.text('Nueva nota'), findsOneWidget);

    await tester.enterText(formField(), 'Comprar cable HDMI');
    await tester.pump();
    await tester.tap(find.text('Guardar'));
    await pumpFor(tester, 600);

    expect(note('Comprar cable HDMI'), findsOneWidget);
  });

  testWidgets('no permite guardar una nota vacía', (tester) async {
    await openNotes(tester);

    await tester.tap(find.bySemanticsLabel('Nueva nota'));
    await pumpFor(tester, 500);
    await tester.tap(find.text('Guardar'));
    await pumpFor(tester, 300);

    expect(find.text('Nueva nota'), findsOneWidget);
  });

  testWidgets('edita una nota existente', (tester) async {
    await openNotes(tester);

    await tester.tap(find.bySemanticsLabel('Editar nota').first);
    await pumpFor(tester, 500);
    expect(find.text('Editar nota'), findsOneWidget);

    await tester.enterText(formField(), 'texto cambiado');
    await tester.pump();
    await tester.tap(find.text('Guardar'));
    await pumpFor(tester, 600);

    expect(note('texto cambiado'), findsOneWidget);
  });

  testWidgets('elimina una nota tras confirmar', (tester) async {
    await openNotes(tester);

    await tester.tap(find.bySemanticsLabel('Editar nota').first);
    await pumpFor(tester, 500);
    await tester.tap(find.text('Eliminar'));
    await pumpFor(tester, 200);
    expect(find.text('¿Eliminar esta nota?'), findsOneWidget);

    await tester.tap(find.text('Eliminar').last);
    await pumpFor(tester, 600);

    expect(note('docs.flutter.dev'), findsNothing);
  });

  testWidgets('filtra al buscar', (tester) async {
    await openNotes(tester);

    await tester.enterText(find.byType(TextField), 'nginx');
    await pumpFor(tester, 500);

    expect(note('systemctl restart nginx'), findsOneWidget);
    expect(note('docs.flutter.dev'), findsNothing);
  });

  testWidgets('avisa cuando la búsqueda no tiene resultados', (tester) async {
    await openNotes(tester);

    await tester.enterText(find.byType(TextField), 'zzz');
    await pumpFor(tester, 500);

    expect(find.text('Sin resultados para «zzz»'), findsOneWidget);
  });

  testWidgets('copiar muestra el aviso', (tester) async {
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
    await openNotes(tester);

    await tester.tap(find.bySemanticsLabel('Copiar nota').first);
    await pumpFor(tester, 200);

    expect(find.text('Copiado'), findsOneWidget);
    await pumpFor(tester, 2500);
  });

  testWidgets('un error al guardar avisa y deja reintentar', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final notes = _FailingNotesRepository();
    await tester.pumpWidget(app(notesRepository: notes));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Abrir menú'));
    await pumpFor(tester, 500);
    await tester.tap(find.text('Notas'));
    await pumpFor(tester, 600);

    await tester.tap(find.bySemanticsLabel('Nueva nota'));
    await pumpFor(tester, 500);
    await tester.enterText(formField(), 'Comprar cable HDMI');
    await tester.pump();
    await tester.tap(find.text('Guardar'));
    await pumpFor(tester, 400);

    expect(find.text('No se pudo guardar la nota'), findsOneWidget);
    expect(find.text('Nueva nota'), findsOneWidget);
    expect(notes.createCalls, 1);

    await tester.tap(find.text('Guardar'));
    await pumpFor(tester, 400);

    expect(notes.createCalls, 2);
  });

  testWidgets('no deja guardar dos veces mientras la primera está en marcha', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final notes = _FailingNotesRepository();
    await tester.pumpWidget(app(notesRepository: notes));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Abrir menú'));
    await pumpFor(tester, 500);
    await tester.tap(find.text('Notas'));
    await pumpFor(tester, 600);

    await tester.tap(find.bySemanticsLabel('Nueva nota'));
    await pumpFor(tester, 500);
    await tester.enterText(formField(), 'Comprar cable HDMI');
    await tester.pump();

    await tester.tap(find.text('Guardar'));
    await tester.pump();
    await tester.tap(find.text('Guardar'));
    await pumpFor(tester, 400);

    expect(notes.createCalls, 1);
  });
}

class _FailingNotesRepository implements NotesRepository {
  final _notes = FakeNotesRepository();
  int createCalls = 0;

  @override
  Future<List<Note>> list({String query = ''}) => _notes.list(query: query);

  @override
  Future<void> create(String content) async {
    createCalls++;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    throw Exception('fallo simulado');
  }

  @override
  Future<void> update(String id, String content) => _notes.update(id, content);

  @override
  Future<void> delete(String id) => _notes.delete(id);
}
