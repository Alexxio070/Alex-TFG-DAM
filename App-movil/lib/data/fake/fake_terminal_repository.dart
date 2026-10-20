import 'dart:async';

import '../repositories/terminal_repository.dart';

const _prompt = '\x1b[32musuario@pc\x1b[0m:\x1b[34m~\x1b[0m\$ ';
const _clearScreen = '\x1b[2J\x1b[H';

class FakeTerminalRepository implements TerminalRepository {
  final _output = StreamController<String>.broadcast();
  final _sessionEnded = StreamController<void>.broadcast();
  final _history = <String>[];
  var _line = '';
  var _historyIndex = -1;

  @override
  Stream<String> get output => _output.stream;

  @override
  Stream<void> get sessionEnded => _sessionEnded.stream;

  @override
  Future<void> createSession() async {
    _history.clear();
    _line = '';
    _historyIndex = -1;
    await Future.delayed(const Duration(milliseconds: 600));
    _emit(
      'Conectado a pc mediante el agente.\r\n'
      'Escribe help para ver los comandos de ejemplo.\r\n\r\n$_prompt',
    );
  }

  void _emit(String text) {
    if (!_output.isClosed) _output.add(text);
  }

  @override
  void send(String data) {
    var i = 0;
    while (i < data.length) {
      final char = data[i];
      if (char == '\x04' && _line.isEmpty) {
        _endSession();
        return;
      }
      if (char == '\x1b') {
        final sequence = data.substring(i);
        if (sequence.startsWith('\x1b[A') || sequence.startsWith('\x1bOA')) {
          _step(-1);
          i += 3;
        } else if (sequence.startsWith('\x1b[B') || sequence.startsWith('\x1bOB')) {
          _step(1);
          i += 3;
        } else {
          i++;
        }
        continue;
      }
      _handle(char);
      i++;
    }
  }

  void _handle(String char) {
    switch (char) {
      case '\r':
      case '\n':
        _run();
      case '\x7f':
      case '\b':
        if (_line.isNotEmpty) {
          _line = _line.substring(0, _line.length - 1);
          _emit('\b \b');
        }
      case '\x03':
        _line = '';
        _historyIndex = -1;
        _emit('^C\r\n$_prompt');
      case '\x0c':
        _emit('$_clearScreen$_prompt$_line');
      case '\t':
        break;
      default:
        if (char.codeUnitAt(0) >= 0x20) {
          _line += char;
          _emit(char);
        }
    }
  }

  void _step(int direction) {
    if (_history.isEmpty) return;
    var index = _historyIndex == -1
        ? (direction < 0 ? _history.length - 1 : -1)
        : _historyIndex + direction;
    if (index >= _history.length) index = -1;
    if (index < -1) index = 0;
    _historyIndex = index;
    _line = index == -1 ? '' : _history[index];
    _emit('\r\x1b[K$_prompt$_line');
  }

  void _run() {
    final command = _line.trim();
    if (command.isNotEmpty) {
      _history.add(_line);
      if (_history.length > 50) _history.removeAt(0);
    }
    _line = '';
    _historyIndex = -1;
    if (command == 'clear') {
      _emit('$_clearScreen$_prompt');
      return;
    }
    if (command == 'exit') {
      _emit('\r\nexit\r\n');
      _endSession();
      return;
    }
    final parts = command.split(RegExp(r'\s+'));
    final name = parts.first;
    final args = parts.skip(1).join(' ');
    final lines = switch (name) {
      '' => <String>[],
      'help' => [
          'Comandos de ejemplo:',
          '  ls  pwd  whoami  uname -a  date  echo <texto>  clear  exit',
        ],
      'ls' => ['Descargas  Documentos  Escritorio  Imágenes  Música  proyectos'],
      'pwd' => ['/home/usuario'],
      'whoami' => ['usuario'],
      'uname' => [
          args.contains('-a')
              ? 'Linux pc 6.11.0 #1 SMP PREEMPT_DYNAMIC x86_64 GNU/Linux'
              : 'Linux',
        ],
      'date' => [_now()],
      'echo' => [args],
      _ => ['\x1b[31mbash: $name: orden no encontrada\x1b[0m'],
    };
    _emit('\r\n${lines.map((l) => '$l\r\n').join()}$_prompt');
  }

  void _endSession() {
    _line = '';
    _historyIndex = -1;
    if (!_sessionEnded.isClosed) _sessionEnded.add(null);
  }

  @override
  Future<void> close() async {
    await _output.close();
    await _sessionEnded.close();
  }

  String _now() {
    final d = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.day}/${d.month}/${d.year}, ${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
  }
}
