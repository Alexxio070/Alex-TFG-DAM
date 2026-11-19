// Cuadrícula de Inicio con sus gestos: tocar, mantener, arrastrar, agrupar, borrar y autoscroll.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/models/home_item.dart';
import 'item_tile.dart';
import 'macro_grid_geometry.dart';
import 'trash_indicator.dart';

const _scrollAfter = 6;
const _longPress = Duration(milliseconds: 420);
const _editHold = Duration(milliseconds: 1500);
const _moveSlop = 8.0;
const _mergeZone = 52.0;
const _trashRadius = 52.0;
const _autoScrollZone = 50.0;
const _autoScrollStep = 10.0;

/// Cuadrícula de [items]. No cambia el estado: avisa de cada gesto con sus callbacks y
/// [HomeViewModel] decide.
class MacroGrid extends StatefulWidget {
  const MacroGrid({
    super.key,
    required this.items,
    required this.onTap,
    required this.onEditFolder,
    required this.onMove,
    required this.onMerge,
    required this.onDelete,
    required this.onDraggingChanged,
  });

  final List<HomeItem> items;
  final ValueChanged<HomeItem> onTap;
  final ValueChanged<Folder> onEditFolder;
  final void Function(String id, int index) onMove;
  final void Function(String id, int index) onMerge;
  final ValueChanged<String> onDelete;
  final ValueChanged<bool> onDraggingChanged;

  @override
  State<MacroGrid> createState() => _MacroGridState();
}

class _MacroGridState extends State<MacroGrid> {
  final _scroll = ScrollController();
  late Geometry _geo = Geometry(Size.zero, 0);
  Press? _press;
  Drag? _drag;
  Timer? _longTimer;
  Timer? _editTimer;

  bool get _scrollable => widget.items.length > _scrollAfter;
  double get _offset => _scroll.hasClients ? _scroll.offset : 0;

