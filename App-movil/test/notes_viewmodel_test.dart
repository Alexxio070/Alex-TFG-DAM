import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tfg/data/models/note.dart';
import 'package:tfg/data/repositories/notes_repository.dart';
import 'package:tfg/data/repositories/pairing_repository.dart';
import 'package:tfg/features/notes/notes_viewmodel.dart';

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

class _AlwaysPaired implements PairingRepository {
  final _paired = ValueNotifier<bool>(true);

  @override
  ValueListenable<bool> get paired => _paired;

  @override
  Future<void> pair() async {}

  @override
  Future<void> unpair() async {}
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
    final vm = NotesViewModel(repository, _AlwaysPaired());
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
