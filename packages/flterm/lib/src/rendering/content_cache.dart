import 'dart:ui';

import 'package:libghostty/libghostty.dart';

import '../foundation.dart';
import 'cell_style_key.dart';
import 'cell_text.dart';
import 'color_run.dart';
import 'style_resolver.dart';
import 'terminal_paint_context.dart';

const emojiScale = 0.9;

(Paragraph, Offset) buildGlyphParagraph(
  StyleResolver styles,
  CellMetrics metrics,
  Cell cell,
  String content,
  Color foreground, {
  required bool wide,
}) {
  final TextStyle textStyle;
  final double width;

  if (wide) {
    textStyle = styles.wideGlyphStyle(
      foreground,
      emojiScale * metrics.cellHeight,
    );
    width = 2 * metrics.cellWidth;
  } else {
    textStyle = styles.resolveStyle(cell, foreground);
    width = metrics.cellWidth;
  }

  final builder = ParagraphBuilder(styles.paragraphStyle)
    ..pushStyle(textStyle)
    ..addText(content)
    ..pop();

  final paragraph = builder.build()..layout(ParagraphConstraints(width: width));

  final dy = wide
      ? (metrics.cellHeight - paragraph.height) / 2
      : metrics.baseline - paragraph.alphabeticBaseline;

  return (paragraph, Offset(0, dy));
}

class ContentCache {
  final TerminalPaintContext _ctx;
  List<_RowCache> _cache = const [];
  var _cols = 0;

  String? _highlightedHyperlink;

  late final _buildState = _RowBuildState();

  ContentCache(this._ctx);

  set highlightedHyperlink(String? value) {
    if (_highlightedHyperlink == value) return;
    _markHyperlinkRowsDirty(_highlightedHyperlink);
    _markHyperlinkRowsDirty(value);
    _highlightedHyperlink = value;
  }

  List<ColorRun> backgroundRunsAt(int row) {
    return row >= 0 && row < _cache.length
        ? _cache[row].backgroundRuns
        : const [];
  }

  void detectDirty(Screen screen, {int rowOffset = 0}) {
    final rows = _cache.length;
    if (screen.dirtyState == DirtyState.full) {
      markAllDirty();
      return;
    }
    final startRow = rowOffset < rows ? rowOffset : rows;
    for (var row = startRow; row < rows; row++) {
      final screenRow = row - rowOffset;
      if (screenRow >= screen.rows) break;
      if (screen.isRowDirty(screenRow)) _cache[row].dirty = true;
    }
  }

  void dispose() => _disposeAll();

  List<Glyph> glyphsAt(int row) {
    return row >= 0 && row < _cache.length ? _cache[row].glyphs : const [];
  }

  void markAllDirty() {
    _ctx.styles.clearStyleCaches();
    for (var row = 0; row < _cache.length; row++) {
      _cache[row].dirty = true;
    }
  }

  void markBlinkingDirty() {
    for (var row = 0; row < _cache.length; row++) {
      if (_cache[row].hasBlink) _cache[row].dirty = true;
    }
  }

  Paragraph? paragraphAt(int row) {
    return row >= 0 && row < _cache.length ? _cache[row].paragraph : null;
  }

  void rebuildDirty(Line Function(int) lineAt) {
    for (var row = 0; row < _cache.length; row++) {
      final entry = _cache[row];
      if (!entry.dirty) continue;
      _rebuildRow(entry, lineAt(row));
      entry.dirty = false;
    }
  }

  void scroll(int delta) {
    final rows = _cache.length;
    if (delta == 0 || rows == 0) return;

    if (delta.abs() >= rows) {
      markAllDirty();
      return;
    }

    final forward = delta > 0;
    final count = delta.abs();
    final discardStart = forward ? rows - count : 0;
    final keepDst = forward ? count : 0;
    final keepSrc = forward ? 0 : count;
    final keepLen = rows - count;
    final freshStart = forward ? 0 : rows - count;

    final recycled = [
      for (var i = discardStart; i < discardStart + count; i++) _cache[i],
    ];

    _cache.setRange(keepDst, keepDst + keepLen, _cache, keepSrc);

    for (var i = 0; i < count; i++) {
      final entry = recycled[i]..reset();
      _cache[freshStart + i] = entry;
    }
  }

