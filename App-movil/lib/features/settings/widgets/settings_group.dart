// Grupo y fila de la lista de Ajustes.

import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';

/// Título y caja con [children] separados por líneas.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 0),
          child: Text(
            title,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.muted),
          ),
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: t.surface,
            border: Border.all(color: t.border),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) Divider(height: 1, thickness: 1, color: t.line),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Fila con etiqueta, subtítulo opcional y control a la derecha.
class SettingsRow extends StatelessWidget {
  const SettingsRow({super.key, required this.label, this.sublabel, required this.trailing});

  final String label;
  final String? sublabel;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 60),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          spacing: 12,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: t.ink),
                  ),
                  if (sublabel != null)
                    Text(sublabel!, style: TextStyle(fontSize: 12, color: t.muted)),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
