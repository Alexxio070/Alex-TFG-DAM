// Menú lateral: secciones, botón de Ajustes y estado de conexión.

import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_icon.dart';
import '../shell_viewmodel.dart';
import '../../../core/widgets/app_top_bar.dart';

const _navSections = [Section.home, Section.metrics, Section.terminal, Section.notes];

const _icons = {
  Section.home: AppIcon.home,
  Section.metrics: AppIcon.metrics,
  Section.terminal: AppIcon.terminal,
  Section.notes: AppIcon.notes,
};

/// Lista de secciones; elegir una llama a [onSelect].
class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.active,
    required this.paired,
    required this.onSelect,
    required this.onClose,
  });

  final Section active;
  final bool paired;
  final ValueChanged<Section> onSelect;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final padding = MediaQuery.paddingOf(context);
    return Container(
      width: kDrawerWidth,
      decoration: BoxDecoration(
        color: t.surface,
        boxShadow: [
          BoxShadow(
            color: kShadowColor.withValues(alpha: 0.18),
            offset: const Offset(12, 0),
            blurRadius: 32,
          ),
        ],
      ),
      child: Column(
        children: [
          AppTopBar(
            title: active.label,
            icon: AppIcon.close,
            iconLabel: 'Cerrar menú',
            borderColor: t.line,
            onIcon: onClose,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  for (final section in _navSections) ...[
                    _NavItem(
                      section: section,
                      selected: section == active,
                      onTap: () => onSelect(section),
                    ),
                    if (section != _navSections.last) const SizedBox(height: 4),
                  ],
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(12, 12, 12, 24 + padding.bottom),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: t.line))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SettingsButton(
                  selected: active == Section.settings,
                  onTap: () => onSelect(Section.settings),
                ),
                _ConnectionStatus(paired: paired),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.section, required this.selected, required this.onTap});

  final Section section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = selected ? Colors.white : t.ink;
    return Material(
      color: selected ? t.accent : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Center(child: AppIconView(_icons[section]!, color: color)),
              ),
              const SizedBox(width: 14),
              Text(
                section.label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      label: 'Ajustes',
      child: Material(
        color: selected ? t.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: AppIconView(AppIcon.settings, color: selected ? Colors.white : t.ink),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConnectionStatus extends StatelessWidget {
  const _ConnectionStatus({required this.paired});

  final bool paired;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: paired ? kGreen : t.off,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            paired ? 'Conectado' : 'Sin emparejar',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: paired ? t.greenText : t.muted,
            ),
          ),
        ],
      ),
    );
  }
}
