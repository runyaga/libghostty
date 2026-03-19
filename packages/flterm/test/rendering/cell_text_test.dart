import 'package:flterm/src/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libghostty/libghostty.dart';

void main() {
  group('cellText', () {
    test('normal cell produces its content', () {
      const cell = Cell(content: 'A');
      expect(cellText(cell, blinkVisible: true), 'A');
    });

    test('empty, invisible, and hidden-blink cells produce a space', () {
      expect(cellText(Cell.empty, blinkVisible: true), ' ');
      expect(
        cellText(
          const Cell(content: 'A', style: CellStyle(invisible: true)),
          blinkVisible: true,
        ),
        ' ',
      );
      expect(
        cellText(
          const Cell(content: 'A', style: CellStyle(blink: true)),
          blinkVisible: false,
        ),
        ' ',
      );
    });

    test('blink cell shows content when blink is visible', () {
      const cell = Cell(content: 'A', style: CellStyle(blink: true));
      expect(cellText(cell, blinkVisible: true), 'A');
    });
  });
}
