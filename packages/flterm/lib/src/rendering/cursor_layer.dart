import 'package:flutter/painting.dart';
import 'package:libghostty/libghostty.dart';

import 'terminal_paint_context.dart';

class CursorLayer extends TerminalLayer {
  final _paint = Paint();

  CursorLayer(super.context);

  @override
  void paint(Canvas canvas, Offset offset) {
    final cursor = context.cursor;
    if (!_shouldRepaint(cursor)) return;

    final metrics = context.metrics;
    final effectiveShape = !cursor.focused && cursor.shape == .block
        ? CursorShape.blockHollow
        : cursor.shape;

    _paint.color = cursor.color;
    final endCol = (cursor.col + (cursor.wide ? 2 : 1)).clamp(0, context.cols);
    final rect = metrics.cellRangeRect(cursor.row, cursor.col, endCol, offset);

    switch (effectiveShape) {
      case CursorShape.block:
        _paint.style = PaintingStyle.fill;
        canvas.drawRect(rect, _paint);
        if (cursor.glyph != null) {
          canvas.save();
          canvas.clipRect(rect.inflate(1));
          canvas.drawParagraph(
            cursor.glyph!,
            rect.topLeft + cursor.glyphOffset,
          );
          canvas.restore();
        }

      case CursorShape.blockHollow:
        _paint
          ..style = .stroke
          ..strokeWidth = 1.5;
        canvas.drawRect(rect, _paint);

      case CursorShape.underline:
        _paint.style = .fill;
        final thickness = (metrics.cellHeight / 8).clamp(1.0, 3.0);
        canvas.drawRect(
          Rect.fromLTWH(
            rect.left,
            rect.bottom - thickness,
            rect.width,
            thickness,
          ),
          _paint,
        );

      case CursorShape.bar:
        _paint.style = .fill;
        final thickness = (metrics.cellWidth / 6).clamp(1.0, 3.0);
        canvas.drawRect(
          Rect.fromLTWH(rect.left, rect.top, thickness, rect.height),
          _paint,
        );
    }
  }

  bool _shouldRepaint(CursorPaintState cursor) {
    return !cursor.scrolling &&
        cursor.visible &&
        cursor.row >= 0 &&
        cursor.row < context.rows &&
        cursor.col >= 0 &&
        cursor.col < context.cols &&
        context.blinkVisible;
  }
}
