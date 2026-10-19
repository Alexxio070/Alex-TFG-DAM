import 'package:flutter/material.dart';

import '../../../core/widgets/app_icon.dart';
import '../terminal_tabs_viewmodel.dart';
import 'close_tab_dialog.dart';

const _barBackground = Color(0xFF15171A);
const _barBorder = Color(0xFF2B2F34);
const _textColor = Color(0xFFE6E8EB);
const _mutedTextColor = Color(0xFF9AA4AF);
const _activeBackground = Color(0xFF0D0F12);

class TerminalTabsBar extends StatelessWidget {
  const TerminalTabsBar({super.key, required this.vm});

  final TerminalTabsViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: _barBackground,
        border: Border(bottom: BorderSide(color: _barBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: vm.tabs.length,
              itemBuilder: (context, index) {
                final tab = vm.tabs[index];
                return _TabChip(
                  label: 'Terminal ${index + 1}',
                  active: index == vm.activeIndex,
                  onTap: () => vm.selectTab(index),
                  onClose: () => showCloseTabDialog(context, onClose: () => vm.closeTab(tab)),
                );
              },
            ),
          ),
          Semantics(
            button: true,
            label: 'Nueva pestaña',
            excludeSemantics: true,
            onTap: vm.addTab,
            child: InkWell(
              onTap: vm.addTab,
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Center(child: AppIconView(AppIcon.plus, color: _textColor, size: 20)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.active,
    required this.onTap,
    required this.onClose,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Material(
        color: active ? _activeBackground : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.only(left: 14, right: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              Semantics(
                button: true,
                label: label,
                selected: active,
                excludeSemantics: true,
                onTap: onTap,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(10),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: active ? _textColor : _mutedTextColor,
                    ),
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: 'Cerrar $label',
                excludeSemantics: true,
                onTap: onClose,
                child: InkWell(
                  onTap: onClose,
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: AppIconView(AppIcon.close, color: _mutedTextColor, size: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
