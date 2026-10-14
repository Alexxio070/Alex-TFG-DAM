import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_icon.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/modal_card.dart';
import '../../data/models/note.dart';
import '../shell/widgets/app_top_bar.dart';
import 'notes_viewmodel.dart';

class NoteFormView extends StatefulWidget {
  const NoteFormView({super.key, this.note});

  final Note? note;

  @override
  State<NoteFormView> createState() => _NoteFormViewState();
}

class _NoteFormViewState extends State<NoteFormView> {
  late final _content = TextEditingController(text: widget.note?.content ?? '');

  bool get _editing => widget.note != null;
  bool get _valid => _content.text.trim().isNotEmpty;

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final vm = context.read<NotesViewModel>();
    final navigator = Navigator.of(context);
    await vm.save(id: widget.note?.id, content: _content.text);
    navigator.pop();
  }

  Future<void> _confirmDelete() {
    final vm = context.read<NotesViewModel>();
    final navigator = Navigator.of(context);
    final id = widget.note!.id;
    return showTopCard(
      context,
      top: 280,
      side: 28,
      builder: (dialogContext) {
        final t = dialogContext.tokens;
        return Semantics(
          label: 'Eliminar nota',
          child: ModalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                Text(
                  '¿Eliminar esta nota?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: t.ink),
                ),
                Text(
                  'También dejará de estar en el PC.',
                  style: TextStyle(fontSize: 14, height: 1.45, color: t.muted2),
                ),
                const SizedBox(height: 6),
                Row(
                  spacing: 12,
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Cancelar',
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                    ),
                    Expanded(
                      child: AppButton(
                        label: 'Eliminar',
                        fill: kRed,
                        onPressed: () async {
                          Navigator.of(dialogContext).pop();
                          await vm.delete(id);
                          navigator.pop();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      backgroundColor: t.bg,
      body: Column(
        children: [
          AppTopBar(
            title: _editing ? 'Editar nota' : 'Nueva nota',
            icon: AppIcon.close,
            iconLabel: 'Cerrar sin guardar',
            onMenu: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.paddingOf(context).bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  Text(
                    'Contenido',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: t.muted2,
                    ),
                  ),
                  AppTextField(
                    controller: _content,
                    focusColor: t.accent,
                    multiline: true,
                    autofocus: !_editing,
                    onChanged: (_) => setState(() {}),
                  ),
                  if (_editing)
                    Text(
                      'Si también la editas en el PC, se conserva el último cambio guardado.',
                      style: TextStyle(fontSize: 11, color: t.muted),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    spacing: 12,
                    children: [
                      if (_editing)
                        Expanded(
                          child: AppButton(
                            label: 'Eliminar',
                            textColor: kRed,
                            onPressed: _confirmDelete,
                          ),
                        ),
                      Expanded(
                        child: AppButton(
                          label: 'Guardar',
                          fill: t.accent,
                          onPressed: _valid ? _save : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
