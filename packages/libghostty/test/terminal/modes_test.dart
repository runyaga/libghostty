@Tags(['ffi'])
library;

import 'package:libghostty/libghostty.dart';
import 'package:test/test.dart';

void main() {
  group('TerminalModes', () {
    test('defaults', () {
      const modes = TerminalModes();
      expect(modes.bracketedPaste, isFalse);
      expect(modes.screenMode, ScreenMode.primary);
      expect(modes.cursorKeyApplication, isFalse);
      expect(modes.keypadApplication, isFalse);
      expect(modes.autoWrap, isTrue);
      expect(modes.originMode, isFalse);
      expect(modes.insertMode, isFalse);
      expect(modes.mouseTracking, MouseTracking.none);
      expect(modes.mouseAlternateScroll, isTrue);
    });

    test('equality compares all fields', () {
      const a = TerminalModes(
        screenMode: ScreenMode.alternate,
        mouseTracking: MouseTracking.normal,
        mouseAlternateScroll: false,
      );
      const b = TerminalModes(
        screenMode: ScreenMode.alternate,
        mouseTracking: MouseTracking.normal,
        mouseAlternateScroll: false,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));

      expect(
        a,
        isNot(
          const TerminalModes(
            mouseTracking: MouseTracking.normal,
            mouseAlternateScroll: false,
          ),
        ),
      );
      expect(
        a,
        isNot(
          const TerminalModes(
            screenMode: ScreenMode.alternate,
            mouseTracking: MouseTracking.x10,
            mouseAlternateScroll: false,
          ),
        ),
      );
      expect(
        a,
        isNot(
          const TerminalModes(
            screenMode: ScreenMode.alternate,
            mouseTracking: MouseTracking.normal,
          ),
        ),
      );
    });

    test('copyWith changes target field and preserves others', () {
      const original = TerminalModes(
        bracketedPaste: true,
        autoWrap: false,
        mouseAlternateScroll: false,
      );
      final modified = original.copyWith(screenMode: ScreenMode.alternate);
      expect(modified.screenMode, ScreenMode.alternate);
      expect(modified.bracketedPaste, isTrue);
      expect(modified.autoWrap, isFalse);
      expect(modified.mouseAlternateScroll, isFalse);
    });

    test('toString includes active non-default flags', () {
      const modes = TerminalModes(
        screenMode: ScreenMode.alternate,
        mouseTracking: MouseTracking.button,
      );
      final str = modes.toString();
      expect(str, contains('screenMode:alternate'));
      expect(str, contains('mouseTracking:button'));
      expect(str, contains('mouseAlternateScroll'));
    });

    test('toString omits inactive flags', () {
      const modes = TerminalModes(autoWrap: false, mouseAlternateScroll: false);
      final str = modes.toString();
      expect(str, isNot(contains('screenMode')));
      expect(str, isNot(contains('mouseTracking')));
      expect(str, isNot(contains('mouseAlternateScroll')));
      expect(str, isNot(contains('autoWrap')));
    });
  });
}
