import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:libghostty/libghostty.dart';

import '../foundation.dart';
import 'cell_text.dart';
import 'content_cache.dart';
import 'content_layer.dart';
import 'cursor_layer.dart';
import 'selection_layer.dart';
import 'style_resolver.dart';
import 'terminal_paint_context.dart';

/// Renders a terminal screen with cell backgrounds, styled text, cursors,
/// and selection overlays.
///
/// ```dart
/// TerminalRenderer(
///   terminal: myTerminal,
///   theme: TerminalTheme.dark(),
///   metrics: measureCellMetrics(fontFamily: 'monospace', fontSize: 14),
///   offset: ViewportOffset.zero(),
///   renderState: controller,
/// )
/// ```
class TerminalRenderer extends LeafRenderObjectWidget {
  /// The terminal whose screen is rendered.
  final Terminal terminal;

  /// Visual style: colors, cursor, font.
  final TerminalTheme theme;

  /// Cell pixel dimensions.
  final CellMetrics metrics;

  /// Scroll offset provided by a [Scrollable] ancestor.
  ///
  /// At `pixels == 0`, the oldest scrollback row is visible.
  /// At `pixels == maxScrollExtent`, the live screen is visible.
  final ViewportOffset offset;

  /// Observable state for selection and focus.
  final TerminalRenderState? renderState;

  /// Whether the cursor blink is currently in the visible phase.
  ///
  /// When false, the cursor and blinking text are hidden.
  final bool blinkVisible;

  /// Called when the terminal grid dimensions change during layout.
  final ValueChanged<TerminalSize>? onResize;

  /// Called for mode changes, mouse shape changes, terminal responses,
  /// and cursor changes.
  final ValueChanged<TerminalEvent>? onEvent;

  /// URI of the hyperlink currently highlighted by Cmd+hover, or null.
  final String? highlightedHyperlink;

  const TerminalRenderer({
    super.key,
    required this.terminal,
    required this.theme,
    required this.metrics,
    required this.offset,
    this.renderState,
    this.blinkVisible = true,
    this.onResize,
    this.onEvent,
    this.highlightedHyperlink,
  });

  @override
  TerminalRenderBox createRenderObject(BuildContext context) {
    return TerminalRenderBox(
      terminal: terminal,
      theme: theme,
      metrics: metrics,
      offset: offset,
      renderState: renderState,
      blinkVisible: blinkVisible,
      onResize: onResize,
      onEvent: onEvent,
      highlightedHyperlink: highlightedHyperlink,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Terminal>('terminal', terminal))
      ..add(DiagnosticsProperty<TerminalTheme>('theme', theme))
      ..add(DiagnosticsProperty<CellMetrics>('metrics', metrics))
      ..add(
        DiagnosticsProperty<TerminalSelection?>(
          'selection',
          renderState?.selection,
        ),
      )
      ..add(DiagnosticsProperty<ViewportOffset>('offset', offset))
      ..add(
        FlagProperty(
          'blinkVisible',
          value: blinkVisible,
          ifTrue: 'blink visible',
        ),
      );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    TerminalRenderBox renderObject,
  ) {
    renderObject
      ..terminal = terminal
      ..theme = theme
      ..offset = offset
      ..metrics = metrics
      ..onResize = onResize
      ..onEvent = onEvent
      ..renderState = renderState
      ..blinkVisible = blinkVisible
      ..highlightedHyperlink = highlightedHyperlink;
  }
}

class _ScrollState {
  var stickToBottom = true;
  var lastScrollbackLength = 0;
  var rowOffset = 0;
}

class TerminalRenderBox extends RenderBox {
  Terminal _terminal;
  TerminalTheme _theme;
  CellMetrics _metrics;
  ViewportOffset _offset;
  TerminalRenderState? _renderState;
  ValueChanged<TerminalSize>? _onResize;
  ValueChanged<TerminalEvent>? _onEvent;
  String? _highlightedHyperlink;

  var _performingLayout = false;
  var _needsTerminalSync = false;

  final _scroll = _ScrollState();

  late final TerminalPaintContext _ctx;
  late final ContentCache _contentCache;
  late final ContentLayer _contentLayer;
  late final CursorLayer _cursorLayer;
  late final SelectionLayer _selectionLayer;

  late final _lineResolverFn = _lineResolver;

  final _backgroundPaint = Paint();

  StreamSubscription<TerminalEvent>? _eventSub;

