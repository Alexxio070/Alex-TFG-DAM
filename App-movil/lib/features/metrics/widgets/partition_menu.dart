// Selector de partición de la tarjeta de disco.

import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../data/models/metrics.dart';
import '../../../data/models/settings.dart';

/// Botón con la partición actual que abre el menú.
class PartitionChip extends StatelessWidget {
  const PartitionChip({super.key, required this.mount, required this.onTap});

  final String mount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      label: 'Cambiar partición',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: t.field,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: t.borderStrong),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 10, 0),
            child: SizedBox(
              height: 36,
              child: Row(
                spacing: 6,
                children: [
                  Flexible(
                    child: Text(
                      mount,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: kMonoFont,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: t.ink,
                      ),
                    ),
                  ),
                  AppIconView(AppIcon.chevronDown, color: t.ink, size: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Lista de particiones para elegir una.
class PartitionMenu extends StatelessWidget {
  const PartitionMenu({
    super.key,
    required this.partitions,
    required this.selectedId,
    required this.unit,
    required this.onPick,
  });

  final List<Partition> partitions;
  final String selectedId;
  final StorageUnit unit;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kShadowColor.withValues(alpha: 0.22),
            offset: const Offset(0, 16),
            blurRadius: 36,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 2,
        children: [
          for (final p in partitions)
            PartitionOption(
              partition: p,
              selected: p.id == selectedId,
              unit: unit,
              onTap: () => onPick(p.id),
            ),
        ],
      ),
    );
  }
}

/// Una partición del menú, con su uso.
class PartitionOption extends StatelessWidget {
  const PartitionOption({
    super.key,
    required this.partition,
    required this.selected,
    required this.unit,
    required this.onTap,
  });

  final Partition partition;
  final bool selected;
  final StorageUnit unit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = selected ? t.accent : t.ink;
    final size =
        '${unit.format(partition.usedGb)} / '
        '${unit.format(partition.totalGb, decimals: 0)} ${unit.label}';
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? t.accent.withValues(alpha: 0x14 / 255) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                          partition.mount,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: kMonoFont,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                        Text(
                          '${partition.device} · $size',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: t.muted),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    AppIconView(AppIcon.check, color: color, size: 20, strokeWidth: 2.2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
