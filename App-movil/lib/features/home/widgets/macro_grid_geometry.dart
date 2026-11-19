// Medidas de la cuadrícula de Inicio y tipos que usa MacroGrid durante un arrastre.

import 'dart:ui';

const columns = 2;
const gap = 18.0;
const sideMargin = 20.0;
const topMargin = 24.0;

// Proporción de la altura disponible que ocupa la cuadrícula, igual que en
// el diseño original (576/780).
const gridHeightRatio = 576 / 780;
const trashBottomOffset = 72.0;

/// Tamaño de las fichas, altura de la cuadrícula y posición de la papelera según la pantalla.
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

  /// Esquina superior izquierda de la ficha en la posición [index].
  Offset slot(int index) => Offset(
        sideMargin + (index % columns) * (tile + gap),
        topMargin + (index ~/ columns) * (tile + gap),
      );

  /// Altura que ocupan [count] fichas.
  double contentHeight(int count) => topMargin + ((count + columns - 1) ~/ columns) * (tile + gap);
}

/// Pulsación en curso, antes de que se convierta en arrastre o en scroll.
class Press {
  Press(this.pointer, this.id, this.start, this.scroll0) : last = start;

  final int pointer;
  final String id;
  final Offset start;
  final double scroll0;
  Offset last;
  bool moved = false;
}

/// Elemento que se está arrastrando y dónde está.
class Drag {
  const Drag({required this.id, required this.pos, required this.offset});

  final String id;
  final Offset pos;
  final Offset offset;

  Drag at(Offset p) => Drag(id: id, pos: p, offset: offset);
}

/// Dónde caería el elemento si se soltara ahora.
sealed class Hit {}

/// Sobre la papelera.
class TrashHit extends Hit {}

/// Sobre otro elemento, para agruparlos.
class MergeHit extends Hit {
  MergeHit(this.index);
  final int index;
}

/// Sobre un hueco, para reordenar.
class MoveHit extends Hit {
  MoveHit(this.index);
  final int index;
}
