import 'dart:ui';

const columns = 2;
const gap = 18.0;
const sideMargin = 20.0;
const topMargin = 24.0;

// Proporción de la altura disponible que ocupa la cuadrícula, igual que en
// el diseño original (576/780).
const gridHeightRatio = 576 / 780;
const trashBottomOffset = 72.0;

class Geometry {
  Geometry(Size size, double bottomInset)
      : tile = (size.width - 2 * sideMargin - gap) / columns,
        gridHeight = size.height * gridHeightRatio,
        trash = Offset(size.width / 2, size.height - trashBottomOffset - bottomInset),
        width = size.width;

  final double tile;
  final double gridHeight;
  final Offset trash;
  final double width;

  Offset slot(int index) => Offset(
        sideMargin + (index % columns) * (tile + gap),
        topMargin + (index ~/ columns) * (tile + gap),
      );

  double contentHeight(int count) => topMargin + ((count + columns - 1) ~/ columns) * (tile + gap);
}

class Press {
  Press(this.pointer, this.id, this.start, this.scroll0) : last = start;

  final int pointer;
  final String id;
  final Offset start;
  final double scroll0;
  Offset last;
  bool moved = false;
}

class Drag {
  const Drag({required this.id, required this.pos, required this.offset});

  final String id;
  final Offset pos;
  final Offset offset;

  Drag at(Offset p) => Drag(id: id, pos: p, offset: offset);
}

sealed class Hit {}

class TrashHit extends Hit {}

class MergeHit extends Hit {
  MergeHit(this.index);
  final int index;
}

class MoveHit extends Hit {
  MoveHit(this.index);
  final int index;
}
