// Tarjeta de uso de disco con su selector de partición.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/models/metrics.dart';
import '../../../data/models/settings.dart';
import 'metric_card.dart';
import 'partition_menu.dart';

const _holdDuration = Duration(seconds: 1);
const _holdSlop = 10.0;
const _menuOffset = Offset(12, 60);
const _menuBottomMargin = 16.0;

/// Uso de la partición elegida; mantenerla pulsada 1 s abre el menú de particiones.
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
  double _anchorTop = 0;

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  void _openMenu() {
    final box = context.findRenderObject() as RenderBox;
    _width = box.size.width;
    _anchorTop = box.localToGlobal(Offset.zero).dy;
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
    final pct = p.totalGb == 0 ? 0.0 : p.usedGb / p.totalGb * 100;
    final label = unit.label;
    return OverlayPortal(
      controller: _menu,
      overlayChildBuilder: (overlayContext) {
        final screenHeight = MediaQuery.sizeOf(overlayContext).height;
        final bottomInset = MediaQuery.paddingOf(overlayContext).bottom;
        final maxMenuHeight = (screenHeight - _anchorTop - _menuOffset.dy - bottomInset - _menuBottomMargin)
            .clamp(0.0, double.infinity);
        return Stack(
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
              offset: _menuOffset,
              child: SizedBox(
                width: _width - 24,
                child: Material(
                  type: MaterialType.transparency,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxMenuHeight),
                    child: SingleChildScrollView(
                      child: PartitionMenu(
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
              ),
            ),
          ],
        );
      },
      child: CompositedTransformTarget(
        link: _link,
        child: Listener(
          onPointerDown: _pressStart,
          onPointerMove: _pressMove,
          onPointerUp: _pressEnd,
          onPointerCancel: _pressEnd,
          child: AnimatedScale(
            duration: _holdDuration,
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
                      spacing: 12,
                      children: [
                        Text(
                          'Uso de disco',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: t.muted2,
                          ),
                        ),
                        Flexible(child: PartitionChip(mount: p.mount, onTap: _toggleMenu)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        MetricValue(
                          number: unit.format(p.usedGb),
                          unit: '/ ${unit.format(p.totalGb, decimals: 0)} $label',
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
                        spacing: 8,
                        children: [
                          Flexible(
                            child: Text(
                              'Usado ${unit.format(p.usedGb)} $label',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              'Libre ${unit.format(p.totalGb - p.usedGb)} $label',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
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

