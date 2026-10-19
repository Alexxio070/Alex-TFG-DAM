import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:xterm/xterm.dart';

import '../../data/repositories/terminal_repository.dart';

enum TerminalSessionState { empty, creating, ready }

class TerminalViewModel extends ChangeNotifier {
  TerminalViewModel(this._repository) {
    _endedSubscription = _repository.sessionEnded.listen((_) => _handleSessionEnded());
  }

  final TerminalRepository _repository;
  Terminal terminal = Terminal(maxLines: 1000);
  StreamSubscription<String>? _outputSubscription;
  late final StreamSubscription<void> _endedSubscription;
  TerminalSessionState _state = TerminalSessionState.empty;
  final _pending = <String>[];
  bool _ctrl = false;
  bool _alt = false;

  TerminalSessionState get state => _state;
  bool get ctrl => _ctrl;
  bool get alt => _alt;

  void requestSession() {
    if (_state != TerminalSessionState.empty) return;
    _state = TerminalSessionState.creating;
    terminal = Terminal(maxLines: 1000)..onOutput = _onTerminalOutput;
    notifyListeners();
    _outputSubscription = _repository.output.listen(terminal.write);
    _repository.createSession().then((_) {
      if (_state != TerminalSessionState.creating) return;
      _state = TerminalSessionState.ready;
      for (final data in _pending) {
        _repository.send(data);
      }
      _pending.clear();
      notifyListeners();
    });
  }

  void _handleSessionEnded() {
    _outputSubscription?.cancel();
    _outputSubscription = null;
    _state = TerminalSessionState.empty;
    _pending.clear();
    terminal = Terminal(maxLines: 1000);
    notifyListeners();
  }

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

  void _onTerminalOutput(String data) {
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
    if (_state == TerminalSessionState.ready) {
      _repository.send(output);
    } else {
      _pending.add(output);
    }
  }

  @override
  void dispose() {
    _state = TerminalSessionState.empty;
    _outputSubscription?.cancel();
    _endedSubscription.cancel();
    super.dispose();
  }
}
