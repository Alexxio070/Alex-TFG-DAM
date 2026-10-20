import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_icon.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/confirm_card.dart';
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
  bool _saving = false;
  String? _error;

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
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await vm.save(id: widget.note?.id, content: _content.text);
      navigator.pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'No se pudo guardar la nota';
        });
      }
    }
  }

  Future<void> _confirmDelete() {
    final vm = context.read<NotesViewModel>();
    final navigator = Navigator.of(context);
    final id = widget.note!.id;
    return showConfirmCard(
      context,
      title: '¿Eliminar esta nota?',
      body: 'También dejará de estar en el PC.',
      confirmLabel: 'Eliminar',
      semanticsLabel: 'Eliminar nota',
      onConfirm: () async {
        try {
          await vm.delete(id);
          navigator.pop();
        } catch (_) {
          if (mounted) setState(() => _error = 'No se pudo eliminar la nota');
        }
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
                  if (_error != null)
                    Text(_error!, style: const TextStyle(fontSize: 12, color: kRed)),
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
                          onPressed: _valid && !_saving ? _save : null,
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
