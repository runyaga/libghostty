@Tags(['ffi'])
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flterm/src/foundation.dart';
import 'package:flterm/src/rendering.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libghostty/libghostty.dart';

import '../helpers/font_loader.dart';

void main() {
  setUpAll(loadBundledFonts);

  group('Cursor shape goldens', () {
    late Terminal terminal;
    late CellMetrics metrics;

    setUp(() {
      terminal = Terminal(cols: _cols, rows: _rows);
      terminal.write(
        Uint8List.fromList(utf8.encode('Hello World!\r\n\x1b[1;4H')),
      );
      final theme = TerminalTheme.dark();
      metrics = measureCellMetrics(
        fontFamily: theme.fontFamily,
        fontSize: theme.fontSize,
      );
    });

    tearDown(() => terminal.dispose());

    Future<void> pump(WidgetTester tester, TerminalTheme theme) async {
      final w = _cols * metrics.cellWidth;
      final h = _rows * metrics.cellHeight;
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = Size(w, h);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: w, maxHeight: h),
              child: TerminalRenderer(
                terminal: terminal,
                theme: theme,
                metrics: metrics,
                offset: ViewportOffset.zero(),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('block cursor', (tester) async {
      await pump(tester, _cursorTheme(CursorShape.block));
      await expectLater(
        find.byType(TerminalRenderer),
        matchesGoldenFile('goldens/cursor_block.png'),
      );
    });

    testWidgets('block hollow cursor', (tester) async {
      await pump(tester, _cursorTheme(CursorShape.blockHollow));
      await expectLater(
        find.byType(TerminalRenderer),
        matchesGoldenFile('goldens/cursor_block_hollow.png'),
      );
    });

    testWidgets('underline cursor', (tester) async {
      await pump(tester, _cursorTheme(CursorShape.underline));
      await expectLater(
        find.byType(TerminalRenderer),
        matchesGoldenFile('goldens/cursor_underline.png'),
      );
    });

    testWidgets('bar cursor', (tester) async {
      await pump(tester, _cursorTheme(CursorShape.bar));
      await expectLater(
        find.byType(TerminalRenderer),
        matchesGoldenFile('goldens/cursor_bar.png'),
      );
    });

    testWidgets('cursor with explicit color', (tester) async {
      await pump(
        tester,
        _cursorTheme(CursorShape.block, color: const Color(0xFF00FF88)),
      );
      await expectLater(
        find.byType(TerminalRenderer),
        matchesGoldenFile('goldens/cursor_custom_color.png'),
      );
    });

    testWidgets('hidden cursor', (tester) async {
      terminal.write(Uint8List.fromList(utf8.encode('\x1b[?25l')));
      await pump(tester, _cursorTheme(CursorShape.block));
      await expectLater(
        find.byType(TerminalRenderer),
        matchesGoldenFile('goldens/cursor_hidden.png'),
      );
    });
  });

  group('Cursor on wide character', () {
    late CellMetrics metrics;

    setUp(() {
      final theme = TerminalTheme.dark();
      metrics = measureCellMetrics(
        fontFamily: theme.fontFamily,
        fontSize: theme.fontSize,
      );
    });

    Future<void> pumpWide(
      WidgetTester tester,
      Terminal terminal,
      TerminalTheme theme,
    ) async {
      final w = _cols * metrics.cellWidth;
      final h = _rows * metrics.cellHeight;
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = Size(w, h);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: w, maxHeight: h),
              child: TerminalRenderer(
                terminal: terminal,
                theme: theme,
                metrics: metrics,
                offset: ViewportOffset.zero(),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('block cursor on checkmark emoji', (tester) async {
      final terminal = Terminal(cols: _cols, rows: _rows);
      addTearDown(terminal.dispose);
      // ✅ U+2705 (wide emoji)
      terminal.write(
        Uint8List.fromList([
          ...utf8.encode('AB'),
          0xE2, 0x9C, 0x85, // ✅
          ...utf8.encode('CD'),
          ...utf8.encode('\x1b[1;3H'),
        ]),
      );

      await pumpWide(
        tester,
        terminal,
        _cursorTheme(CursorShape.block, fallback: _emojiFallback),
      );
      await expectLater(
        find.byType(TerminalRenderer),
        matchesGoldenFile('goldens/cursor_block_emoji.png'),
      );
    });

    testWidgets('hollow cursor on checkmark emoji', (tester) async {
      final terminal = Terminal(cols: _cols, rows: _rows);
      addTearDown(terminal.dispose);
      terminal.write(
        Uint8List.fromList([
          ...utf8.encode('AB'),
          0xE2, 0x9C, 0x85, // ✅
          ...utf8.encode('CD'),
          ...utf8.encode('\x1b[1;3H'),
        ]),
      );

      await pumpWide(
        tester,
        terminal,
        _cursorTheme(CursorShape.blockHollow, fallback: _emojiFallback),
      );
      await expectLater(
        find.byType(TerminalRenderer),
        matchesGoldenFile('goldens/cursor_hollow_emoji.png'),
      );
    });

    testWidgets('block cursor on CJK character', (tester) async {
      final terminal = Terminal(cols: _cols, rows: _rows);
      addTearDown(terminal.dispose);
      terminal.write(
        Uint8List.fromList([
          ...utf8.encode('AB'),
          0xE6, 0x97, 0xA5, // 日
          ...utf8.encode('CD'),
          ...utf8.encode('\x1b[1;3H'),
        ]),
      );

      await pumpWide(
        tester,
        terminal,
        _cursorTheme(CursorShape.block, fallback: _cjkFallback),
      );
      await expectLater(
        find.byType(TerminalRenderer),
        matchesGoldenFile('goldens/cursor_block_wide.png'),
      );
    });

    testWidgets('underline cursor on wide char', (tester) async {
      final terminal = Terminal(cols: _cols, rows: _rows);
      addTearDown(terminal.dispose);
      terminal.write(
        Uint8List.fromList([
          ...utf8.encode('AB'),
          0xE2, 0x9C, 0x85, // ✅
          ...utf8.encode('CD'),
          ...utf8.encode('\x1b[1;3H'),
        ]),
      );

      await pumpWide(
        tester,
        terminal,
        _cursorTheme(CursorShape.underline, fallback: _emojiFallback),
      );
      await expectLater(
        find.byType(TerminalRenderer),
        matchesGoldenFile('goldens/cursor_underline_emoji.png'),
      );
    });
  });
}

const _cols = 15;
const _rows = 3;

const _cjkFallback = ['Noto Sans JP', 'JetBrains Mono'];
const _emojiFallback = ['Noto Emoji', 'JetBrains Mono'];

TerminalTheme _cursorTheme(
  CursorShape shape, {
  Color? color,
  List<String>? fallback,
}) {
  return TerminalTheme.dark().copyWith(
    fontFamilyFallback: fallback,
    cursor: CursorTheme(
      shape: shape,
      color: color,
      blinkInterval: const Duration(hours: 1),
    ),
  );
}
