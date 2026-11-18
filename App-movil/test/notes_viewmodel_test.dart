import 'package:flutter_test/flutter_test.dart';
import 'package:sysmote/data/models/note.dart';
import 'package:sysmote/data/repositories/notes_repository.dart';
import 'package:sysmote/features/auth/auth_viewmodel.dart';
import 'package:sysmote/features/notes/notes_viewmodel.dart';

import 'fakes/fake_auth_repository.dart';
import 'fakes/in_memory_token_storage.dart';

class _SlowNotesRepository implements NotesRepository {
  final Map<String, Duration> delays;

  _SlowNotesRepository(this.delays);

  @override
  Future<List<Note>> list({String query = ''}) async {
    await Future<void>.delayed(delays[query] ?? Duration.zero);
    final now = DateTime.now();
    return [
      Note(
        id: query,
        content: query,
        origin: NoteOrigin.mobile,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  @override
  Future<void> create(String content) async {}

  @override
  Future<void> update(String id, String content) async {}

  @override
  Future<void> delete(String id) async {}
}

void main() {
  test('una respuesta lenta de una búsqueda antigua no pisa la más reciente', () async {
    // "lenta" se dispara primero (tras el debounce de 300 ms) pero tarda
    // 500 ms en responder; "rapida" se dispara después pero no tarda nada,
    // así que su respuesta llega antes que la de "lenta".
    final repository = _SlowNotesRepository({
      'lenta': const Duration(milliseconds: 500),
      'rapida': Duration.zero,
    });
    final auth = AuthViewModel(
      FakeAuthRepository.loggedIn(),
      InMemoryTokenStorage()..write('token-fake'),
    );
    final vm = NotesViewModel(repository, auth);
    await Future<void>.delayed(Duration.zero);

    vm.search('lenta');
    await Future<void>.delayed(const Duration(milliseconds: 310)); // dispara "lenta"
    vm.search('rapida');
    await Future<void>.delayed(const Duration(milliseconds: 310)); // dispara "rapida"

    expect(vm.items.single.id, 'rapida');

    await Future<void>.delayed(const Duration(milliseconds: 300)); // llega "lenta", se descarta

    expect(vm.items.single.id, 'rapida');
  });
}
