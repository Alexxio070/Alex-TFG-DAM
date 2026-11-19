// Diálogo para crear una macro.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/app_switch.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/field_label.dart';
import '../../../core/widgets/modal_card.dart';
import '../../../data/models/home_item.dart';
import '../home_viewmodel.dart';
import 'item_tile.dart';

/// Pide nombre (único y de hasta 50 caracteres), comando, icono y si pide confirmación, y crea la
/// macro.
Future<void> showNewMacroDialog(BuildContext context) {
  final vm = context.read<HomeViewModel>();
  return showTopCard(context, top: 180, side: 20, builder: (_) => _NewMacroCard(vm: vm));
}

class _NewMacroCard extends StatefulWidget {
  const _NewMacroCard({required this.vm});

  final HomeViewModel vm;

  @override
  State<_NewMacroCard> createState() => _NewMacroCardState();
}

const _kMaxNameLength = 50;

class _NewMacroCardState extends State<_NewMacroCard> {
  final _name = TextEditingController();
  final _command = TextEditingController();
  bool _confirm = false;
  MacroKind _kind = MacroKind.bolt;

  String? get _nameError {
    final name = _name.text.trim();
    if (name.isEmpty) return null;
    if (name.length > _kMaxNameLength) {
      return 'Máximo $_kMaxNameLength caracteres';
    }
    final taken = widget.vm.items.any((item) {
      final label = switch (item) {
        Macro() => item.label,
        Folder() => item.name,
      };
      return label.toLowerCase() == name.toLowerCase();
    });
    if (taken) return 'Ya hay un elemento con ese nombre';
    return null;
  }

  bool get _valid =>
      _name.text.trim().isNotEmpty && _nameError == null && _command.text.trim().isNotEmpty;

  @override
  void dispose() {
    _name.dispose();
    _command.dispose();
    super.dispose();
  }

  void _create() {
    widget.vm.createMacro(
      name: _name.text.trim(),
      command: _command.text.trim(),
      confirm: _confirm,
      kind: _kind,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      label: 'Nueva macro',
      child: ModalCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 18,
          children: [
            Text(
              'Nueva macro',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: t.ink),
            ),
            FieldLabel(
              label: 'Nombre',
              error: _nameError,
              child: AppTextField(
                controller: _name,
                focusColor: t.accent,
                hint: 'Ej. Silenciar',
                onChanged: (_) => setState(() {}),
              ),
            ),
            FieldLabel(
              label: 'Comando',
              child: AppTextField(
                controller: _command,
                focusColor: t.accent,
                hint: 'Ej. pactl set-sink-mute @DEFAULT_SINK@ toggle',
                mono: true,
                onChanged: (_) => setState(() {}),
              ),
            ),
            FieldLabel(
              label: 'Icono',
              child: Row(
                spacing: 10,
                children: [
                  for (final kind in MacroKind.values)
                    _IconOption(
                      kind: kind,
                      selected: kind == _kind,
                      onTap: () => setState(() => _kind = kind),
                    ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(
                        'Pedir confirmación',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: t.ink),
                      ),
                      Text(
                        'Pregunta antes de ejecutarla',
                        style: TextStyle(fontSize: 12, color: t.muted),
                      ),
                    ],
                  ),
                ),
                AppSwitch(
                  value: _confirm,
                  label: 'Pedir confirmación',
                  onChanged: (v) => setState(() => _confirm = v),
                ),
              ],
            ),
            Row(
              spacing: 12,
              children: [
                Expanded(
                  child: AppButton(label: 'Cancelar', onPressed: () => Navigator.of(context).pop()),
                ),
                Expanded(
                  child: AppButton(
                    label: 'Crear',
                    fill: t.accent,
                    onPressed: _valid ? _create : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IconOption extends StatelessWidget {
  const _IconOption({required this.kind, required this.selected, required this.onTap});

  final MacroKind kind;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      selected: selected,
      label: switch (kind) {
        MacroKind.volume => 'Volumen',
        MacroKind.lock => 'Candado',
        MacroKind.moon => 'Luna',
        MacroKind.bolt => 'Rayo',
      },
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: t.surface,
            border: Border.all(color: selected ? t.accent : t.border, width: selected ? 2 : 1),
          ),
          child: Center(child: AppIconView(iconFor(kind), color: t.accent, size: 22)),
        ),
      ),
    );
  }
}
