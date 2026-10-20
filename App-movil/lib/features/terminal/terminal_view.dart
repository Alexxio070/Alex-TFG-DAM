import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:xterm/xterm.dart' as xterm;

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_toast.dart';
import '../settings/settings_viewmodel.dart';
import 'terminal_tabs_viewmodel.dart';
import 'terminal_viewmodel.dart';
import 'widgets/extra_keys_bar.dart';
import 'widgets/terminal_tabs_bar.dart';

const _theme = xterm.TerminalTheme(
  cursor: kTerminalForeground,
  selection: Color(0x66E6E8EB),
  foreground: kTerminalForeground,
  background: kTerminalBackground,
  black: kTerminalBackground,
  red: Color(0xFFFF7B72),
  green: kTerminalGreen,
  yellow: Color(0xFFE3B341),
  blue: Color(0xFF79C0FF),
  magenta: Color(0xFFD2A8FF),
  cyan: Color(0xFF56D4DD),
  white: kTerminalForeground,
  brightBlack: Color(0xFF6E7681),
  brightRed: Color(0xFFFFA198),
  brightGreen: kTerminalGreen,
  brightYellow: Color(0xFFF2CC60),
  brightBlue: Color(0xFFA5D6FF),
  brightMagenta: Color(0xFFE2C5FF),
  brightCyan: Color(0xFF76E3EA),
  brightWhite: Color(0xFFFFFFFF),
  searchHitBackground: Color(0xFFE3B341),
  searchHitBackgroundCurrent: kTerminalGreen,
  searchHitForeground: kTerminalBackground,
);

class TerminalView extends StatefulWidget {
  const TerminalView({super.key});

  @override
  State<TerminalView> createState() => _TerminalViewState();
}

class _TerminalViewState extends State<TerminalView> with WidgetsBindingObserver {
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

  void _openFirstTab(TerminalTabsViewModel tabs) {
    tabs.addTab();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  Widget build(BuildContext context) {
    final tabs = context.watch<TerminalTabsViewModel>();
    final fontSize = context.select<SettingsViewModel, int>((s) => s.termFont);
    final keyboardOpen = View.of(context).viewInsets.bottom > 0;
    if (tabs.tabs.isEmpty) {
      return ColoredBox(
        color: kTerminalBackground,
        child: _EmptyState(onTrigger: () => _openFirstTab(tabs)),
      );
    }
    final vm = tabs.active;
    return ColoredBox(
      color: kTerminalBackground,
      child: Column(
        children: [
          TerminalTabsBar(vm: tabs),
          Expanded(
            child: Stack(
              children: [
                MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  removeBottom: true,
                  child: xterm.TerminalView(
                    vm.terminal,
                    focusNode: _focus,
                    theme: _theme,
                    deleteDetection: true,
                    padding: EdgeInsets.fromLTRB(
                      12,
                      10,
                      12,
                      14 + MediaQuery.paddingOf(context).bottom,
                    ),
                    textStyle: xterm.TerminalStyle(fontSize: fontSize.toDouble(), height: 1.5),
                  ),
                ),
                if (vm.state == TerminalSessionState.creating) const _LoadingOverlay(),
                if (tabs.showFullToast)
                  const Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 24),
                      child: AppToast(text: 'No caben más pestañas'),
                    ),
                  ),
              ],
            ),
          ),
          if (keyboardOpen && vm.state == TerminalSessionState.ready)
            ExtraKeysBar(vm: vm, onHide: _hideKeyboard),
        ],
      ),
    );
  }
}

final _modifierKeys = {
  LogicalKeyboardKey.controlLeft,
  LogicalKeyboardKey.controlRight,
  LogicalKeyboardKey.altLeft,
  LogicalKeyboardKey.altRight,
  LogicalKeyboardKey.shiftLeft,
  LogicalKeyboardKey.shiftRight,
  LogicalKeyboardKey.metaLeft,
  LogicalKeyboardKey.metaRight,
};

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onTrigger});

  final VoidCallback onTrigger;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent || _modifierKeys.contains(event.logicalKey)) {
          return KeyEventResult.ignored;
        }
        onTrigger();
        return KeyEventResult.handled;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTrigger,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Toca para abrir una terminal en tu PC',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _theme.foreground),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: kTerminalBackground,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            CircularProgressIndicator(color: _theme.foreground),
            Text(
              'Abriendo terminal…',
              style: TextStyle(fontSize: 13, color: _theme.brightBlack),
            ),
          ],
        ),
      ),
    );
  }
}
