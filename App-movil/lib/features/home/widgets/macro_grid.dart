import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../data/models/home_item.dart';
import 'item_tile.dart';

const _columns = 2;
const _gap = 18.0;
const _sideMargin = 20.0;
const _topMargin = 24.0;
const _scrollAfter = 6;
const _longPress = Duration(milliseconds: 420);
const _editHold = Duration(milliseconds: 1500);
const _moveSlop = 8.0;
const _mergeZone = 52.0;
const _trashRadius = 52.0;

class _Geometry {
  _Geometry(Size size, double bottomInset)
      : tile = (size.width - 2 * _sideMargin - _gap) / _columns,
        gridHeight = size.height * 576 / 780,
        trash = Offset(size.width / 2, size.height - 72 - bottomInset),
        width = size.width;

  final double tile;
  final double gridHeight;
  final Offset trash;
  final double width;

  Offset slot(int index) => Offset(
        _sideMargin + (index % _columns) * (tile + _gap),
        _topMargin + (index ~/ _columns) * (tile + _gap),
      );

  double contentHeight(int count) =>
      _topMargin + ((count + _columns - 1) ~/ _columns) * (tile + _gap);
}

class _Press {
  _Press(this.pointer, this.id, this.start, this.scroll0) : last = start;

  final int pointer;
  final String id;
  final Offset start;
  final double scroll0;
  Offset last;
  bool moved = false;
}

class _Drag {
  const _Drag({required this.id, required this.pos, required this.offset});

  final String id;
  final Offset pos;
  final Offset offset;

  _Drag at(Offset p) => _Drag(id: id, pos: p, offset: offset);
}

sealed class _Hit {}

class _TrashHit extends _Hit {}

class _MergeHit extends _Hit {
  _MergeHit(this.index);
  final int index;
}

class _MoveHit extends _Hit {
  _MoveHit(this.index);
  final int index;
}

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
  late _Geometry _geo = _Geometry(Size.zero, 0);
  _Press? _press;
  _Drag? _drag;
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

  _Hit _hit(Offset p, String draggedId) {
    final items = widget.items;
    if ((p - _geo.trash).distance < _trashRadius) return _TrashHit();
    final y = p.dy + _offset;
    final col = p.dx < _geo.width / 2 ? 0 : 1;
    final row = math.max(0, ((y - _topMargin + _gap / 2) / (_geo.tile + _gap)).floor());
    final index = row * _columns + col;
    final dragged = items.where((i) => i.id == draggedId).firstOrNull;
    if (index < items.length && items[index].id != draggedId && dragged is Macro) {
      final slot = _geo.slot(index);
      final center = Offset(slot.dx + _geo.tile / 2, slot.dy + _geo.tile / 2);
      if ((p.dx - center.dx).abs() < _mergeZone && (y - center.dy).abs() < _mergeZone) {
        return _MergeHit(index);
      }
    }
    return _MoveHit(math.min(index, items.length - 1));
  }

  void _onDown(PointerDownEvent e) {
    if (_drag != null || _press != null) return;
    final index = _tileAt(e.localPosition);
    if (index == null) return;
    final item = widget.items[index];
    final press = _Press(e.pointer, item.id, e.localPosition, _offset);
    _press = press;
    _longTimer?.cancel();
    _editTimer?.cancel();
    _longTimer = Timer(_longPress, () => _startDrag(press, index));
  }

  void _startDrag(_Press press, int index) {
    if (_press != press || press.moved) return;
    final slot = _geo.slot(index);
    final tilePos = Offset(slot.dx, slot.dy - press.scroll0);
    setState(() => _drag = _Drag(id: press.id, pos: press.last, offset: press.start - tilePos));
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
        if (p.dy > _geo.gridHeight - 50) {
          _scrollTo(_offset + 10);
        } else if (p.dy < 50) {
          _scrollTo(_offset - 10);
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

  void _drop(_Drag drag) {
    final hit = _hit(drag.pos, drag.id);
    setState(() => _drag = null);
    widget.onDraggingChanged(false);
    switch (hit) {
      case _TrashHit():
        widget.onDelete(drag.id);
      case _MergeHit(:final index):
        widget.onMerge(drag.id, index);
      case _MoveHit(:final index):
        widget.onMove(drag.id, index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    return LayoutBuilder(
      builder: (context, constraints) {
        _geo = _Geometry(constraints.biggest, MediaQuery.paddingOf(context).bottom);
        final drag = _drag;
        final hit = drag == null ? null : _hit(drag.pos, drag.id);
        final dragged = drag == null ? null : items.where((i) => i.id == drag.id).firstOrNull;
        final trashHot = hit is _TrashHit;
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
                _Trash(center: _geo.trash, hot: trashHot),
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

  Widget _positionedTile(HomeItem item, int index, _Drag? drag, _Hit? hit) {
    final slot = _geo.slot(index);
    final isTarget = hit is _MergeHit && hit.index == index;
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

class _Trash extends StatelessWidget {
  const _Trash({required this.center, required this.hot});

  final Offset center;
  final bool hot;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Positioned(
      left: center.dx - 32,
      top: center.dy - 32,
      width: 64,
      height: 64,
      child: IgnorePointer(
        child: AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: hot ? 1.18 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hot ? kRed : t.surface,
              boxShadow: [
                BoxShadow(
                  color: kShadowColor.withValues(alpha: 0.2),
                  offset: const Offset(0, 8),
                  blurRadius: 24,
                ),
              ],
            ),
            child: Center(
              child: AppIconView(AppIcon.trash, color: hot ? Colors.white : kRed, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}
