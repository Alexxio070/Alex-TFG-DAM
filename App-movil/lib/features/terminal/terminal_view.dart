import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:xterm/xterm.dart';

import '../settings/settings_viewmodel.dart';
import 'terminal_viewmodel.dart';
import 'widgets/extra_keys_bar.dart';

const _background = Color(0xFF0D0F12);

const _theme = TerminalTheme(
  cursor: Color(0xFFE6E8EB),
  selection: Color(0x66E6E8EB),
  foreground: Color(0xFFE6E8EB),
  background: _background,
  black: Color(0xFF0D0F12),
  red: Color(0xFFFF7B72),
  green: Color(0xFF7EE787),
  yellow: Color(0xFFE3B341),
  blue: Color(0xFF79C0FF),
  magenta: Color(0xFFD2A8FF),
  cyan: Color(0xFF56D4DD),
  white: Color(0xFFE6E8EB),
  brightBlack: Color(0xFF6E7681),
  brightRed: Color(0xFFFFA198),
  brightGreen: Color(0xFF7EE787),
  brightYellow: Color(0xFFF2CC60),
  brightBlue: Color(0xFFA5D6FF),
  brightMagenta: Color(0xFFE2C5FF),
  brightCyan: Color(0xFF76E3EA),
  brightWhite: Color(0xFFFFFFFF),
  searchHitBackground: Color(0xFFE3B341),
  searchHitBackgroundCurrent: Color(0xFF7EE787),
  searchHitForeground: Color(0xFF0D0F12),
);

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> with WidgetsBindingObserver {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() => setState(() {});

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focus.dispose();
    super.dispose();
  }

  void _hideKeyboard() {
    _focus.unfocus();
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TerminalViewModel>();
    final fontSize = context.select<SettingsViewModel, int>((s) => s.termFont);
    final keyboardOpen = View.of(context).viewInsets.bottom > 0;
    return ColoredBox(
      color: _background,
      child: Column(
        children: [
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              removeBottom: true,
              child: TerminalView(
                vm.terminal,
                focusNode: _focus,
                theme: _theme,
                deleteDetection: true,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                textStyle: TerminalStyle(
                  fontSize: fontSize.toDouble(),
                  height: 1.5,
                  fontFamily: 'JetBrainsMono',
                ),
              ),
            ),
          ),
          if (keyboardOpen) ExtraKeysBar(vm: vm, onHide: _hideKeyboard),
        ],
      ),
    );
  }
}
