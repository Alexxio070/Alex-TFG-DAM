import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_tokens.dart';
import '../../data/models/home_item.dart';
import '../../data/repositories/macro_repository.dart';

const kMaxItems = 40;

typedef RunToastData = ({String title, String command});

class HomeViewModel extends ChangeNotifier {
  HomeViewModel(this._repository) {
    _load();
  }

  final MacroRepository _repository;
  List<HomeItem> _items = [];
  int _nextId = 100;
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

  void setDragging(bool value) {
    if (value) {
      _toastTimer?.cancel();
      _toast = null;
    }
    _dragging = value;
    notifyListeners();
  }

  void execute(Macro macro) {
    HapticFeedback.lightImpact();
    _repository.run(macro);
    _showToast((title: 'Ejecutando «${macro.label}»', command: macro.command), 2200);
  }

  void showFullToast() {
    _showToast((title: 'No caben más botones', command: ''), 1600);
  }

  void createMacro({
    required String name,
    required String command,
    required bool confirm,
    MacroKind kind = MacroKind.bolt,
  }) {
    final macro = Macro(
      id: 'm$_nextId',
      label: name,
      command: command,
      confirm: confirm,
      kind: kind,
    );
    _nextId++;
    _commit([..._items, macro]);
  }

  void moveItem(String id, int toIndex) {
    final items = List.of(_items);
    final from = items.indexWhere((i) => i.id == id);
    if (from < 0) return;
    final moving = items.removeAt(from);
    items.insert(toIndex, moving);
    _commit(items);
  }

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
        id: 'f$_nextId',
        name: 'Carpeta',
        color: kAccentColors.first,
        children: [target, moving],
      );
      _nextId++;
    }
    items.removeAt(from);
    _commit(items);
  }

  void deleteItem(String id) {
    _commit(_items.where((i) => i.id != id).toList());
  }

  void updateFolder(String id, {required String name, required Color color}) {
    final label = name.trim().isEmpty ? 'Carpeta' : name.trim();
    _commit([
      for (final item in _items)
        if (item is Folder && item.id == id) item.copyWith(name: label, color: color) else item,
    ]);
  }

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
    _toastTimer?.cancel();
    _toast = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }
}
