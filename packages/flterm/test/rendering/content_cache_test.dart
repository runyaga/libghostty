@Tags(['ffi'])
library;

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:flterm/src/foundation.dart';
import 'package:flterm/src/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libghostty/libghostty.dart';

import '../helpers/font_loader.dart';

void main() {
  setUpAll(loadBundledFonts);

  late TerminalPaintContext ctx;
  late ContentCache cache;

  setUp(() {
    ctx = TerminalPaintContext(
      StyleResolver(TerminalTheme.dark()),
      _metrics,
      selectionColor: const Color(0x00000000),
    );
    cache = ContentCache(ctx);
  });

  tearDown(() => cache.dispose());

  group('gridSize', () {
    test('initializes with null paragraphs', () {
      ctx.rows = 3;
      ctx.cols = 10;
      cache.updateGridSize();
      for (var row = 0; row < 3; row++) {
        expect(cache.paragraphAt(row), isNull);
      }
    });

    test('same gridSize is a no-op', () {
      ctx.rows = 3;
      ctx.cols = 10;
      cache.updateGridSize();
      cache.rebuildDirty((_) => const Line([]));
      final p0 = cache.paragraphAt(0);
      cache.updateGridSize();
      expect(identical(cache.paragraphAt(0), p0), isTrue);
    });

    test('out-of-bounds accessors return safe defaults', () {
      ctx.rows = 3;
      ctx.cols = 10;
      cache.updateGridSize();

      expect(cache.paragraphAt(-1), isNull);
      expect(cache.paragraphAt(3), isNull);
      expect(cache.glyphsAt(-1), isEmpty);
      expect(cache.glyphsAt(3), isEmpty);
      expect(cache.backgroundRunsAt(-1), isEmpty);
      expect(cache.backgroundRunsAt(3), isEmpty);
    });
  });

  group('rebuildDirty', () {
    test('builds paragraphs for all dirty rows', () {
      ctx.rows = 3;
      ctx.cols = 10;
      cache.updateGridSize();
      cache.rebuildDirty((_) => const Line([]));
      for (var row = 0; row < 3; row++) {
        expect(cache.paragraphAt(row), isNotNull);
      }
    });

    test('second call is a no-op when no rows are dirty', () {
      ctx.rows = 3;
      ctx.cols = 10;
      cache.updateGridSize();
      cache.rebuildDirty((_) => const Line([]));
      final p0 = cache.paragraphAt(0);
      cache.rebuildDirty((_) => const Line([]));
      expect(identical(cache.paragraphAt(0), p0), isTrue);
    });

    test('markAllDirty forces full rebuild', () {
      ctx.rows = 3;
      ctx.cols = 10;
      cache.updateGridSize();
      cache.rebuildDirty((_) => const Line([]));
      final p0 = cache.paragraphAt(0);
      cache.markAllDirty();
      cache.rebuildDirty((_) => const Line([]));
      expect(identical(cache.paragraphAt(0), p0), isFalse);
    });
  });

  group('scroll', () {
    test('forward by 1 shifts paragraphs down, fresh row at top', () {
      ctx.rows = 4;
      ctx.cols = 10;
      cache.updateGridSize();
      cache.rebuildDirty((_) => const Line([]));
      final original = [for (var i = 0; i < 4; i++) cache.paragraphAt(i)];

      cache.scroll(1);

      expect(cache.paragraphAt(0), isNull);
      expect(identical(cache.paragraphAt(1), original[0]), isTrue);
      expect(identical(cache.paragraphAt(2), original[1]), isTrue);
      expect(identical(cache.paragraphAt(3), original[2]), isTrue);
    });

    test('backward by 1 shifts paragraphs up, fresh row at bottom', () {
      ctx.rows = 4;
      ctx.cols = 10;
      cache.updateGridSize();
      cache.rebuildDirty((_) => const Line([]));
      final original = [for (var i = 0; i < 4; i++) cache.paragraphAt(i)];

      cache.scroll(-1);

      expect(identical(cache.paragraphAt(0), original[1]), isTrue);
      expect(identical(cache.paragraphAt(1), original[2]), isTrue);
      expect(identical(cache.paragraphAt(2), original[3]), isTrue);
      expect(cache.paragraphAt(3), isNull);
    });

    test('delta equal to rows marks all dirty for rebuild', () {
      ctx.rows = 3;
      ctx.cols = 10;
      cache.updateGridSize();
      cache.rebuildDirty((_) => const Line([]));

      cache.scroll(3);

      cache.rebuildDirty((_) => const Line([]));
      for (var row = 0; row < 3; row++) {
        expect(cache.paragraphAt(row), isNotNull);
      }
    });

    test('delta of 0 is a no-op', () {
      ctx.rows = 3;
      ctx.cols = 10;
      cache.updateGridSize();
      cache.rebuildDirty((_) => const Line([]));
      final p0 = cache.paragraphAt(0);

      cache.scroll(0);

      expect(identical(cache.paragraphAt(0), p0), isTrue);
    });

    test('fresh rows rebuild after scroll', () {
      ctx.rows = 3;
      ctx.cols = 10;
      cache.updateGridSize();
      cache.rebuildDirty((_) => const Line([]));

      cache.scroll(1);
      expect(cache.paragraphAt(0), isNull);

      cache.rebuildDirty((_) => const Line([]));
      expect(cache.paragraphAt(0), isNotNull);
    });

    test('forward by 2 shifts two rows, two fresh at top', () {
      ctx.rows = 4;
      ctx.cols = 10;
      cache.updateGridSize();
      cache.rebuildDirty((_) => const Line([]));
      final original = [for (var i = 0; i < 4; i++) cache.paragraphAt(i)];

      cache.scroll(2);

      expect(cache.paragraphAt(0), isNull);
      expect(cache.paragraphAt(1), isNull);
      expect(identical(cache.paragraphAt(2), original[0]), isTrue);
      expect(identical(cache.paragraphAt(3), original[1]), isTrue);
    });

    test('negative delta exceeding rows marks all dirty', () {
      ctx.rows = 3;
      ctx.cols = 10;
      cache.updateGridSize();
      cache.rebuildDirty((_) => const Line([]));
      final p0 = cache.paragraphAt(0);

      cache.scroll(-5);

      cache.rebuildDirty((_) => const Line([]));
      expect(identical(cache.paragraphAt(0), p0), isFalse);
    });
  });

  group('detectDirty', () {
    test('full dirty state marks all rows dirty', () {
      ctx.rows = 3;
      ctx.cols = 10;
      cache.updateGridSize();
      cache.rebuildDirty((_) => const Line([]));
      final original = [for (var i = 0; i < 3; i++) cache.paragraphAt(i)];

      cache.detectDirty(_FakeScreen(3, DirtyState.full, const {}));
      cache.rebuildDirty((_) => const Line([]));

      for (var row = 0; row < 3; row++) {
        expect(identical(cache.paragraphAt(row), original[row]), isFalse);
      }
    });

    test('partial dirty state marks only dirty rows', () {
      ctx.rows = 3;
      ctx.cols = 10;
      cache.updateGridSize();
      cache.rebuildDirty((_) => const Line([]));
      final original = [for (var i = 0; i < 3; i++) cache.paragraphAt(i)];

      cache.detectDirty(_FakeScreen(3, DirtyState.partial, const {1}));
      cache.rebuildDirty((_) => const Line([]));

      expect(identical(cache.paragraphAt(0), original[0]), isTrue);
      expect(identical(cache.paragraphAt(1), original[1]), isFalse);
      expect(identical(cache.paragraphAt(2), original[2]), isTrue);
    });

    test('clean dirty state leaves all rows unchanged', () {
      ctx.rows = 3;
      ctx.cols = 10;
      cache.updateGridSize();
      cache.rebuildDirty((_) => const Line([]));
      final original = [for (var i = 0; i < 3; i++) cache.paragraphAt(i)];

      cache.detectDirty(_FakeScreen(3, DirtyState.clean, const {}));
      cache.rebuildDirty((_) => const Line([]));

      for (var row = 0; row < 3; row++) {
        expect(identical(cache.paragraphAt(row), original[row]), isTrue);
      }
    });

    test('rowOffset shifts which screen rows map to cache rows', () {
      ctx.rows = 4;
      ctx.cols = 10;
      cache.updateGridSize();
      cache.rebuildDirty((_) => const Line([]));
      final original = [for (var i = 0; i < 4; i++) cache.paragraphAt(i)];

      cache.detectDirty(
        _FakeScreen(4, DirtyState.partial, const {0}),
        rowOffset: 2,
      );
      cache.rebuildDirty((_) => const Line([]));

      expect(identical(cache.paragraphAt(0), original[0]), isTrue);
      expect(identical(cache.paragraphAt(1), original[1]), isTrue);
      expect(identical(cache.paragraphAt(2), original[2]), isFalse);
      expect(identical(cache.paragraphAt(3), original[3]), isTrue);
    });
  });

  group('markBlinkingDirty', () {
    test('marks only rows containing blink cells', () {
      final terminal = Terminal(cols: 10, rows: 3);
      addTearDown(terminal.dispose);
      terminal.write(
        Uint8List.fromList(
          utf8.encode('normal\r\n\x1b[5mblink\x1b[0m\r\nlast'),
        ),
      );

      ctx.rows = 3;
      ctx.cols = 10;
      cache.updateGridSize();
      cache.rebuildDirty((row) => terminal.screen.lineAt(row));
      final p0 = cache.paragraphAt(0);
      final p1 = cache.paragraphAt(1);
      final p2 = cache.paragraphAt(2);

      cache.markBlinkingDirty();
      cache.rebuildDirty((row) => terminal.screen.lineAt(row));

      expect(identical(cache.paragraphAt(0), p0), isTrue);
      expect(identical(cache.paragraphAt(1), p1), isFalse);
      expect(identical(cache.paragraphAt(2), p2), isTrue);
    });
  });

  group('highlightedHyperlink', () {
    test('setting hyperlink marks rows containing that URI dirty', () {
      final terminal = Terminal(cols: 20, rows: 3);
      addTearDown(terminal.dispose);
      terminal.write(
        Uint8List.fromList(
          utf8.encode(
            'plain\r\n'
            '\x1b]8;;https://a.com\x1b\\link\x1b]8;;\x1b\\\r\n'
            'more',
          ),
        ),
      );

      ctx.rows = 3;
      ctx.cols = 20;
      cache.updateGridSize();
      cache.rebuildDirty((row) => terminal.screen.lineAt(row));
      final p0 = cache.paragraphAt(0);
      final p1 = cache.paragraphAt(1);
      final p2 = cache.paragraphAt(2);

      cache.highlightedHyperlink = 'https://a.com';
      cache.rebuildDirty((row) => terminal.screen.lineAt(row));

      expect(identical(cache.paragraphAt(0), p0), isTrue);
      expect(identical(cache.paragraphAt(1), p1), isFalse);
      expect(identical(cache.paragraphAt(2), p2), isTrue);
    });

    test('changing hyperlink marks both old and new URI rows dirty', () {
      final terminal = Terminal(cols: 30, rows: 3);
      addTearDown(terminal.dispose);
      terminal.write(
        Uint8List.fromList(
          utf8.encode(
            '\x1b]8;;https://a.com\x1b\\linkA\x1b]8;;\x1b\\\r\n'
            '\x1b]8;;https://b.com\x1b\\linkB\x1b]8;;\x1b\\\r\n'
            'plain',
          ),
        ),
      );

      ctx.rows = 3;
      ctx.cols = 30;
      cache.updateGridSize();
      cache.rebuildDirty((row) => terminal.screen.lineAt(row));

      cache.highlightedHyperlink = 'https://a.com';
      cache.rebuildDirty((row) => terminal.screen.lineAt(row));
      final p0 = cache.paragraphAt(0);
      final p1 = cache.paragraphAt(1);
      final p2 = cache.paragraphAt(2);

      cache.highlightedHyperlink = 'https://b.com';
      cache.rebuildDirty((row) => terminal.screen.lineAt(row));

      expect(identical(cache.paragraphAt(0), p0), isFalse);
      expect(identical(cache.paragraphAt(1), p1), isFalse);
      expect(identical(cache.paragraphAt(2), p2), isTrue);
    });

    test('setting same hyperlink value is a no-op', () {
      final terminal = Terminal(cols: 20, rows: 2);
      addTearDown(terminal.dispose);
      terminal.write(
        Uint8List.fromList(
          utf8.encode('\x1b]8;;https://a.com\x1b\\link\x1b]8;;\x1b\\\r\nplain'),
        ),
      );

      ctx.rows = 2;
      ctx.cols = 20;
      cache.updateGridSize();
      cache.rebuildDirty((row) => terminal.screen.lineAt(row));

      cache.highlightedHyperlink = 'https://a.com';
      cache.rebuildDirty((row) => terminal.screen.lineAt(row));
      final p0 = cache.paragraphAt(0);

      cache.highlightedHyperlink = 'https://a.com';
      cache.rebuildDirty((row) => terminal.screen.lineAt(row));

      expect(identical(cache.paragraphAt(0), p0), isTrue);
    });
  });

  group('background runs', () {
    test('cells with background color produce ColorRun entries', () {
      final terminal = Terminal(cols: 10, rows: 1);
      addTearDown(terminal.dispose);
      terminal.write(Uint8List.fromList(utf8.encode('\x1b[42mHello\x1b[0m')));

      ctx.rows = 1;
      ctx.cols = 10;
      cache.updateGridSize();
      cache.rebuildDirty((row) => terminal.screen.lineAt(row));

      final runs = cache.backgroundRunsAt(0);
      expect(runs, isNotEmpty);
      expect(runs.first.startCol, 0);
      expect(runs.first.endCol, 5);
    });
  });
}

const _metrics = CellMetrics(cellWidth: 8, cellHeight: 16, baseline: 12);

class _FakeScreen implements Screen {
  @override
  final int rows;

  @override
  final DirtyState dirtyState;

  final Set<int> _dirtyRows;

  _FakeScreen(this.rows, this.dirtyState, this._dirtyRows);

  @override
  int get cols => 10;

  @override
  Cell cellAt(int row, int col) => Cell.empty;

  @override
  bool isRowDirty(int row) => _dirtyRows.contains(row);

  @override
  bool isRowWrapped(int row) => false;

  @override
  Line lineAt(int row) => const Line([]);
}
