// ViewModel de Notas: lista, búsqueda y guardado de notas.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/note.dart';
import '../../data/repositories/notes_repository.dart';
import '../auth/auth_viewmodel.dart';

/// Carga las notas cuando hay sesión, filtra por búsqueda y muestra avisos breves.
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

  /// Vuelve a pedir las notas de la búsqueda actual.
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

  /// Filtra por [query], esperando 300 ms a que se deje de escribir.
  void search(String query) {
    _query = query.trim();
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 300), load);
  }

  /// Crea una nota (sin [id]) o edita la nota [id], y recarga la lista.
  Future<void> save({String? id, required String content}) async {
    final text = content.trim();
    if (id == null) {
      await _notes.create(text);
    } else {
      await _notes.update(id, text);
    }
    await load();
  }

  /// Borra la nota [id] y recarga la lista.
  Future<void> delete(String id) async {
    await _notes.delete(id);
    await load();
  }

  /// Muestra [text] como aviso durante 2,2 s.
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