  TerminalRenderBox({
    required Terminal terminal,
    required TerminalTheme theme,
    required CellMetrics metrics,
    required ViewportOffset offset,
    TerminalRenderState? renderState,
    bool blinkVisible = true,
    ValueChanged<TerminalSize>? onResize,
    ValueChanged<TerminalEvent>? onEvent,
    String? highlightedHyperlink,
  }) : _terminal = terminal,
       _theme = theme,
       _offset = offset,
       _metrics = metrics,
       _onResize = onResize,
       _onEvent = onEvent,
       _renderState = renderState,
       _highlightedHyperlink = highlightedHyperlink {
    final styles = StyleResolver(theme);
    _ctx =
        TerminalPaintContext(
            styles,
            metrics,
            selectionColor: theme.selectionColor,
          )
          ..blinkVisible = blinkVisible
          ..cursor.focused = renderState?.hasFocus ?? true
          ..selection = renderState?.selection;
    _contentCache = ContentCache(_ctx);
    _contentLayer = ContentLayer(_ctx, _contentCache);
    _cursorLayer = CursorLayer(_ctx);
    _selectionLayer = SelectionLayer(_ctx);
    _backgroundPaint.color = theme.background;
  }

  bool get blinkVisible => _ctx.blinkVisible;

  set blinkVisible(bool value) {
    if (_ctx.blinkVisible == value) return;
    _ctx.blinkVisible = value;
    _contentCache.markBlinkingDirty();
    if (_ctx.rows > 0) _contentCache.rebuildDirty(_lineResolverFn);
    markNeedsPaint();
  }

  set highlightedHyperlink(String? value) {
    if (_highlightedHyperlink == value) return;
    _highlightedHyperlink = value;
    _contentCache.highlightedHyperlink = value;
    if (_ctx.rows > 0) _contentCache.rebuildDirty(_lineResolverFn);
    markNeedsPaint();
  }

  @override
  bool get isRepaintBoundary => true;

  CellMetrics get metrics => _metrics;

  set metrics(CellMetrics value) {
    if (_metrics == value) return;
    _metrics = value;
    _ctx.metrics = value;
    _contentCache.markAllDirty();
    _ctx.cursor.invalidateGlyph();
    markNeedsLayout();
  }

  ViewportOffset get offset => _offset;

  set offset(ViewportOffset value) {
    if (_offset == value) return;
    if (attached) _offset.removeListener(_onScroll);
    _offset = value;
    if (attached) _offset.addListener(_onScroll);
    markNeedsLayout();
  }

  ValueChanged<TerminalEvent>? get onEvent => _onEvent;

  set onEvent(ValueChanged<TerminalEvent>? value) {
    if (_onEvent == value) return;
    _onEvent = value;
  }

  ValueChanged<TerminalSize>? get onResize => _onResize;

  set onResize(ValueChanged<TerminalSize>? value) {
    if (_onResize == value) return;
    _onResize = value;
  }

  TerminalRenderState? get renderState => _renderState;

  set renderState(TerminalRenderState? value) {
    if (_renderState == value) return;
    if (attached) _renderState?.removeListener(_onRenderStateChanged);
    _renderState = value;
    if (attached) _renderState?.addListener(_onRenderStateChanged);
    _onRenderStateChanged();
  }

  TerminalSelection? get selection => _ctx.selection;

  Terminal get terminal => _terminal;

  set terminal(Terminal value) {
    if (_terminal == value) return;
    _eventSub?.cancel().ignore();
    _terminal = value;
    _setupSubscriptions();
    _contentCache.markAllDirty();
    markNeedsLayout();
  }

  TerminalTheme get theme => _theme;

  set theme(TerminalTheme value) {
    if (_theme == value) return;
    _theme = value;
    _ctx.styles = StyleResolver(value);
    _ctx.selectionColor = value.selectionColor;
    _contentCache.markAllDirty();
    _ctx.cursor.invalidateGlyph();
    _backgroundPaint.color = value.background;
    markNeedsLayout();
  }

  Line? get _cursorLine {
    if (_scroll.rowOffset > 0) return null;
    final row = _terminal.cursor.row;
    if (row < 0 || row >= _ctx.rows) return null;
    return _terminal.screen.lineAt(row);
  }

