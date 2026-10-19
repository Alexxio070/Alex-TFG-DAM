import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/repositories/terminal_repository.dart';
import 'terminal_viewmodel.dart';

const kMaxTerminalTabs = 6;

class TerminalTabsViewModel extends ChangeNotifier {
  TerminalTabsViewModel(this._createRepository);

  final TerminalRepository Function() _createRepository;
  final List<TerminalViewModel> _tabs = [];
  int _activeIndex = 0;
  bool _showFullToast = false;
  Timer? _toastTimer;

  List<TerminalViewModel> get tabs => _tabs;
  int get activeIndex => _activeIndex;
  TerminalViewModel get active => _tabs[_activeIndex];
  bool get isFull => _tabs.length >= kMaxTerminalTabs;
  bool get showFullToast => _showFullToast;

  void addTab() {
    if (isFull) {
      _toastTimer?.cancel();
      _showFullToast = true;
      _toastTimer = Timer(const Duration(milliseconds: 1600), () {
        _showFullToast = false;
        notifyListeners();
      });
      notifyListeners();
      return;
    }
    final vm = TerminalViewModel(_createRepository());
    vm.addListener(() => _onTabChanged(vm));
    vm.requestSession();
    _tabs.add(vm);
    _activeIndex = _tabs.length - 1;
    notifyListeners();
  }

  // Si la sesión de una pestaña termina (exit o Ctrl+D), la pestaña se cierra
  // sola, sin pedir confirmación: ya fue una acción explícita del usuario.
  void _onTabChanged(TerminalViewModel vm) {
    if (vm.state == TerminalSessionState.empty) {
      final index = _tabs.indexOf(vm);
      if (index != -1) {
        _tabs.removeAt(index);
        if (_activeIndex >= _tabs.length) {
          _activeIndex = _tabs.isEmpty ? 0 : _tabs.length - 1;
        }
        scheduleMicrotask(vm.dispose);
      }
    }
    notifyListeners();
  }

  void selectTab(int index) {
    _activeIndex = index;
    notifyListeners();
  }

  void closeTab(TerminalViewModel vm) {
    final index = _tabs.indexOf(vm);
    if (index == -1) return;
    _tabs.removeAt(index);
    vm.dispose();
    if (_activeIndex >= _tabs.length) {
      _activeIndex = _tabs.isEmpty ? 0 : _tabs.length - 1;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    for (final vm in _tabs) {
      vm.dispose();
    }
    super.dispose();
  }
}
