import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_switch.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/modal_card.dart';
import '../home_viewmodel.dart';

Future<void> showNewMacroDialog(BuildContext context) {
  final vm = context.read<HomeViewModel>();
  return showTopCard(
    context,
    top: 180,
    side: 20,
    builder: (_) => _NewMacroCard(vm: vm),
  );
}

class _NewMacroCard extends StatefulWidget {
  const _NewMacroCard({required this.vm});

  final HomeViewModel vm;

  @override
  State<_NewMacroCard> createState() => _NewMacroCardState();
}

class _NewMacroCardState extends State<_NewMacroCard> {
  final _name = TextEditingController();
  final _command = TextEditingController();
  bool _confirm = false;

  bool get _valid => _name.text.trim().isNotEmpty && _command.text.trim().isNotEmpty;

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
            _Field(
              label: 'Nombre',
              child: AppTextField(
                controller: _name,
                focusColor: t.accent,
                hint: 'Ej. Silenciar',
                onChanged: (_) => setState(() {}),
              ),
            ),
            _Field(
              label: 'Comando',
              child: AppTextField(
                controller: _command,
                focusColor: t.accent,
                hint: 'Ej. pactl set-sink-mute @DEFAULT_SINK@ toggle',
                mono: true,
                onChanged: (_) => setState(() {}),
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
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: t.ink,
                        ),
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
                  child: AppButton(
                    label: 'Cancelar',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
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

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.tokens.muted2,
          ),
        ),
        child,
      ],
    );
  }
}
