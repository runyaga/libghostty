import 'package:flutter/painting.dart';

import 'terminal_paint_context.dart';

class SelectionLayer extends TerminalLayer {
  final _paint = Paint();

  SelectionLayer(super.context);

  @override
  void paint(Canvas canvas, Offset offset) {
    final selection = context.selection;
    if (selection == null) return;

    final rows = context.rows;
    final cols = context.cols;
    final metrics = context.metrics;

    final rowBase = context.scrollbackLength - context.rowOffset;
    final selTopRow = selection.topRow - rowBase;
    final selBottomRow = selection.bottomRow - rowBase;

    if (selBottomRow < 0 || selTopRow >= rows) return;
    final topRow = selTopRow.clamp(0, rows - 1);
    final bottomRow = selBottomRow.clamp(0, rows - 1);
    final isBlockSelection = selection.mode == .block;
    final topCol = selTopRow < 0 && !isBlockSelection
        ? 0
        : selection.topCol.clamp(0, cols);
    final bottomCol = selBottomRow >= rows && !isBlockSelection
        ? cols
        : selection.bottomCol.clamp(0, cols);

    _paint.color = context.selectionColor;

    if (isBlockSelection) {
      if (topCol >= bottomCol) return;
      canvas.drawRect(
        Rect.fromLTWH(
          offset.dx + topCol * metrics.cellWidth,
          offset.dy + topRow * metrics.cellHeight,
          (bottomCol - topCol) * metrics.cellWidth,
          (bottomRow - topRow + 1) * metrics.cellHeight,
        ),
        _paint,
      );
      return;
    }

    if (topRow == bottomRow) {
      if (topCol >= bottomCol) return;
      canvas.drawRect(
        metrics.cellRangeRect(topRow, topCol, bottomCol, offset),
        _paint,
      );
      return;
    }

    if (topCol < cols) {
      canvas.drawRect(
        metrics.cellRangeRect(topRow, topCol, cols, offset),
        _paint,
      );
    }

    if (bottomRow - topRow > 1) {
      canvas.drawRect(
        Rect.fromLTWH(
          offset.dx,
          offset.dy + (topRow + 1) * metrics.cellHeight,
          cols * metrics.cellWidth,
          (bottomRow - topRow - 1) * metrics.cellHeight,
        ),
        _paint,
      );
    }

    if (bottomCol > 0) {
      canvas.drawRect(
        metrics.cellRangeRect(bottomRow, 0, bottomCol, offset),
        _paint,
      );
    }
  }
}