  @override
  void dispose() {
    _longTimer?.cancel();
    _editTimer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollTo(double value) {
    if (!_scroll.hasClients) return;
    _scroll.jumpTo(value.clamp(0, _scroll.position.maxScrollExtent));
  }

  int? _tileAt(Offset p) {
    if (p.dy < 0 || p.dy > _geo.gridHeight) return null;
    final y = p.dy + _offset;
    for (var i = 0; i < widget.items.length; i++) {
      final slot = _geo.slot(i);
      final rect = Rect.fromLTWH(slot.dx, slot.dy, _geo.tile, _geo.tile);
      if (rect.contains(Offset(p.dx, y))) return i;
    }
    return null;
  }

  Hit _hit(Offset p, String draggedId) {
    final items = widget.items;
    if ((p - _geo.trash).distance < _trashRadius) return TrashHit();
    final y = p.dy + _offset;
    final col = (p.dx / (_geo.width / columns)).floor().clamp(0, columns - 1);
    final row = math.max(0, ((y - topMargin + gap / 2) / (_geo.tile + gap)).floor());
    final index = row * columns + col;
    final dragged = items.where((i) => i.id == draggedId).firstOrNull;
    if (index < items.length && items[index].id != draggedId && dragged is Macro) {
      final slot = _geo.slot(index);
      final center = Offset(slot.dx + _geo.tile / 2, slot.dy + _geo.tile / 2);
      if ((p.dx - center.dx).abs() < _mergeZone && (y - center.dy).abs() < _mergeZone) {
        return MergeHit(index);
      }
    }
    return MoveHit(math.min(index, items.length - 1));
  }

  void _onDown(PointerDownEvent e) {
    if (_drag != null || _press != null) return;
    final index = _tileAt(e.localPosition);
    if (index == null) return;
    final item = widget.items[index];
    final press = Press(e.pointer, item.id, e.localPosition, _offset);
    _press = press;
    _longTimer?.cancel();
    _editTimer?.cancel();
    _longTimer = Timer(_longPress, () => _startDrag(press, index));
  }

  void _startDrag(Press press, int index) {
    if (_press != press || press.moved) return;
    final slot = _geo.slot(index);
    final tilePos = Offset(slot.dx, slot.dy - press.scroll0);
    setState(() => _drag = Drag(id: press.id, pos: press.last, offset: press.start - tilePos));
    widget.onDraggingChanged(true);
    final item = widget.items[index];
    if (item is Folder) {
      _editTimer = Timer(_editHold - _longPress, () {
        if (_press != press || press.moved) return;
        _press = null;
        setState(() => _drag = null);
        widget.onDraggingChanged(false);
        widget.onEditFolder(item);
      });
    }
  }

  void _onMove(PointerMoveEvent e) {
    final press = _press;
    if (press == null || e.pointer != press.pointer) return;
    final p = e.localPosition;
    press.last = p;
    if (!press.moved && (p - press.start).distance > _moveSlop) {
      press.moved = true;
      _editTimer?.cancel();
    }
    final drag = _drag;
    if (drag != null) {
      if (_scrollable) {
        if (p.dy > _geo.gridHeight - _autoScrollZone) {
          _scrollTo(_offset + _autoScrollStep);
        } else if (p.dy < _autoScrollZone) {
          _scrollTo(_offset - _autoScrollStep);
        }
      }
      setState(() => _drag = drag.at(p));
    } else if (press.moved && _scrollable) {
      _scrollTo(press.scroll0 - (p.dy - press.start.dy));
    }
  }

  void _onUp(PointerUpEvent e) {
    final press = _press;
    if (press == null || e.pointer != press.pointer) return;
    _longTimer?.cancel();
    _editTimer?.cancel();
    _press = null;
    final drag = _drag;
    if (drag != null) {
      _drop(drag);
    } else if (!press.moved) {
      final item = widget.items.where((i) => i.id == press.id).firstOrNull;
      if (item != null) widget.onTap(item);
    }
  }

  void _onCancel(PointerCancelEvent e) {
    _longTimer?.cancel();
    _editTimer?.cancel();
    _press = null;
    if (_drag != null) {
      setState(() => _drag = null);
      widget.onDraggingChanged(false);
    }
  }

  void _drop(Drag drag) {
    final hit = _hit(drag.pos, drag.id);
    setState(() => _drag = null);
    widget.onDraggingChanged(false);
    switch (hit) {
      case TrashHit():
        widget.onDelete(drag.id);
      case MergeHit(:final index):
        widget.onMerge(drag.id, index);
      case MoveHit(:final index):
        widget.onMove(drag.id, index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    return LayoutBuilder(
      builder: (context, constraints) {
        _geo = Geometry(constraints.biggest, MediaQuery.paddingOf(context).bottom);
        final drag = _drag;
        final hit = drag == null ? null : _hit(drag.pos, drag.id);
        final dragged = drag == null ? null : items.where((i) => i.id == drag.id).firstOrNull;
        final trashHot = hit is TrashHit;
        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _onDown,
          onPointerMove: _onMove,
          onPointerUp: _onUp,
          onPointerCancel: _onCancel,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: _geo.gridHeight,
                child: SingleChildScrollView(
                  controller: _scroll,
                  physics: const NeverScrollableScrollPhysics(),
                  child: SizedBox(
                    height: _geo.contentHeight(items.length),
                    child: Stack(
                      children: [
                        for (var i = 0; i < items.length; i++)
                          _positionedTile(items[i], i, drag, hit),
                      ],
                    ),
                  ),
                ),
              ),
              if (drag != null) ...[
                TrashIndicator(center: _geo.trash, hot: trashHot),
                if (dragged != null)
                  Positioned(
                    left: drag.pos.dx - drag.offset.dx,
                    top: drag.pos.dy - drag.offset.dy,
                    width: _geo.tile,
                    height: _geo.tile,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: trashHot ? 0.55 : 1,
                        child: Transform.scale(
                          scale: 1.05,
                          child: ItemTile(item: dragged, lifted: true),
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _positionedTile(HomeItem item, int index, Drag? drag, Hit? hit) {
    final slot = _geo.slot(index);
    final isTarget = hit is MergeHit && hit.index == index;
    final isDragged = drag?.id == item.id;
    final label = switch (item) {
      Macro() => item.label,
      Folder() => item.name,
    };
    return AnimatedPositioned(
      key: ValueKey(item.id),
      duration: const Duration(milliseconds: 220),
      curve: Curves.ease,
      left: slot.dx,
      top: slot.dy,
      width: _geo.tile,
      height: _geo.tile,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: isDragged ? 0.25 : 1,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: isTarget ? 1.05 : 1,
          child: Semantics(
            button: true,
            label: label,
            excludeSemantics: true,
            onTap: () => widget.onTap(item),
            child: ItemTile(item: item, highlight: isTarget),
          ),
        ),
      ),
    );
  }
}
