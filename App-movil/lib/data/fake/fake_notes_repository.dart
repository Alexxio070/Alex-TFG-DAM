// PLACEHOLDER: notas de ejemplo en memoria mientras el agente no tenga notas. No es código muerto:
// lo usa main.dart.

import '../models/note.dart';
import '../repositories/notes_repository.dart';

/// Lista, crea, edita y borra notas en memoria, empezando con 3 de ejemplo.
class FakeNotesRepository implements NotesRepository {
  FakeNotesRepository() {
    final now = DateTime.now();
    _notes = [
      Note(
        id: 'n1',
        content: 'https://docs.flutter.dev/cookbook',
        origin: NoteOrigin.mobile,
        createdAt: now.subtract(const Duration(minutes: 5)),
        updatedAt: now.subtract(const Duration(minutes: 5)),
      ),
      Note(
        id: 'n2',
        content: 'sudo systemctl restart nginx && journalctl -u nginx -f',
        origin: NoteOrigin.pc,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      Note(
        id: 'n3',
        content:
            'Llamar al técnico para el router. Su web: www.tecnico-local.es, '
            'abre de lunes a viernes.',
        origin: NoteOrigin.mobile,
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
    ];
  }

  late List<Note> _notes;
  int _nextId = 4;

  @override
  Future<List<Note>> list({String query = ''}) async {
    final text = query.trim().toLowerCase();
    final result =
        _notes.where((n) => text.isEmpty || n.content.toLowerCase().contains(text)).toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return result;
  }

  @override
  Future<void> create(String content) async {
    final now = DateTime.now();
    _notes.add(
      Note(
        id: 'n${_nextId++}',
        content: content,
        origin: NoteOrigin.mobile,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  Future<void> update(String id, String content) async {
    _notes = [
      for (final n in _notes)
        if (n.id == id)
          Note(
            id: n.id,
            content: content,
            origin: n.origin,
            createdAt: n.createdAt,
            updatedAt: DateTime.now(),
          )
        else
          n,
    ];
  }

  @override
  Future<void> delete(String id) async {
    _notes = _notes.where((n) => n.id != id).toList();
  }
}
