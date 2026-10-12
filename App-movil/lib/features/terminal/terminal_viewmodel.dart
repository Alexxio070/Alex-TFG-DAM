import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:xterm/xterm.dart';

import '../../data/repositories/terminal_repository.dart';

class TerminalViewModel extends ChangeNotifier {
  TerminalViewModel(this._repository) {
    terminal.onOutput = _onInput;
    _subscription = _repository.output.listen(terminal.write);
  }

  final TerminalRepository _repository;
  final terminal = Terminal(maxLines: 1000);
  late final StreamSubscription<String> _subscription;
  bool _ctrl = false;
  bool _alt = false;

  bool get ctrl => _ctrl;
  bool get alt => _alt;

  void toggleCtrl() {
    _ctrl = !_ctrl;
    notifyListeners();
  }

  void toggleAlt() {
    _alt = !_alt;
    notifyListeners();
  }

  void pressKey(TerminalKey key) => terminal.keyInput(key);

  void pressText(String text) => terminal.textInput(text);

  void _onInput(String data) {
    var output = data;
    if (_ctrl && data.length == 1) {
      final code = data.toLowerCase().codeUnitAt(0);
      if (code >= 0x61 && code <= 0x7a) output = String.fromCharCode(code - 0x60);
    }
    if (_alt && data.length == 1) output = '\x1b$output';
    if (_ctrl || _alt) {
      _ctrl = false;
      _alt = false;
      notifyListeners();
    }
    _repository.send(output);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
