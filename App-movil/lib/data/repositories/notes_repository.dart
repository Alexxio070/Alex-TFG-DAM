import '../models/note.dart';

abstract class NotesRepository {
  Future<List<Note>> list({String query = ''});
  Future<void> create(String content);
  Future<void> update(String id, String content);
  Future<void> delete(String id);
}
