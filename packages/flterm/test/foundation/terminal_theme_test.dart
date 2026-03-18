import 'package:flterm/src/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libghostty/libghostty.dart';

void main() {
  group('CursorTheme', () {
    test('defaults: block shape, no color, 600ms blink', () {
      const cursor = CursorTheme();
      expect(cursor.shape, CursorShape.block);
      expect(cursor.color, isNull);
      expect(cursor.blinkInterval, const Duration(milliseconds: 600));
    });

    test('stores custom values', () {
      const cursor = CursorTheme(
        shape: CursorShape.bar,
        color: Color(0xFFFF0000),
        blinkInterval: Duration(milliseconds: 500),
      );
      expect(cursor.shape, CursorShape.bar);
      expect(cursor.color, const Color(0xFFFF0000));
      expect(cursor.blinkInterval, const Duration(milliseconds: 500));
    });

    test('equality and hashCode', () {
      const a = CursorTheme();
      const b = CursorTheme();
      const c = CursorTheme(shape: CursorShape.bar);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });

    test('lerp at boundaries returns endpoints', () {
      const a = CursorTheme(
        color: Color(0xFF000000),
        blinkInterval: Duration(milliseconds: 400),
      );
      const b = CursorTheme(
        shape: CursorShape.bar,
        color: Color(0xFFFFFFFF),
        blinkInterval: Duration(milliseconds: 800),
      );
      final at0 = CursorTheme.lerp(a, b, 0.0)!;
      expect(at0.shape, CursorShape.block);
      expect(at0.blinkInterval, const Duration(milliseconds: 400));

      final at1 = CursorTheme.lerp(a, b, 1.0)!;
      expect(at1.shape, CursorShape.bar);
      expect(at1.blinkInterval, const Duration(milliseconds: 800));
    });

    test('lerp snaps shape at midpoint', () {
      const a = CursorTheme();
      const b = CursorTheme(shape: CursorShape.bar);
      expect(CursorTheme.lerp(a, b, 0.49)!.shape, CursorShape.block);
      expect(CursorTheme.lerp(a, b, 0.5)!.shape, CursorShape.bar);
    });

    test('lerp with null returns other at boundary', () {
      const a = CursorTheme();
      expect(CursorTheme.lerp(a, null, 0.0), a);
      expect(CursorTheme.lerp(a, null, 1.0), isNull);
      expect(CursorTheme.lerp(null, a, 0.0), isNull);
      expect(CursorTheme.lerp(null, a, 1.0), a);
    });
  });

  group('HyperlinkStyle', () {
    test('defaults: no underline, no colors', () {
      const style = HyperlinkStyle();
      expect(style.underline, UnderlineStyle.none);
      expect(style.underlineColor, isNull);
      expect(style.textColor, isNull);
    });

    test('stores custom values', () {
      const style = HyperlinkStyle(
        underline: UnderlineStyle.single,
        underlineColor: Color(0xFF00FF00),
        textColor: Color(0xFF0000FF),
      );
      expect(style.underline, UnderlineStyle.single);
      expect(style.underlineColor, const Color(0xFF00FF00));
      expect(style.textColor, const Color(0xFF0000FF));
    });

    test('equality and hashCode', () {
      const a = HyperlinkStyle();
      const b = HyperlinkStyle();
      const c = HyperlinkStyle(underline: UnderlineStyle.single);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });

    test('each field contributes to identity', () {
      const plain = HyperlinkStyle();
      expect(
        plain,
        isNot(equals(const HyperlinkStyle(underline: UnderlineStyle.single))),
      );
      expect(
        plain,
        isNot(equals(const HyperlinkStyle(underlineColor: Color(0xFFFF0000)))),
      );
      expect(
        plain,
        isNot(equals(const HyperlinkStyle(textColor: Color(0xFFFF0000)))),
      );
    });

    test('lerp snaps underline at midpoint', () {
      const a = HyperlinkStyle();
      const b = HyperlinkStyle(underline: UnderlineStyle.single);
      expect(HyperlinkStyle.lerp(a, b, 0.49)!.underline, UnderlineStyle.none);
      expect(HyperlinkStyle.lerp(a, b, 0.5)!.underline, UnderlineStyle.single);
    });

    test('lerp interpolates colors', () {
      const a = HyperlinkStyle(textColor: Color(0xFF000000));
      const b = HyperlinkStyle(textColor: Color(0xFFFFFFFF));
      final mid = HyperlinkStyle.lerp(a, b, 0.5)!;
      expect(mid.textColor, isNot(equals(a.textColor)));
      expect(mid.textColor, isNot(equals(b.textColor)));
    });

    test('lerp with null returns other at boundary', () {
      const a = HyperlinkStyle();
      expect(HyperlinkStyle.lerp(a, null, 0.0), a);
      expect(HyperlinkStyle.lerp(a, null, 1.0), isNull);
      expect(HyperlinkStyle.lerp(null, a, 0.0), isNull);
      expect(HyperlinkStyle.lerp(null, a, 1.0), a);
    });
  });

  group('HyperlinkTheme', () {
    test('defaults: idle invisible, highlighted has single underline', () {
      const theme = HyperlinkTheme();
      expect(theme.idle.underline, UnderlineStyle.none);
      expect(theme.idle.textColor, isNull);
      expect(theme.highlighted.underline, UnderlineStyle.single);
      expect(theme.highlighted.textColor, isNull);
    });

    test('equality and hashCode', () {
      const a = HyperlinkTheme();
      const b = HyperlinkTheme();
      const c = HyperlinkTheme(
        idle: HyperlinkStyle(underline: UnderlineStyle.single),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });

    test('lerp with null returns other at boundary', () {
      const a = HyperlinkTheme();
      expect(HyperlinkTheme.lerp(a, null, 0.0), a);
      expect(HyperlinkTheme.lerp(a, null, 1.0), isNull);
      expect(HyperlinkTheme.lerp(null, a, 0.0), isNull);
      expect(HyperlinkTheme.lerp(null, a, 1.0), a);
    });
  });

  group('TerminalTheme', () {
    test('dark() produces valid dark theme', () {
      final theme = TerminalTheme.dark();
      expect((theme.foreground.a * 255.0).round(), 255);
      expect((theme.background.a * 255.0).round(), 255);
      for (var i = 0; i < 256; i++) {
        expect(() => theme.palette[i], returnsNormally, reason: 'index $i');
      }
    });

    test('light() produces valid light theme', () {
      final theme = TerminalTheme.light();
      expect((theme.foreground.a * 255.0).round(), 255);
      expect((theme.background.a * 255.0).round(), 255);
      for (var i = 0; i < 256; i++) {
        expect(() => theme.palette[i], returnsNormally, reason: 'index $i');
      }
    });

    test('dark and light have different foreground and background', () {
      final dark = TerminalTheme.dark();
      final light = TerminalTheme.light();
      expect(dark.foreground, isNot(equals(light.foreground)));
      expect(dark.background, isNot(equals(light.background)));
      expect(dark, isNot(equals(light)));
    });

    test('resolveColor maps CellColor to Flutter Color', () {
      final theme = TerminalTheme.dark();
      expect(
        theme.resolveColor(const DefaultColor(), isForeground: true),
        theme.foreground,
      );
      expect(
        theme.resolveColor(const DefaultColor(), isForeground: false),
        theme.background,
      );
      expect(
        theme.resolveColor(const RgbColor(255, 0, 0), isForeground: true),
        const Color(0xFFFF0000),
      );
    });

    test('equality and hashCode', () {
      final a = TerminalTheme.dark();
      final b = TerminalTheme.dark();
      final c = a.copyWith(foreground: const Color(0xFFFFFFFF));
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });

    test('copyWith changes specific fields', () {
      final original = TerminalTheme.dark();
      const newFg = Color(0xFFFFFFFF);
      final modified = original.copyWith(foreground: newFg);
      expect(modified.foreground, newFg);
      expect(modified.background, original.background);
      expect(modified.fontFamily, original.fontFamily);
    });

    test('copyWith regenerates palette when foreground changes', () {
      final original = TerminalTheme.dark();
      final modified = original.copyWith(foreground: const Color(0xFFFF0000));
      expect(modified.palette, isNot(equals(original.palette)));
    });

    test('copyWith regenerates palette when background changes', () {
      final original = TerminalTheme.dark();
      final modified = original.copyWith(background: const Color(0xFF000000));
      expect(modified.palette, isNot(equals(original.palette)));
    });

    test('copyWith reuses palette when only hyperlink changes', () {
      final original = TerminalTheme.dark();
      final modified = original.copyWith(
        hyperlink: const HyperlinkTheme(
          idle: HyperlinkStyle(underline: UnderlineStyle.single),
        ),
      );
      expect(modified.palette, equals(original.palette));
      expect(modified.hyperlink.idle.underline, UnderlineStyle.single);
    });

    test('copyWith reuses palette when only cursor changes', () {
      final original = TerminalTheme.dark();
      final modified = original.copyWith(
        cursor: const CursorTheme(shape: CursorShape.bar),
      );
      expect(modified.palette, equals(original.palette));
    });

    test('lerp at boundaries returns endpoints', () {
      final dark = TerminalTheme.dark();
      final light = TerminalTheme.light();
      expect(TerminalTheme.lerp(dark, light, 0.0), dark);
      expect(TerminalTheme.lerp(dark, light, 1.0), light);
    });

    test('lerp at midpoint produces intermediate colors', () {
      final dark = TerminalTheme.dark();
      final light = TerminalTheme.light();
      final mid = TerminalTheme.lerp(dark, light, 0.5)!;
      expect(mid.foreground, isNot(equals(dark.foreground)));
      expect(mid.foreground, isNot(equals(light.foreground)));
      expect(mid.background, isNot(equals(dark.background)));
      expect(mid.background, isNot(equals(light.background)));
    });

    test('lerp with null returns other at boundary', () {
      final theme = TerminalTheme.dark();
      expect(TerminalTheme.lerp(theme, null, 0.0), theme);
      expect(TerminalTheme.lerp(theme, null, 1.0), isNull);
      expect(TerminalTheme.lerp(null, theme, 0.0), isNull);
      expect(TerminalTheme.lerp(null, theme, 1.0), theme);
    });

    test('lerp snaps fontFamily at midpoint', () {
      final a = TerminalTheme.dark().copyWith(fontFamily: 'Menlo');
      final b = TerminalTheme.dark().copyWith(fontFamily: 'Consolas');
      expect(TerminalTheme.lerp(a, b, 0.49)!.fontFamily, 'Menlo');
      expect(TerminalTheme.lerp(a, b, 0.5)!.fontFamily, 'Consolas');
    });

    test('fontFamilyFallback defaults to a non-empty list', () {
      final theme = TerminalTheme.dark();
      expect(theme.fontFamilyFallback, isNotEmpty);
    });

    test('copyWith preserves fontFamilyFallback when not overridden', () {
      final original = TerminalTheme.dark();
      final modified = original.copyWith(fontFamily: 'Fira Code');
      expect(modified.fontFamilyFallback, original.fontFamilyFallback);
    });

    test('copyWith overrides fontFamilyFallback', () {
      final original = TerminalTheme.dark();
      const custom = ['Fira Code', 'Menlo'];
      final modified = original.copyWith(fontFamilyFallback: custom);
      expect(modified.fontFamilyFallback, custom);
    });

    test('fontFamilyFallback contributes to equality', () {
      final a = TerminalTheme.dark();
      final b = a.copyWith(fontFamilyFallback: ['Menlo']);
      expect(a, isNot(equals(b)));
    });

    test('lerp snaps fontFamilyFallback at midpoint', () {
      final a = TerminalTheme.dark().copyWith(fontFamilyFallback: ['Menlo']);
      final b = TerminalTheme.dark().copyWith(fontFamilyFallback: ['Consolas']);
      expect(TerminalTheme.lerp(a, b, 0.49)!.fontFamilyFallback, ['Menlo']);
      expect(TerminalTheme.lerp(a, b, 0.5)!.fontFamilyFallback, ['Consolas']);
    });
  });
}
