@Tags(['ffi'])
library;

import 'dart:typed_data';

import 'package:libghostty/libghostty.dart';
import 'package:test/test.dart';

void main() {
  group('GridRef', () {
    late Terminal terminal;

    setUp(() {
      terminal = Terminal(cols: 80, rows: 24);
      terminal.write(Uint8List.fromList('Hello'.codeUnits));
    });

    tearDown(() {
      terminal.dispose();
    });

    group('content', () {
      test('returns content for selected cells', () {
        final ref = GridRef.at(terminal, col: 0, row: 0);
        addTearDown(ref.dispose);
        expect(ref.content, 'H');

        final otherRef = GridRef.at(terminal, col: 4, row: 0);
        addTearDown(otherRef.dispose);
        expect(otherRef.content, 'o');

        final emptyRef = GridRef.at(terminal, col: 79, row: 23);
        addTearDown(emptyRef.dispose);
        expect(emptyRef.content, isEmpty);
      });
    });

    group('handles', () {
      test('returns valid cell and row handles', () {
        final ref = GridRef.at(terminal, col: 0, row: 0);
        addTearDown(ref.dispose);
        expect(ref.cell, isNonZero);
        expect(ref.row, isNonZero);
      });
    });

    group('style', () {
      test('reflects bold attribute', () {
        terminal.write(Uint8List.fromList('\x1b[1mB'.codeUnits));
        final ref = GridRef.at(terminal, col: 5, row: 0);
        addTearDown(ref.dispose);
        expect(ref.style, isA<Style>());
        expect(ref.style.bold, isTrue);
      });
    });

    group('graphemes', () {
      test('returns codepoint list', () {
        final ref = GridRef.at(terminal, col: 0, row: 0);
        addTearDown(ref.dispose);
        expect(ref.graphemes, contains(0x48));
      });
    });

    group('wide', () {
      test('returns cell width classification', () {
        final ref = GridRef.at(terminal, col: 0, row: 0);
        addTearDown(ref.dispose);
        expect(ref.wide, CellWidth.narrow);
        expect(ref.isWide, isFalse);

        terminal.write(Uint8List.fromList([0xE6, 0x97, 0xA5]));
        final wideRef = GridRef.at(terminal, col: 5, row: 0);
        addTearDown(wideRef.dispose);
        expect(wideRef.wide, CellWidth.wide);
        expect(wideRef.isWide, isTrue);
      });
    });
  });
}
