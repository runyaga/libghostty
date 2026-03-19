import 'dart:ui';

import 'package:libghostty/libghostty.dart';

import '../foundation.dart' show CellMetrics, TerminalSelection;
import 'style_resolver.dart';

class CursorPaintState {
  Paragraph? glyph;
  var glyphOffset = Offset.zero;
  var row = -1;
  var col = -1;
  var shape = CursorShape.block;
  var visible = false;
  var wide = false;
  var color = const Color(0xFFFFFFFF);
  var cellContent = ' ';
  var focused = true;
  var scrolling = false;

  void dispose() => invalidateGlyph();

  void invalidateGlyph() {
    glyph?.dispose();
    glyph = null;
    glyphOffset = Offset.zero;
  }
}

abstract class TerminalLayer {
  final TerminalPaintContext context;

  TerminalLayer(this.context);

  void paint(Canvas canvas, Offset offset);
}

class TerminalPaintContext {
  StyleResolver styles;
  CellMetrics metrics;
  Color selectionColor;
  TerminalSelection? selection;

  var rows = 0;
  var cols = 0;
  var blinkVisible = true;
  var scrollbackLength = 0;
  var rowOffset = 0;

  final cursor = CursorPaintState();

  TerminalPaintContext(
    this.styles,
    this.metrics, {
    required this.selectionColor,
  });
}
