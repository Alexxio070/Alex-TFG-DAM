import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../data/models/metrics.dart';
import '../../settings/settings_viewmodel.dart';
import 'metric_card.dart';

const _holdDuration = Duration(seconds: 1);
const _holdSlop = 10.0;

class DiskCard extends StatefulWidget {
  const DiskCard({
    super.key,
    required this.partitions,
    required this.selected,
    required this.unit,
    required this.onSelect,
  });

  final List<Partition> partitions;
  final Partition selected;
  final StorageUnit unit;
  final ValueChanged<String> onSelect;

  @override
  State<DiskCard> createState() => _DiskCardState();
}

class _DiskCardState extends State<DiskCard> {
  final _menu = OverlayPortalController();
  final _link = LayerLink();
  Timer? _holdTimer;
  Offset? _holdStart;
  bool _pressing = false;
  double _width = 0;

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  void _openMenu() {
    _width = context.size?.width ?? 0;
    _menu.show();
  }

  void _toggleMenu() {
    if (_menu.isShowing) {
      _menu.hide();
    } else {
      _openMenu();
    }
  }

  void _pressStart(PointerDownEvent e) {
    _holdTimer?.cancel();
    _holdStart = e.position;
    setState(() => _pressing = true);
    _holdTimer = Timer(_holdDuration, () {
      _holdStart = null;
      setState(() => _pressing = false);
      _openMenu();
    });
  }

  void _pressMove(PointerMoveEvent e) {
    final start = _holdStart;
    if (start != null && (e.position - start).distance > _holdSlop) _pressEnd();
  }

  void _pressEnd([PointerEvent? _]) {
    _holdTimer?.cancel();
    _holdStart = null;
    if (_pressing) setState(() => _pressing = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final unit = widget.unit;
    final p = widget.selected;
    final pct = p.usedGb / p.totalGb * 100;
    final label = unit.label;
    return OverlayPortal(
      controller: _menu,
      overlayChildBuilder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _menu.hide,
              child: const SizedBox.expand(),
            ),
          ),
          CompositedTransformFollower(
            link: _link,
            targetAnchor: Alignment.topLeft,
            followerAnchor: Alignment.topLeft,
            offset: const Offset(12, 60),
            child: SizedBox(
              width: _width - 24,
              child: Material(
                type: MaterialType.transparency,
                child: _PartitionMenu(
                  partitions: widget.partitions,
                  selectedId: p.id,
                  unit: unit,
                  onPick: (id) {
                    _menu.hide();
                    widget.onSelect(id);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      child: CompositedTransformTarget(
        link: _link,
        child: Listener(
          onPointerDown: _pressStart,
          onPointerMove: _pressMove,
          onPointerUp: _pressEnd,
          onPointerCancel: _pressEnd,
          child: AnimatedScale(
            duration: const Duration(seconds: 1),
            curve: Curves.ease,
            scale: _pressing ? 0.97 : 1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: _pressing ? Border.all(color: t.accent, width: 2) : null,
              ),
              child: MetricSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 12,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Uso de disco',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: t.muted2,
                          ),
                        ),
                        _PartitionChip(mount: p.mount, onTap: _toggleMenu),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        MetricValue(
                          number: formatNumber(p.usedGb * unit.factor),
                          unit: '/ ${formatNumber(p.totalGb * unit.factor, 0)} $label',
                        ),
                        Text(
                          '${formatNumber(pct, 0)} %',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: t.muted2,
                          ),
                        ),
                      ],
                    ),
                    Semantics(
                      image: true,
                      label: 'Usado ${formatNumber(pct, 0)} % de ${p.mount}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: SizedBox(
                          height: 14,
                          child: Stack(
                            children: [
                              Container(color: t.line),
                              FractionallySizedBox(
                                widthFactor: pct / 100,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: t.accent,
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    DefaultTextStyle(
                      style: TextStyle(fontSize: 12, color: t.muted),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Usado ${formatNumber(p.usedGb * unit.factor)} $label'),
                          Text('Libre ${formatNumber((p.totalGb - p.usedGb) * unit.factor)} $label'),
                        ],
                      ),
                    ),
                    Text(
                      '${p.device} · Mantén pulsado para cambiar de partición',
                      style: TextStyle(fontSize: 12, color: t.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PartitionChip extends StatelessWidget {
  const _PartitionChip({required this.mount, required this.onTap});

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
                mainAxisSize: MainAxisSize.min,
                spacing: 6,
                children: [
                  Text(
                    mount,
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: t.ink,
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

class _PartitionMenu extends StatelessWidget {
  const _PartitionMenu({
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
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(22, 24, 29, 0.22),
            offset: Offset(0, 16),
            blurRadius: 36,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 2,
        children: [
          for (final p in partitions)
            _PartitionOption(
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

class _PartitionOption extends StatelessWidget {
  const _PartitionOption({
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
    final size = '${formatNumber(partition.usedGb * unit.factor)} / '
        '${formatNumber(partition.totalGb * unit.factor, 0)} ${unit.label}';
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(
                        partition.mount,
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                      Text(
                        '${partition.device} · $size',
                        style: TextStyle(fontSize: 12, color: t.muted),
                      ),
                    ],
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
