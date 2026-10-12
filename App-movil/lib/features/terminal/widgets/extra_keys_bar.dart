import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';

import '../../../core/widgets/app_icon.dart';
import '../terminal_viewmodel.dart';

const _barBackground = Color(0xFF15171A);
const _barBorder = Color(0xFF2B2F34);
const _keyColor = Color(0xFFE6E8EB);
const _activeBackground = Color(0xFF7EE787);
const _activeForeground = Color(0xFF0D0F12);

class ExtraKeysBar extends StatelessWidget {
  const ExtraKeysBar({super.key, required this.vm, required this.onHide});

  final TerminalViewModel vm;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: _barBackground,
        border: Border(top: BorderSide(color: _barBorder)),
      ),
      child: Row(
        children: [
          _Key(label: 'ESC', semantics: 'Escape', onTap: () => vm.pressKey(TerminalKey.escape)),
          _Key(label: 'TAB', semantics: 'Tabulador', onTap: () => vm.pressKey(TerminalKey.tab)),
          _Key(label: 'CTRL', semantics: 'Control', active: vm.ctrl, onTap: vm.toggleCtrl),
          _Key(label: 'ALT', semantics: 'Alt', active: vm.alt, onTap: vm.toggleAlt),
          _Key(label: '-', semantics: 'Guion', onTap: () => vm.pressText('-')),
          _Key(label: '/', semantics: 'Barra', onTap: () => vm.pressText('/')),
          _Key(
            label: '↑',
            semantics: 'Comando anterior',
            onTap: () => vm.pressKey(TerminalKey.arrowUp),
          ),
          _Key(
            label: '↓',
            semantics: 'Comando siguiente',
            onTap: () => vm.pressKey(TerminalKey.arrowDown),
          ),
          _Key(
            semantics: 'Ocultar teclado',
            onTap: onHide,
            child: const AppIconView(AppIcon.keyboardHide, color: _keyColor, size: 20),
          ),
        ],
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    this.label,
    required this.semantics,
    required this.onTap,
    this.active = false,
    this.child,
  });

  final String? label;
  final String semantics;
  final VoidCallback onTap;
  final bool active;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        label: semantics,
        excludeSemantics: true,
        onTap: onTap,
        child: Material(
          color: active ? _activeBackground : Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Center(
              child: child ??
                  Text(
                    label!,
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: active ? _activeForeground : _keyColor,
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