  void updateGridSize() {
    final newRows = _ctx.rows;
    final newCols = _ctx.cols;
    if (newCols == _cols && newRows == _cache.length) return;
    _cols = newCols;
    _ctx.styles.maxCacheSize = newCols * newRows * 3;
    _disposeAll();
    _cache = List<_RowCache>.generate(newRows, (_) => _RowCache(newCols));
  }

  void _disposeAll() {
    for (final entry in _cache) {
      entry.dispose();
    }
    _cache = const [];
  }

  void _markHyperlinkRowsDirty(String? uri) {
    if (uri == null) return;
    for (var row = 0; row < _cache.length; row++) {
      final entry = _cache[row];
      if (!entry.hasHyperlink) continue;
      for (var col = 0; col < entry.hyperlinks.length; col++) {
        if (entry.hyperlinks[col] == uri) {
          entry.dirty = true;
          break;
        }
      }
    }
  }

  void _processBackground(Cell cell, int col, List<ColorRun> runs) {
    final state = _buildState;
    if (state.background != state.backgroundRunColor) {
      if (state.backgroundRunColor != state.terminalBackground) {
        runs.add(
          ColorRun(state.backgroundRunStart, col, state.backgroundRunColor),
        );
      }
      state.backgroundRunColor = state.background;
      state.backgroundRunStart = col;
    }
  }

  void _rebuildRow(_RowCache entry, Line line) {
    entry.dispose();
    final runs = entry.backgroundRuns..clear();
    final glyphs = entry.glyphs;
    final links = entry.hyperlinks;
    final styles = _ctx.styles;
    final state = _buildState..reset(styles);
    final cols = _cols;
    final metrics = _ctx.metrics;
    final blinkVisible = _ctx.blinkVisible;

    final builder = ParagraphBuilder(styles.paragraphStyle);
    var rowHasBlink = false;
    var rowHasHyperlink = false;

    for (var col = 0; col < cols; col++) {
      final cell = line.cellAt(col);
      final hyperlink = cell.hyperlink;
      links[col] = hyperlink;
      if (cell.style.blink) rowHasBlink = true;
      if (hyperlink != null) rowHasHyperlink = true;

      final style = _resolveSpanStyle(cell, hyperlink);

      _processBackground(cell, col, runs);

      if (style != null && style != state.currentStyle) {
        if (state.currentStyle != null) builder.pop();
        builder.pushStyle(style);
        state.currentStyle = style;
      }

      if (cell.isWide) {
        builder.addText('  ');

        final content = cellText(cell, blinkVisible: blinkVisible);
        if (content != ' ') {
          final (paragraph, offset) = buildGlyphParagraph(
            styles,
            metrics,
            cell,
            content,
            state.foreground,
            wide: true,
          );
          glyphs.add(Glyph(col, 2, paragraph, offset));
        }

        col++;
        if (col < cols) {
          links[col] = hyperlink;
          if (state.backgroundRunColor != state.terminalBackground) {
            runs.add(
              ColorRun(
                state.backgroundRunStart,
                col + 1,
                state.backgroundRunColor,
              ),
            );
          }

          state.backgroundRunStart = col + 1;
          state.backgroundRunColor = state.terminalBackground;
        }
      } else {
        final text = cellText(cell, blinkVisible: blinkVisible);
        if (text.codeUnitAt(0) > 0x7F) {
          builder.addText(' ');
          if (text != ' ') {
            final (paragraph, offset) = buildGlyphParagraph(
              styles,
              metrics,
              cell,
              text,
              state.foreground,
              wide: false,
            );
            glyphs.add(Glyph(col, 1, paragraph, offset));
          }
        } else {
          builder.addText(text);
        }
      }
    }

    if (state.currentStyle != null) builder.pop();

    if (state.backgroundRunColor != state.terminalBackground) {
      runs.add(
        ColorRun(state.backgroundRunStart, cols, state.backgroundRunColor),
      );
    }

    entry.hasBlink = rowHasBlink;
    entry.hasHyperlink = rowHasHyperlink;

    entry.paragraph = builder.build()
      ..layout(const ParagraphConstraints(width: double.infinity));
  }

