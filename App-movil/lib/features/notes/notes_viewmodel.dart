import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/note.dart';
import '../../data/repositories/notes_repository.dart';
import '../../data/repositories/pairing_repository.dart';

class NotesViewModel extends ChangeNotifier {
  NotesViewModel(this._notes, this._pairing) {
    _pairing.paired.addListener(load);
    load();
  }

  final NotesRepository _notes;
  final PairingRepository _pairing;
  List<Note> _items = const [];
  String _query = '';
  bool _loading = false;
  String? _message;
  Timer? _searchTimer;
  Timer? _messageTimer;

  List<Note> get items => _items;
  String get query => _query;
  bool get loading => _loading;
  bool get isPaired => _pairing.paired.value;
  String? get message => _message;

  Future<void> load() async {
    if (!isPaired) {
      _items = const [];
      notifyListeners();
      return;
    }
    _loading = true;
    notifyListeners();
    try {
      _items = await _notes.list(query: _query);
    } catch (_) {
      showMessage('No se pudieron cargar las notas');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void search(String query) {
    _query = query.trim();
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 300), load);
  }

  Future<void> save({String? id, required String content}) async {
    final text = content.trim();
    if (id == null) {
      await _notes.create(text);
    } else {
      await _notes.update(id, text);
    }
    await load();
  }

  Future<void> delete(String id) async {
    await _notes.delete(id);
    await load();
  }

  void showMessage(String text) {
    _messageTimer?.cancel();
    _message = text;
    _messageTimer = Timer(const Duration(milliseconds: 2200), () {
      _message = null;
      notifyListeners();
    });
    notifyListeners();
  }

  @override
  void dispose() {
    _pairing.paired.removeListener(load);
    _searchTimer?.cancel();
    _messageTimer?.cancel();
    super.dispose();
  }
}
