import 'package:flterm/src/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libghostty/libghostty.dart' show Key, MouseShape;

void main() {
  group('keyFromPhysical', () {
    test('maps all key categories correctly', () {
      expect(keyFromPhysical(PhysicalKeyboardKey.keyA), Key.keyA);
      expect(keyFromPhysical(PhysicalKeyboardKey.keyM), Key.keyM);
      expect(keyFromPhysical(PhysicalKeyboardKey.keyZ), Key.keyZ);

      expect(keyFromPhysical(PhysicalKeyboardKey.digit0), Key.digit0);
      expect(keyFromPhysical(PhysicalKeyboardKey.digit5), Key.digit5);
      expect(keyFromPhysical(PhysicalKeyboardKey.digit9), Key.digit9);

      expect(keyFromPhysical(PhysicalKeyboardKey.arrowUp), Key.arrowUp);
      expect(keyFromPhysical(PhysicalKeyboardKey.arrowDown), Key.arrowDown);
      expect(keyFromPhysical(PhysicalKeyboardKey.arrowLeft), Key.arrowLeft);
      expect(keyFromPhysical(PhysicalKeyboardKey.arrowRight), Key.arrowRight);

      expect(keyFromPhysical(PhysicalKeyboardKey.f1), Key.f1);
      expect(keyFromPhysical(PhysicalKeyboardKey.f12), Key.f12);
      expect(keyFromPhysical(PhysicalKeyboardKey.f24), Key.f24);

      expect(keyFromPhysical(PhysicalKeyboardKey.shiftLeft), Key.shiftLeft);
      expect(keyFromPhysical(PhysicalKeyboardKey.shiftRight), Key.shiftRight);
      expect(keyFromPhysical(PhysicalKeyboardKey.controlLeft), Key.controlLeft);
      expect(keyFromPhysical(PhysicalKeyboardKey.altLeft), Key.altLeft);
      expect(keyFromPhysical(PhysicalKeyboardKey.metaLeft), Key.metaLeft);

      expect(keyFromPhysical(PhysicalKeyboardKey.enter), Key.enter);
      expect(keyFromPhysical(PhysicalKeyboardKey.backspace), Key.backspace);
      expect(keyFromPhysical(PhysicalKeyboardKey.tab), Key.tab);
      expect(keyFromPhysical(PhysicalKeyboardKey.space), Key.space);
      expect(keyFromPhysical(PhysicalKeyboardKey.escape), Key.escape);

      expect(keyFromPhysical(PhysicalKeyboardKey.home), Key.home);
      expect(keyFromPhysical(PhysicalKeyboardKey.end), Key.end);
      expect(keyFromPhysical(PhysicalKeyboardKey.pageUp), Key.pageUp);
      expect(keyFromPhysical(PhysicalKeyboardKey.pageDown), Key.pageDown);
      expect(keyFromPhysical(PhysicalKeyboardKey.insert), Key.insert);
      expect(keyFromPhysical(PhysicalKeyboardKey.delete), Key.delete);

      expect(keyFromPhysical(PhysicalKeyboardKey.numpad0), Key.numpad0);
      expect(keyFromPhysical(PhysicalKeyboardKey.numpad9), Key.numpad9);
      expect(keyFromPhysical(PhysicalKeyboardKey.numpadAdd), Key.numpadAdd);
      expect(keyFromPhysical(PhysicalKeyboardKey.numpadEnter), Key.numpadEnter);

      expect(keyFromPhysical(PhysicalKeyboardKey.comma), Key.comma);
      expect(keyFromPhysical(PhysicalKeyboardKey.period), Key.period);
      expect(keyFromPhysical(PhysicalKeyboardKey.semicolon), Key.semicolon);
      expect(keyFromPhysical(PhysicalKeyboardKey.slash), Key.slash);
      expect(keyFromPhysical(PhysicalKeyboardKey.backquote), Key.backquote);
    });

    test('unmapped key returns Key.unidentified', () {
      final unknown =
          PhysicalKeyboardKey.findKeyByCode(0x999999) ??
          const PhysicalKeyboardKey(0x999999);
      expect(keyFromPhysical(unknown), Key.unidentified);
    });
  });

  group('Key enum contiguity', () {
    test('keyA..keyZ and digit0..digit9 indices are contiguous', () {
      expect(Key.keyZ.index - Key.keyA.index, 25);
      expect(Key.digit9.index - Key.digit0.index, 9);
    });
  });

  group('keyFromCodepoint', () {
    test('lowercase letters map to letter keys', () {
      expect(keyFromCodepoint(0x61), Key.keyA);
      expect(keyFromCodepoint(0x7a), Key.keyZ);
      expect(keyFromCodepoint(0x6d), Key.keyM);
    });

    test('uppercase letters map to same letter keys', () {
      expect(keyFromCodepoint(0x41), Key.keyA);
      expect(keyFromCodepoint(0x5a), Key.keyZ);
    });

    test('digits map to digit keys', () {
      expect(keyFromCodepoint(0x30), Key.digit0);
      expect(keyFromCodepoint(0x39), Key.digit9);
      expect(keyFromCodepoint(0x35), Key.digit5);
    });

    test('space maps to space key', () {
      expect(keyFromCodepoint(0x20), Key.space);
    });

    test('unmapped codepoints return null', () {
      expect(keyFromCodepoint(0x00), isNull);
      expect(keyFromCodepoint(0x1b), isNull);
      expect(keyFromCodepoint(0x7f), isNull);
      expect(keyFromCodepoint(0x100), isNull);
    });
  });

  group('unshiftedCodepointForKey', () {
    test('letter keys return lowercase ASCII', () {
      expect(unshiftedCodepointForKey(Key.keyA), 0x61);
      expect(unshiftedCodepointForKey(Key.keyZ), 0x7a);
    });

    test('digit keys return ASCII digit', () {
      expect(unshiftedCodepointForKey(Key.digit0), 0x30);
      expect(unshiftedCodepointForKey(Key.digit9), 0x39);
    });

    test('non-character keys return 0', () {
      expect(unshiftedCodepointForKey(Key.enter), 0);
      expect(unshiftedCodepointForKey(Key.arrowUp), 0);
      expect(unshiftedCodepointForKey(Key.f1), 0);
    });
  });

  group('cursorFromMouseShape', () {
    test('text shape returns text cursor', () {
      expect(cursorFromMouseShape(MouseShape.text), SystemMouseCursors.text);
    });

    test('pointer shape returns click cursor', () {
      expect(
        cursorFromMouseShape(MouseShape.pointer),
        SystemMouseCursors.click,
      );
    });

    test('default shape returns basic cursor', () {
      expect(
        cursorFromMouseShape(MouseShape.defaultCursor),
        SystemMouseCursors.basic,
      );
    });

    test('resize shapes return corresponding cursors', () {
      expect(
        cursorFromMouseShape(MouseShape.colResize),
        SystemMouseCursors.resizeColumn,
      );
      expect(
        cursorFromMouseShape(MouseShape.rowResize),
        SystemMouseCursors.resizeRow,
      );
      expect(
        cursorFromMouseShape(MouseShape.nResize),
        SystemMouseCursors.resizeUp,
      );
      expect(
        cursorFromMouseShape(MouseShape.eResize),
        SystemMouseCursors.resizeRight,
      );
    });

    test('grab shapes return grab cursors', () {
      expect(cursorFromMouseShape(MouseShape.grab), SystemMouseCursors.grab);
      expect(
        cursorFromMouseShape(MouseShape.grabbing),
        SystemMouseCursors.grabbing,
      );
    });

    test('compound resize shapes fall back to basic', () {
      expect(
        cursorFromMouseShape(MouseShape.ewResize),
        SystemMouseCursors.basic,
      );
      expect(
        cursorFromMouseShape(MouseShape.nsResize),
        SystemMouseCursors.basic,
      );
      expect(
        cursorFromMouseShape(MouseShape.neswResize),
        SystemMouseCursors.basic,
      );
      expect(
        cursorFromMouseShape(MouseShape.nwseResize),
        SystemMouseCursors.basic,
      );
    });

    test('all MouseShape values produce a cursor without throwing', () {
      for (final shape in MouseShape.values) {
        expect(() => cursorFromMouseShape(shape), returnsNormally);
      }
    });
  });
}