  double get _scrollMaxExtent =>
      _terminal.scrollback.length * _metrics.cellHeight;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _offset.addListener(_onScroll);
    _renderState?.addListener(_onRenderStateChanged);
    _setupSubscriptions();
    markNeedsLayout();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('cols', _ctx.cols))
      ..add(IntProperty('rows', _ctx.rows))
      ..add(DiagnosticsProperty<TerminalTheme>('theme', _theme))
      ..add(DiagnosticsProperty<CellMetrics>('metrics', _metrics))
      ..add(
        DiagnosticsProperty<TerminalSelection?>('selection', _ctx.selection),
      )
      ..add(
        FlagProperty(
          'blinkVisible',
          value: blinkVisible,
          ifTrue: 'cursor visible',
        ),
      )
      ..add(
        FlagProperty('focused', value: _ctx.cursor.focused, ifTrue: 'focused'),
      )
      ..add(
        DiagnosticsProperty<TerminalRenderState?>('renderState', _renderState),
      );
  }

  @override
  void detach() {
    _offset.removeListener(_onScroll);
    _renderState?.removeListener(_onRenderStateChanged);
    _eventSub?.cancel().ignore();
    _contentCache.dispose();
    _ctx.cursor.dispose();
    _ctx.rows = 0;
    _ctx.cols = 0;
    super.detach();
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    _syncTerminalState();

    final canvas = context.canvas;
    canvas.drawRect(offset & size, _backgroundPaint);
    _contentLayer.paint(canvas, offset);
    _cursorLayer.paint(canvas, offset);
    _selectionLayer.paint(canvas, offset);
  }

  @override
  void performLayout() {
    _performingLayout = true;

    final maxW = constraints.maxWidth.isFinite ? constraints.maxWidth : 0.0;
    final maxH = constraints.maxHeight.isFinite ? constraints.maxHeight : 0.0;
    final (newCols, newRows) = _metrics.gridSize(maxW, maxH);

    size = constraints.constrain(
      Size(newCols * _metrics.cellWidth, newRows * _metrics.cellHeight),
    );

    if (newCols != _ctx.cols || newRows != _ctx.rows) {
      _ctx.cols = newCols;
      _ctx.rows = newRows;
      _contentCache.updateGridSize();
      if (newCols > 0 && newRows > 0) {
        _terminal.resize(cols: newCols, rows: newRows);
        _onResize?.call(TerminalSize(cols: newCols, rows: newRows));
      }
    }

    _syncScrollLayout();
    _ctx.cursor.scrolling = _scroll.rowOffset > 0;

    if (_ctx.rows > 0) {
      _syncTerminalState();
      _updateCursor(_terminal.cursor, _cursorLine);
      _contentCache.rebuildDirty(_lineResolverFn);
    }

    markNeedsPaint();
    _performingLayout = false;
  }

  int _computeScrollRowOffset() {
    final scrollbackLen = _terminal.scrollback.length;
    if (scrollbackLen == 0 || _metrics.cellHeight <= 0) return 0;
    final maxExtent = _scrollMaxExtent;
    if (maxExtent <= 0) return 0;
    final pixels = _offset.pixels.clamp(0.0, maxExtent);
    return scrollbackLen - (pixels / _metrics.cellHeight).floor();
  }

  bool _isCursorUnchanged(Cursor cursor, String content, {required bool wide}) {
    final cur = _ctx.cursor;
    return cursor.row == cur.row &&
        cursor.col == cur.col &&
        cursor.shape == cur.shape &&
        cursor.visible == cur.visible &&
        wide == cur.wide &&
        content == cur.cellContent &&
        cur.glyph != null;
  }

  Line _lineResolver(int row) {
    return _scroll.rowOffset > 0
        ? _scrollLineAt(row)
        : _terminal.screen.lineAt(row);
  }

  void _onRenderStateChanged() {
    var needsPaint = false;

    final newSelection = _renderState?.selection;
    if (newSelection != _ctx.selection) {
      _ctx.selection = newSelection;
      needsPaint = true;
    }

    final newFocused = _renderState?.hasFocus ?? true;
    if (newFocused != _ctx.cursor.focused) {
      _ctx.cursor.focused = newFocused;
      _ctx.cursor.invalidateGlyph();
      _needsTerminalSync = true;
      needsPaint = true;
    }

    if (needsPaint) markNeedsPaint();
  }

  void _onScroll() {
    if (_ctx.rows == 0) return;
    final delta = _processScroll();
    _ctx.cursor.scrolling = _scroll.rowOffset > 0;
    _ctx.scrollbackLength = _scroll.lastScrollbackLength;
    _ctx.rowOffset = _scroll.rowOffset;

    if (delta == 0) {
      markNeedsPaint();
      return;
    }

    _contentCache.scroll(delta);
    _updateCursor(_terminal.cursor, _cursorLine);
    _contentCache.rebuildDirty(_lineResolverFn);
    markNeedsPaint();
  }

  void _onTerminalChanged() {
    if (_ctx.rows == 0) return;
    _needsTerminalSync = true;

    final scrollbackLen = _terminal.scrollback.length;
    if (scrollbackLen != _scroll.lastScrollbackLength) {
      _scroll.lastScrollbackLength = scrollbackLen;
      _contentCache.markAllDirty();
      if (!_performingLayout) {
        markNeedsLayout();
        return;
      }
    }

    if (!_performingLayout) markNeedsPaint();
  }

  int _processScroll() {
    final maxExtent = _scrollMaxExtent;
    _scroll.stickToBottom = maxExtent <= 0 || _offset.pixels >= maxExtent - 1.0;
    final newRow = _computeScrollRowOffset();
    final delta = newRow - _scroll.rowOffset;
    _scroll.rowOffset = newRow;
    return delta;
  }

  void _rebuildCursorGlyph(Cell? cell, String content) {
    final cur = _ctx.cursor;
    cur.invalidateGlyph();

    if (cur.scrolling || !cur.focused) return;
    if (cur.shape != CursorShape.block) return;
    if (content == ' ' || cell == null) return;
    if (cur.row < 0 || cur.row >= _ctx.rows) return;
    if (cur.col < 0 || cur.col >= _ctx.cols) return;

    final colors = _ctx.styles.resolveColors(cell);
    final (paragraph, offset) = buildGlyphParagraph(
      _ctx.styles,
      _ctx.metrics,
      cell,
      content,
      colors.$2,
      wide: cell.isWide,
    );
    cur.glyph = paragraph;
    cur.glyphOffset = offset;
  }

  Cell? _resolveCursorCell(Cursor cursor, Line? cursorLine) {
    if (cursorLine == null) return null;
    if (!cursor.visible) return null;
    if (cursor.row < 0 || cursor.row >= _ctx.rows) return null;
    if (cursor.col < 0 || cursor.col >= _ctx.cols) return null;

    final cell = cursorLine.cellAt(cursor.col);
    _ctx.cursor.color =
        _ctx.styles.theme.cursor.color ??
        _ctx.styles.theme.resolveColor(cell.foreground, isForeground: true);
    return cell;
  }

  Line _scrollLineAt(int viewportRow) {
    final scrollbackLen = _terminal.scrollback.length;
    final absRow = scrollbackLen - _scroll.rowOffset + viewportRow;
    if (absRow < 0) return const Line([]);
    if (absRow < scrollbackLen) {
      return _terminal.scrollback.lineAt(absRow);
    }
    final screenRow = absRow - scrollbackLen;
    return screenRow < _terminal.screen.rows
        ? _terminal.screen.lineAt(screenRow)
        : const Line([]);
  }

  void _setupSubscriptions() {
    _eventSub = _terminal.onEvent.listen((event) {
      switch (event) {
        case ScreenChanged():
          _onTerminalChanged();
        case CursorChanged():
          _needsTerminalSync = true;
          markNeedsPaint();
          _onEvent?.call(event);
        default:
          _onEvent?.call(event);
      }
    });
  }

  void _syncScrollLayout() {
    final maxExtent = _scrollMaxExtent;
    if (_scroll.stickToBottom && maxExtent > 0) {
      final correction = maxExtent - _offset.pixels;
      if (correction.abs() > 0.01) _offset.correctBy(correction);
    }
    _offset.applyViewportDimension(size.height);
    _offset.applyContentDimensions(0, maxExtent);
    _scroll.lastScrollbackLength = _terminal.scrollback.length;
    _scroll.rowOffset = _computeScrollRowOffset();
    _ctx.scrollbackLength = _scroll.lastScrollbackLength;
    _ctx.rowOffset = _scroll.rowOffset;
  }

  void _syncTerminalState() {
    if (!_needsTerminalSync || _ctx.rows == 0) return;
    _needsTerminalSync = false;

    final screen = _terminal.screen;
    final rowOffset = _scroll.rowOffset;

    _contentCache.detectDirty(screen, rowOffset: rowOffset > 0 ? rowOffset : 0);
    _updateCursor(_terminal.cursor, _cursorLine);
    _contentCache.rebuildDirty(_lineResolverFn);
    _terminal.clearContentChanges();
  }

  void _updateCursor(Cursor cursor, Line? cursorLine) {
    final cell = _resolveCursorCell(cursor, cursorLine);
    final newContent = cell != null
        ? cellText(cell, blinkVisible: _ctx.blinkVisible)
        : ' ';
    final wide = cell?.isWide ?? false;

    if (_isCursorUnchanged(cursor, newContent, wide: wide)) return;

    final cur = _ctx.cursor;
    cur.row = cursor.row;
    cur.col = cursor.col;
    cur.shape = cursor.shape;
    cur.visible = cursor.visible;
    cur.wide = wide;
    cur.cellContent = newContent;

    _rebuildCursorGlyph(cell, newContent);
  }
}
