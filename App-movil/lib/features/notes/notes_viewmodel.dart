import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/note.dart';
import '../../data/repositories/notes_repository.dart';
import '../auth/auth_viewmodel.dart';

class NotesViewModel extends ChangeNotifier {
  NotesViewModel(this._notes, this._auth) {
    _auth.addListener(load);
    load();
  }

  final NotesRepository _notes;
  final AuthViewModel _auth;
  List<Note> _items = const [];
  String _query = '';
  bool _loading = false;
  String? _message;
  Timer? _searchTimer;
  Timer? _messageTimer;

  List<Note> get items => _items;
  String get query => _query;
  bool get loading => _loading;
  bool get isPaired => _auth.stage == AuthStage.loggedIn;
  String? get message => _message;

  Future<void> load() async {
    if (!isPaired) {
      _items = const [];
      notifyListeners();
      return;
    }
    final requestedQuery = _query;
    _loading = true;
    notifyListeners();
    List<Note>? items;
    String? error;
    try {
      items = await _notes.list(query: requestedQuery);
    } catch (_) {
      error = 'No se pudieron cargar las notas';
    }
    // Ha salido una búsqueda más reciente mientras esperábamos: se
    // descarta esta respuesta para no pisar un resultado más nuevo.
    if (requestedQuery != _query) return;
    if (items != null) _items = items;
    if (error != null) showMessage(error);
    _loading = false;
    notifyListeners();
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
    _auth.removeListener(load);
    _searchTimer?.cancel();
    _messageTimer?.cancel();
    super.dispose();
  }
}
