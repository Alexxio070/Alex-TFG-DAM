// Interfaz de las notas.

import '../models/note.dart';

/// Lista (con búsqueda), crea, edita y borra notas.
abstract class NotesRepository {
  Future<List<Note>> list({String query = ''});
  Future<void> create(String content);
  Future<void> update(String id, String content);
  Future<void> delete(String id);
}
