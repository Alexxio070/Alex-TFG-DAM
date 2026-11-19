// Tarjeta de una nota en la lista.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../data/models/note.dart';
import '../../../data/models/note_links.dart';

/// Texto seleccionable con enlaces pulsables, origen, fecha y botones de copiar y editar.
class NoteCard extends StatefulWidget {
  const NoteCard({
    super.key,
    required this.note,
    required this.onOpenLink,
    required this.onCopy,
    required this.onEdit,
  });

  final Note note;
  final ValueChanged<String> onOpenLink;
  final VoidCallback onCopy;
  final VoidCallback onEdit;

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  final _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  TextSpan _content(Color ink, Color accent) {
    _disposeRecognizers();
    final text = widget.note.content;
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final link in findLinks(text)) {
      if (link.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, link.start)));
      }
      final recognizer = TapGestureRecognizer()..onTap = () => widget.onOpenLink(link.url);
      _recognizers.add(recognizer);
      spans.add(
        TextSpan(
          text: text.substring(link.start, link.end),
          recognizer: recognizer,
          style: TextStyle(color: accent, decoration: TextDecoration.underline),
        ),
      );
      cursor = link.end;
    }
    if (cursor < text.length) spans.add(TextSpan(text: text.substring(cursor)));
    return TextSpan(
      style: TextStyle(fontSize: 13, height: 1.4, color: ink),
      children: spans,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final origin = widget.note.origin == NoteOrigin.pc ? 'Desde el PC' : 'Desde el móvil';
    final date = formatRelativeDate(widget.note.updatedAt, DateTime.now());
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 0),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SelectableText.rich(_content(t.ink, t.accent), minLines: 1, maxLines: 3),
          ),
          Row(
            children: [
              Expanded(
                child: Text('$origin · $date', style: TextStyle(fontSize: 11, color: t.muted)),
              ),
              _IconAction(icon: AppIcon.copy, label: 'Copiar nota', onTap: widget.onCopy),
              _IconAction(icon: AppIcon.edit, label: 'Editar nota', onTap: widget.onEdit),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({required this.icon, required this.label, required this.onTap});

  final AppIcon icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(child: AppIconView(icon, color: context.tokens.muted2, size: 20)),
        ),
      ),
    );
  }
}
