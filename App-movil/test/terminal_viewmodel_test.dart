import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tfg/data/repositories/terminal_repository.dart';
import 'package:tfg/features/terminal/terminal_viewmodel.dart';

class _RecordingTerminalRepository implements TerminalRepository {
  final sent = <String>[];
  final _output = StreamController<String>.broadcast();
  final _sessionEnded = StreamController<void>.broadcast();

  @override
  Stream<String> get output => _output.stream;

  @override
  Stream<void> get sessionEnded => _sessionEnded.stream;

  @override
  Future<void> createSession() async {}

  @override
  void send(String data) => sent.add(data);

  @override
  Future<void> close() async {
    await _output.close();
    await _sessionEnded.close();
  }
}

void main() {
  test('Ctrl + letra manda el código de control, no la letra', () async {
    final repo = _RecordingTerminalRepository();
    final vm = TerminalViewModel(repo);
    vm.requestSession();
    await Future<void>.delayed(Duration.zero);

    vm.toggleCtrl();
    expect(vm.ctrl, isTrue);
    vm.terminal.textInput('c');

    expect(repo.sent, contains('\x03'));
    expect(repo.sent, isNot(contains('c')));
    expect(vm.ctrl, isFalse);
  });

  test('Alt antepone ESC al siguiente carácter', () async {
    final repo = _RecordingTerminalRepository();
    final vm = TerminalViewModel(repo);
    vm.requestSession();
    await Future<void>.delayed(Duration.zero);

    vm.toggleAlt();
    expect(vm.alt, isTrue);
    vm.terminal.textInput('b');

    expect(repo.sent, contains('\x1bb'));
    expect(vm.alt, isFalse);
  });

  test('sin Ctrl ni Alt, el carácter se manda tal cual', () async {
    final repo = _RecordingTerminalRepository();
    final vm = TerminalViewModel(repo);
    vm.requestSession();
    await Future<void>.delayed(Duration.zero);

    vm.terminal.textInput('a');

    expect(repo.sent, contains('a'));
  });
}
