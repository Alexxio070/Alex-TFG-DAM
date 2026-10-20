import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/open_link.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_fab.dart';
import '../../core/widgets/app_icon.dart';
import '../../core/widgets/app_toast.dart';
import '../../data/models/note.dart';
import 'note_form_view.dart';
import 'notes_viewmodel.dart';
import 'widgets/note_card.dart';

class NotesView extends StatelessWidget {
  const NotesView({super.key});

  Future<void> _copy(NotesViewModel vm, Note note) async {
    await Clipboard.setData(ClipboardData(text: note.content));
    vm.showMessage('Copiado');
  }

  Future<void> _open(NotesViewModel vm, String url) async {
    if (!await openLink(url)) vm.showMessage('No se pudo abrir el enlace');
  }

  void _openForm(BuildContext context, [Note? note]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => NoteFormView(note: note)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotesViewModel>();
    final message = vm.message;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: _SearchField(onChanged: vm.search),
            ),
            Expanded(child: _NotesList(vm: vm, onOpen: _open, onCopy: _copy, onEdit: _openForm)),
          ],
        ),
        Positioned(
          right: 20,
          bottom: 28 + bottomInset,
          child: AppFab(label: 'Nueva nota', onTap: () => _openForm(context)),
        ),
        if (message != null)
          Positioned(
            left: 20,
            right: 96,
            bottom: 28 + bottomInset,
            child: AppToast(text: message),
          ),
      ],
    );
  }
}

class _NotesList extends StatelessWidget {
  const _NotesList({
    required this.vm,
    required this.onOpen,
    required this.onCopy,
    required this.onEdit,
  });

  final NotesViewModel vm;
  final Future<void> Function(NotesViewModel vm, String url) onOpen;
  final Future<void> Function(NotesViewModel vm, Note note) onCopy;
  final void Function(BuildContext context, Note note) onEdit;

  @override
  Widget build(BuildContext context) {
    if (!vm.isPaired) {
      return const _Placeholder(
        title: 'Sin emparejar',
        body: 'Empareja el móvil para ver tus notas.',
      );
    }
    if (vm.loading && vm.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.items.isEmpty) {
      return vm.query.isEmpty
          ? const _Placeholder(
              title: 'Aún no hay notas',
              body: 'Crea una nota para dejarla también en tu PC.',
            )
          : _Placeholder(title: 'Sin resultados para «${vm.query}»', body: '');
    }
    return RefreshIndicator(
      onRefresh: vm.load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(12, 8, 12, 100 + MediaQuery.paddingOf(context).bottom),
        itemCount: vm.items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final note = vm.items[index];
          return NoteCard(
            key: ValueKey(note.id),
            note: note,
            onOpenLink: (url) => onOpen(vm, url),
            onCopy: () => onCopy(vm, note),
            onEdit: () => onEdit(context, note),
          );
        },
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: t.ink),
            ),
            if (body.isNotEmpty)
              Text(
                body,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: t.muted),
              ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SizedBox(
      height: 36,
      child: TextField(
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: TextStyle(fontSize: 14, color: t.ink),
        decoration: InputDecoration(
          isCollapsed: true,
          filled: true,
          fillColor: t.surface,
          hintText: 'Buscar notas',
          hintStyle: TextStyle(color: t.muted),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: AppIconView(AppIcon.search, color: t.muted, size: 16),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 36),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: t.borderStrong),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: t.accent, width: 2),
          ),
        ),
      ),
    );
  }
}
