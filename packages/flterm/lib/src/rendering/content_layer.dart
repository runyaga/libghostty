import 'package:flutter/painting.dart';

import 'content_cache.dart';
import 'terminal_paint_context.dart';

class ContentLayer extends TerminalLayer {
  final _paint = Paint();
  final ContentCache _cache;

  ContentLayer(super.context, this._cache);

  @override
  void paint(Canvas canvas, Offset offset) {
    final rows = context.rows;
    final metrics = context.metrics;
    final cellHeight = metrics.cellHeight;

    for (var row = 0; row < rows; row++) {
      for (final run in _cache.backgroundRunsAt(row)) {
        _paint.color = run.color;
        canvas.drawRect(
          metrics.cellRangeRect(row, run.startCol, run.endCol, offset),
          _paint,
        );
      }
    }

    for (var row = 0; row < rows; row++) {
      final paragraph = _cache.paragraphAt(row);
      if (paragraph != null) {
        canvas.drawParagraph(
          paragraph,
          Offset(offset.dx, offset.dy + row * cellHeight),
        );
      }

      for (final glyph in _cache.glyphsAt(row)) {
        final endCol = glyph.col + glyph.span;
        final cellRect = metrics.cellRangeRect(row, glyph.col, endCol, offset);
        final origin = cellRect.topLeft + glyph.offset;

        if (glyph.span > 1) {
          canvas.save();
          canvas.clipRect(cellRect.inflate(1));
          canvas.drawParagraph(glyph.paragraph, origin);
          canvas.restore();
        } else {
          canvas.drawParagraph(glyph.paragraph, origin);
        }
      }
    }
  }
}
