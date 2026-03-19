import 'package:flterm/src/rendering.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libghostty/libghostty.dart';

void main() {
  const fg = Color(0xFFD8D8D8);

  CellStyleKey base({
    bool bold = false,
    bool italic = false,
    bool faint = false,
    bool strikethrough = false,
    bool overline = false,
    UnderlineStyle underline = UnderlineStyle.none,
    Color? underlineColor,
  }) {
    return CellStyleKey(
      bold: bold,
      italic: italic,
      faint: faint,
      strikethrough: strikethrough,
      overline: overline,
      foreground: fg,
      underline: underline,
      underlineColor: underlineColor,
    );
  }

  group('CellStyleKey', () {
    test('equality and hashCode', () {
      expect(base(), equals(base()));
      expect(base().hashCode, base().hashCode);
    });

    test('each field contributes to identity', () {
      final plain = base();
      expect(plain, isNot(equals(base(bold: true))));
      expect(plain, isNot(equals(base(italic: true))));
      expect(plain, isNot(equals(base(faint: true))));
      expect(plain, isNot(equals(base(strikethrough: true))));
      expect(plain, isNot(equals(base(overline: true))));
      expect(plain, isNot(equals(base(underline: UnderlineStyle.single))));
      expect(
        base(underline: UnderlineStyle.single),
        isNot(
          equals(
            base(
              underline: UnderlineStyle.single,
              underlineColor: const Color(0xFFFF0000),
            ),
          ),
        ),
      );

      const a = CellStyleKey(
        bold: false,
        italic: false,
        faint: false,
        strikethrough: false,
        overline: false,
        foreground: Color(0xFFFF0000),
        underline: UnderlineStyle.none,
      );
      const b = CellStyleKey(
        bold: false,
        italic: false,
        faint: false,
        strikethrough: false,
        overline: false,
        foreground: Color(0xFF0000FF),
        underline: UnderlineStyle.none,
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('CellStyleKey.buildTextStyle', () {
    const fontFamily = 'monospace';
    const fontSize = 14.0;
    const fallback = ['Menlo', 'Consolas'];

    test('plain key produces default style', () {
      final ts = base().buildTextStyle(fontFamily, fontSize, fallback);
      expect(ts.fontWeight, FontWeight.normal);
      expect(ts.fontStyle, FontStyle.normal);
      expect(ts.decoration, TextDecoration.none);
      expect(ts.color, fg);
      expect(ts.fontFamily, fontFamily);
      expect(ts.fontSize, fontSize);
    });

    test('bold sets FontWeight.bold', () {
      final ts = base(
        bold: true,
      ).buildTextStyle(fontFamily, fontSize, fallback);
      expect(ts.fontWeight, FontWeight.bold);
    });

    test('italic sets FontStyle.italic', () {
      final ts = base(
        italic: true,
      ).buildTextStyle(fontFamily, fontSize, fallback);
      expect(ts.fontStyle, FontStyle.italic);
    });

    test('underline styles map to correct decoration styles', () {
      const mapping = {
        UnderlineStyle.single: TextDecorationStyle.solid,
        UnderlineStyle.doubleLine: TextDecorationStyle.double,
        UnderlineStyle.curly: TextDecorationStyle.wavy,
        UnderlineStyle.dotted: TextDecorationStyle.dotted,
        UnderlineStyle.dashed: TextDecorationStyle.dashed,
      };
      for (final MapEntry(:key, :value) in mapping.entries) {
        final ts = base(
          underline: key,
        ).buildTextStyle(fontFamily, fontSize, fallback);
        expect(
          ts.decoration,
          containsDecoration(TextDecoration.underline),
          reason: '$key',
        );
        expect(ts.decorationStyle, value, reason: '$key');
      }
    });

    test('strikethrough sets lineThrough', () {
      final ts = base(
        strikethrough: true,
      ).buildTextStyle(fontFamily, fontSize, fallback);
      expect(ts.decoration, containsDecoration(TextDecoration.lineThrough));
    });

    test('overline sets overline', () {
      final ts = base(
        overline: true,
      ).buildTextStyle(fontFamily, fontSize, fallback);
      expect(ts.decoration, containsDecoration(TextDecoration.overline));
    });

    test('combined underline + strikethrough includes both', () {
      final ts = base(
        underline: UnderlineStyle.single,
        strikethrough: true,
      ).buildTextStyle(fontFamily, fontSize, fallback);
      expect(ts.decoration, containsDecoration(TextDecoration.underline));
      expect(ts.decoration, containsDecoration(TextDecoration.lineThrough));
    });

    test('underlineColor sets decorationColor', () {
      final ts = base(
        underline: UnderlineStyle.single,
        underlineColor: const Color(0xFFFF0000),
      ).buildTextStyle(fontFamily, fontSize, fallback);
      expect(ts.decorationColor, const Color(0xFFFF0000));
    });
  });
}

Matcher containsDecoration(TextDecoration d) {
  return predicate<TextDecoration>((v) => v.contains(d), 'contains $d');
}
