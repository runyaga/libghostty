@Tags(['ffi'])
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flterm/src/foundation/screen_extension.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libghostty/libghostty.dart';

void main() {
  group('Terminal screen extension', () {
    late Terminal terminal;

    setUp(() {
      terminal = Terminal(cols: 20, rows: 3);
      terminal.write(Uint8List.fromList(utf8.encode('AB日CD')));
    });

    tearDown(() => terminal.dispose());

    group('snapColToWideBoundary', () {
      test('returns narrow cells unchanged', () {
        expect(terminal.snapColToWideBoundary(0, 0, inclusive: true), 0);
        expect(terminal.snapColToWideBoundary(0, 0, inclusive: false), 0);
      });

      test('snaps wide cells by inclusion mode', () {
        expect(terminal.snapColToWideBoundary(0, 2, inclusive: true), 2);
        expect(terminal.snapColToWideBoundary(0, 2, inclusive: false), 4);
        expect(terminal.snapColToWideBoundary(0, 3, inclusive: true), 2);
        expect(terminal.snapColToWideBoundary(0, 3, inclusive: false), 4);
      });

      test('returns out-of-bounds columns unchanged', () {
        expect(terminal.snapColToWideBoundary(-1, 3, inclusive: true), 3);
        expect(terminal.snapColToWideBoundary(99, 3, inclusive: true), 3);
        expect(terminal.snapColToWideBoundary(0, -1, inclusive: true), -1);
        expect(terminal.snapColToWideBoundary(0, 20, inclusive: true), 20);
      });
    });

    group('snapSelectionCols', () {
      test('snaps columns by selection direction', () {
        final (rightStart, rightEnd) = terminal.snapSelectionCols(0, 3, 0, 5);
        expect(rightStart, 2);
        expect(rightEnd, 5);

        final (leftStart, leftEnd) = terminal.snapSelectionCols(0, 3, 0, 0);
        expect(leftStart, 4);
        expect(leftEnd, 0);

        final (multiStart, multiEnd) = terminal.snapSelectionCols(0, 3, 1, 0);
        expect(multiStart, 2);
        expect(multiEnd, 0);
      });
    });

    group('wordBoundaryAt', () {
      test('selects wide characters from spacer tails', () {
        final (start, end) = terminal.wordBoundaryAt(0, 3);
        expect(start, 2);
        expect(end, 4);
      });
    });

    group('lineBoundaryAt', () {
      test('trims trailing empty cells on non-wrapped rows', () {
        final b = terminal.lineBoundaryAt(0);
        expect(b.startRow, 0);
        expect(b.endRow, 0);
        expect(b.endCol, 6);
      });

      test('spans wrapped rows with trimmed ends', () {
        final t = Terminal(cols: 5, rows: 4);
        addTearDown(t.dispose);
        t.write(Uint8List.fromList(utf8.encode('ABCDEFGH')));

        final b0 = t.lineBoundaryAt(0);
        expect(b0.startRow, 0);
        expect(b0.endRow, 1);
        expect(b0.endCol, 3);

        final b1 = t.lineBoundaryAt(1);
        expect(b1, b0);
      });

      test('returns independent boundaries for separate lines', () {
        final t = Terminal(cols: 5, rows: 4);
        addTearDown(t.dispose);
        t.write(Uint8List.fromList(utf8.encode('AB\r\nCD')));

        expect(t.lineBoundaryAt(0).endCol, 2);
        expect(t.lineBoundaryAt(1).endCol, 2);
        expect(t.lineBoundaryAt(1).startRow, 1);
      });

      test('returns safe defaults for out-of-bounds rows', () {
        expect(terminal.lineBoundaryAt(-1).endCol, 0);
        expect(terminal.lineBoundaryAt(99).endCol, 0);
      });
    });

    group('linkAt', () {
      void writeRow(String text) {
        terminal.write(Uint8List.fromList(utf8.encode('\x1b[2J\x1b[H$text')));
      }

      test('extracts a path token (slashes/dots kept)', () {
        writeRow('src/a_b.dart');
        final r = terminal.linkAt(0, 1);
        expect(r.token, 'src/a_b.dart');
        expect(r.uri, isNull);
      });

      test('extracts a URL token (query/fragment kept)', () {
        writeRow('https://x.io/y?q=1#z');
        expect(terminal.linkAt(0, 0).token, 'https://x.io/y?q=1#z');
      });

      test('returns null token over a non-link cell', () {
        writeRow('a b');
        final r = terminal.linkAt(0, 1); // the space
        expect(r.token, isNull);
        expect(r.uri, isNull);
      });

      test('returns nulls for out-of-bounds cells', () {
        expect(terminal.linkAt(-1, 0), (token: null, uri: null, tail: ''));
        expect(terminal.linkAt(0, 999), (token: null, uri: null, tail: ''));
      });

      test('reports the OSC 8 hyperlink uri', () {
        writeRow('\x1b]8;;https://e.test\x1b\\Link\x1b]8;;\x1b\\');
        final r = terminal.linkAt(0, 0);
        expect(r.uri, 'https://e.test');
        expect(r.token, 'Link');
      });

      test('tail spans to end-of-row so spaces after the token are kept', () {
        writeRow('a.md (1).pdf'); // fits the 20-col test grid
        final r = terminal.linkAt(0, 0);
        expect(r.token, 'a.md'); // bare token stops at the space
        expect(r.tail, 'a.md (1).pdf'); // tail keeps the rest
      });
    });
  });
}
