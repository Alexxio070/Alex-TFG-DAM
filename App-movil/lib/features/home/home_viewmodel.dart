// ViewModel de Inicio: estado de la cuadrícula de macros y carpetas.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../core/theme/app_tokens.dart';
import '../../data/models/home_item.dart';
import '../../data/repositories/macro_repository.dart';

/// Máximo de elementos en la cuadrícula.
const kMaxItems = 40;

/// Texto del aviso inferior: título y comando.
typedef RunToastData = ({String title, String command});

/// Carga, ordena, agrupa y borra macros y carpetas, las guarda en el repositorio y ejecuta macros.
class HomeViewModel extends ChangeNotifier {
  HomeViewModel(this._repository) {
    _load();
  }

  final MacroRepository _repository;
  List<HomeItem> _items = [];
  bool _dragging = false;
  RunToastData? _toast;
  Timer? _toastTimer;

  List<HomeItem> get items => _items;
  bool get dragging => _dragging;
  RunToastData? get toast => _toast;
  bool get isFull => _items.length >= kMaxItems;

  Future<void> _load() async {
    _items = await _repository.loadItems();
    notifyListeners();
  }

  /// Marca si se está arrastrando un elemento; al empezar, oculta el aviso.
  void setDragging(bool value) {
    if (value) {
      _toastTimer?.cancel();
      _toast = null;
    }
    _dragging = value;
    notifyListeners();
  }

  /// Ejecuta [macro] en el PC y muestra el aviso «Ejecutando…».
  void execute(Macro macro) {
    _repository.run(macro);
    _showToast((title: 'Ejecutando «${macro.label}»', command: macro.command), 2200);
  }

  /// Avisa de que no caben más elementos.
  void showFullToast() {
    _showToast((title: 'No caben más botones', command: ''), 1600);
  }

  /// Añade una macro nueva al final.
  void createMacro({
    required String name,
    required String command,
    required bool confirm,
    MacroKind kind = MacroKind.bolt,
  }) {
    final macro = Macro(
      id: 'm${_newId()}',
      label: name,
      command: command,
      confirm: confirm,
      kind: kind,
    );
    _commit([..._items, macro]);
  }

  /// Mueve el elemento [id] a la posición [toIndex].
  void moveItem(String id, int toIndex) {
    final items = List.of(_items);
    final from = items.indexWhere((i) => i.id == id);
    if (from < 0) return;
    final moving = items.removeAt(from);
    items.insert(toIndex, moving);
    _commit(items);
  }

  /// Suelta la macro [id] sobre el elemento de [targetIndex]: si es una carpeta la mete dentro y si
  /// es otra macro crea una carpeta con las dos.
  void mergeInto(String id, int targetIndex) {
    final items = List.of(_items);
    final from = items.indexWhere((i) => i.id == id);
    final moving = from < 0 ? null : items[from];
    if (moving is! Macro) return;
    final target = items[targetIndex];
    if (target is Folder) {
      items[targetIndex] = target.copyWith(children: [...target.children, moving]);
    } else if (target is Macro) {
      items[targetIndex] = Folder(
        id: 'f${_newId()}',
        name: 'Carpeta',
        color: kAccentColors.first,
        children: [target, moving],
      );
    }
    items.removeAt(from);
    _commit(items);
  }

  /// Borra el elemento [id] (una carpeta, con sus macros).
  void deleteItem(String id) {
    _commit(_items.where((i) => i.id != id).toList());
  }

  /// Deshace la carpeta [id] y deja sus macros sueltas en su lugar.
  void ungroupFolder(String id) {
    final items = List.of(_items);
    final index = items.indexWhere((i) => i.id == id);
    if (index < 0) return;
    final item = items[index];
    if (item is! Folder) return;
    items.removeAt(index);
    items.insertAll(index, item.children);
    _commit(items);
  }

  /// Cambia el nombre y el color de la carpeta [id].
  void updateFolder(String id, {required String name, required Color color}) {
    final label = name.trim().isEmpty ? 'Carpeta' : name.trim();
    _commit([
      for (final item in _items)
        if (item is Folder && item.id == id) item.copyWith(name: label, color: color) else item,
    ]);
  }

  int _newId() => DateTime.now().microsecondsSinceEpoch;

  void _commit(List<HomeItem> items) {
    _items = items;
    _repository.saveItems(items);
    notifyListeners();
  }

  void _showToast(RunToastData data, int milliseconds) {
    _toastTimer?.cancel();
    _toast = data;
    _toastTimer = Timer(Duration(milliseconds: milliseconds), _clearToast);
    notifyListeners();
  }

  void _clearToast() {
    _toast = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }
}