  TextStyle? _resolveSpanStyle(Cell cell, String? hyperlink) {
    final state = _buildState;
    final styles = _ctx.styles;
    final hasLink = hyperlink != null;
    final isHighlighted = hasLink && hyperlink == _highlightedHyperlink;

    final colorsChanged =
        cell.foreground != state.prevForeground ||
        cell.background != state.prevBackground ||
        cell.style.inverse != state.prevCellStyle.inverse ||
        cell.style.faint != state.prevCellStyle.faint;
    if (colorsChanged) {
      final colors = styles.resolveColors(cell);
      state.foreground = colors.$1;
      state.background = colors.$2;
    }

    final hyperlinkChanged =
        hasLink != state.prevHadLink ||
        isHighlighted != state.prevWasHighlighted;
    if (state.currentStyle != null &&
        !colorsChanged &&
        !hyperlinkChanged &&
        cell.style == state.prevCellStyle &&
        cell.underlineColor == state.prevUnderlineColor) {
      return null;
    }

    state.prevForeground = cell.foreground;
    state.prevBackground = cell.background;
    state.prevUnderlineColor = cell.underlineColor;
    state.prevCellStyle = cell.style;
    state.prevHadLink = hasLink;
    state.prevWasHighlighted = isHighlighted;

    final hlStyle = hasLink
        ? (isHighlighted ? state.hlHighlighted : state.hlIdle)
        : null;
    final effectiveFg = hlStyle?.textColor ?? state.foreground;

    if (hlStyle != null &&
        cell.style.underline == UnderlineStyle.none &&
        hlStyle.underline != UnderlineStyle.none) {
      final key = CellStyleKey(
        bold: cell.style.bold,
        foreground: effectiveFg,
        faint: cell.style.faint,
        italic: cell.style.italic,
        underline: hlStyle.underline,
        overline: cell.style.overline,
        underlineColor: hlStyle.underlineColor,
        strikethrough: cell.style.strikethrough,
      );
      return styles.buildStyle(key);
    }

    if (cell.style == const CellStyle() && cell.underlineColor == null) {
      return styles.baseStyle(effectiveFg);
    }

    return styles.resolveStyle(cell, effectiveFg);
  }
}

class Glyph {
  final int col;
  final int span;
  final Offset offset;
  final Paragraph paragraph;

  Glyph(this.col, this.span, this.paragraph, this.offset);

  void dispose() => paragraph.dispose();
}

class _RowBuildState {
  late Color terminalBackground;
  late HyperlinkStyle hlIdle;
  late HyperlinkStyle hlHighlighted;

  var backgroundRunStart = 0;
  var backgroundRunColor = const Color(0x00000000);

  TextStyle? currentStyle;
  CellColor prevForeground = const DefaultColor();
  CellColor prevBackground = const DefaultColor();
  CellColor? prevUnderlineColor;
  var prevCellStyle = const CellStyle();
  var prevHadLink = false;
  var prevWasHighlighted = false;

  var foreground = const Color(0x00000000);
  var background = const Color(0x00000000);

  void reset(StyleResolver styles) {
    final theme = styles.theme;
    terminalBackground = theme.background;
    hlIdle = theme.hyperlink.idle;
    hlHighlighted = theme.hyperlink.highlighted;

    backgroundRunStart = 0;
    backgroundRunColor = terminalBackground;

    currentStyle = null;
    prevForeground = const DefaultColor();
    prevBackground = const DefaultColor();
    prevUnderlineColor = null;
    prevCellStyle = const CellStyle();
    prevHadLink = false;
    prevWasHighlighted = false;

    foreground = theme.resolveColor(const DefaultColor(), isForeground: true);
    background = theme.resolveColor(const DefaultColor(), isForeground: false);
  }
}

class _RowCache {
  var dirty = true;
  var hasBlink = false;
  var hasHyperlink = false;
  Paragraph? paragraph;
  final List<String?> hyperlinks;
  final List<ColorRun> backgroundRuns = [];
  final List<Glyph> glyphs = [];

  _RowCache(int cols) : hyperlinks = List<String?>.filled(cols, null);

  void dispose() {
    paragraph?.dispose();
    paragraph = null;
    for (final glyph in glyphs) {
      glyph.dispose();
    }
    glyphs.clear();
  }

  void reset() {
    dispose();
    dirty = true;
    hasBlink = false;
    hasHyperlink = false;
    backgroundRuns.clear();
    hyperlinks.fillRange(0, hyperlinks.length, null);
  }
}
