// Hoja para cambiar el nombre y el color de una carpeta.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/field_label.dart';
import '../../../core/widgets/modal_card.dart';
import '../../../data/models/home_item.dart';
import '../home_viewmodel.dart';

/// Edita el nombre y el color de [folder].
Future<void> showFolderEditSheet(BuildContext context, Folder folder) {
  final vm = context.read<HomeViewModel>();
  return showBottomCard(
    context,
    builder: (_) => _FolderEditCard(vm: vm, folder: folder),
  );
}

class _FolderEditCard extends StatefulWidget {
  const _FolderEditCard({required this.vm, required this.folder});

  final HomeViewModel vm;
  final Folder folder;

  @override
  State<_FolderEditCard> createState() => _FolderEditCardState();
}

class _FolderEditCardState extends State<_FolderEditCard> {
  late final _name = TextEditingController(text: widget.folder.name);
  late Color _color = widget.folder.color;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    widget.vm.updateFolder(widget.folder.id, name: _name.text, color: _color);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Semantics(
        label: 'Editar carpeta',
        child: BottomSheetCard(
          bottomPadding: 28,
          children: [
            Text(
              'Editar carpeta',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: t.ink),
            ),
            FieldLabel(
              label: 'Nombre',
              child: AppTextField(controller: _name, focusColor: _color),
            ),
            FieldLabel(
              label: 'Color',
              crossAxisAlignment: CrossAxisAlignment.start,
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (var i = 0; i < kAccentColors.length; i++)
                    _Swatch(
                      color: kAccentColors[i],
                      label: kAccentNames[i],
                      selected: kAccentColors[i] == _color,
                      onTap: () => setState(() => _color = kAccentColors[i]),
                    ),
                ],
              ),
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
                  child: AppButton(label: 'Guardar', fill: _color, onPressed: _save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surface = context.tokens.surface;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: selected
                ? [
                    BoxShadow(color: surface, spreadRadius: 3),
                    BoxShadow(color: color, spreadRadius: 5),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}
