import 'package:flterm/src/foundation.dart';
import 'package:flterm/src/rendering.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libghostty/libghostty.dart';

void main() {
  late StyleResolver resolver;

  setUp(() {
    resolver = StyleResolver(TerminalTheme.dark());
  });

  group('resolveColors', () {
    test('default cell uses theme foreground and background', () {
      final theme = TerminalTheme.dark();
      final (fg, bg) = resolver.resolveColors(Cell.empty);
      expect(fg, theme.foreground);
      expect(bg, theme.background);
    });

    test('explicit RGB colors are resolved directly', () {
      const cell = Cell(
        foreground: RgbColor(255, 0, 0),
        background: RgbColor(0, 0, 255),
      );
      final (fg, bg) = resolver.resolveColors(cell);
      expect(fg, const Color(0xFFFF0000));
      expect(bg, const Color(0xFF0000FF));
    });

    test('inverse swaps foreground and background', () {
      final theme = TerminalTheme.dark();
      const cell = Cell(style: CellStyle(inverse: true));
      final (fg, bg) = resolver.resolveColors(cell);
      expect(fg, theme.background);
      expect(bg, theme.foreground);
    });

    test('faint halves foreground alpha', () {
      const cell = Cell(style: CellStyle(faint: true));
      final (fg, _) = resolver.resolveColors(cell);
      final expected = TerminalTheme.dark().foreground.a * 0.5;
      expect(fg.a, closeTo(expected, 0.001));
    });

    test('inverse + faint applies both transformations', () {
      final theme = TerminalTheme.dark();
      const cell = Cell(style: CellStyle(inverse: true, faint: true));
      final (fg, bg) = resolver.resolveColors(cell);
      expect(bg, theme.foreground);
      expect(fg.a, closeTo(theme.background.a * 0.5, 0.001));
    });
  });

  group('resolveStyle', () {
    test('same key reuses cached instance', () {
      final (fg, _) = resolver.resolveColors(Cell.empty);
      final a = resolver.resolveStyle(Cell.empty, fg);
      final b = resolver.resolveStyle(Cell.empty, fg);
      expect(identical(a, b), isTrue);
    });

    test('different attributes produce different instances', () {
      final (fg, _) = resolver.resolveColors(Cell.empty);
      const boldCell = Cell(content: 'A', style: CellStyle(bold: true));
      final plain = resolver.resolveStyle(Cell.empty, fg);
      final bold = resolver.resolveStyle(boldCell, fg);
      expect(identical(plain, bold), isFalse);
    });

    test('resolves to same instance as buildStyle with matching key', () {
      final (fg, _) = resolver.resolveColors(Cell.empty);
      final fromResolve = resolver.resolveStyle(Cell.empty, fg);
      final fromBuild = resolver.buildStyle(
        CellStyleKey(
          bold: false,
          italic: false,
          faint: false,
          strikethrough: false,
          overline: false,
          foreground: fg,
          underline: UnderlineStyle.none,
        ),
      );
      expect(identical(fromResolve, fromBuild), isTrue);
    });

    test('cell with underline color includes it in the key', () {
      const cell = Cell(
        content: 'A',
        style: CellStyle(underline: UnderlineStyle.single),
        underlineColor: RgbColor(255, 0, 0),
      );
      final (fg, _) = resolver.resolveColors(cell);
      final withColor = resolver.resolveStyle(cell, fg);

      const cellNoColor = Cell(
        content: 'A',
        style: CellStyle(underline: UnderlineStyle.single),
      );
      final withoutColor = resolver.resolveStyle(cellNoColor, fg);

      expect(identical(withColor, withoutColor), isFalse);
    });
  });

  group('baseStyle', () {
    test('same color reuses cached instance', () {
      const color = Color(0xFFFF0000);
      expect(
        identical(resolver.baseStyle(color), resolver.baseStyle(color)),
        isTrue,
      );
    });

    test('different colors produce different instances', () {
      const red = Color(0xFFFF0000);
      const blue = Color(0xFF0000FF);
      expect(
        identical(resolver.baseStyle(red), resolver.baseStyle(blue)),
        isFalse,
      );
    });
  });

  group('wideGlyphStyle', () {
    test('same color and fontSize reuses cached instance', () {
      const color = Color(0xFFFF0000);
      final a = resolver.wideGlyphStyle(color, 14.0);
      final b = resolver.wideGlyphStyle(color, 14.0);
      expect(identical(a, b), isTrue);
    });

    test('different colors produce different instances', () {
      const red = Color(0xFFFF0000);
      const blue = Color(0xFF0000FF);
      expect(
        identical(
          resolver.wideGlyphStyle(red, 14.0),
          resolver.wideGlyphStyle(blue, 14.0),
        ),
        isFalse,
      );
    });

    test('fontSize change invalidates cache', () {
      const color = Color(0xFFFF0000);
      final at14 = resolver.wideGlyphStyle(color, 14.0);
      resolver.wideGlyphStyle(color, 18.0);
      final at14Again = resolver.wideGlyphStyle(color, 14.0);
      expect(identical(at14, at14Again), isFalse);
    });
  });

  group('clearStyleCaches', () {
    test('forces new instances for all cache types', () {
      final (fg, _) = resolver.resolveColors(Cell.empty);
      final base = resolver.baseStyle(fg);
      final style = resolver.resolveStyle(Cell.empty, fg);
      final wide = resolver.wideGlyphStyle(fg, 14.0);

      resolver.clearStyleCaches();

      expect(identical(resolver.baseStyle(fg), base), isFalse);
      expect(identical(resolver.resolveStyle(Cell.empty, fg), style), isFalse);
      expect(identical(resolver.wideGlyphStyle(fg, 14.0), wide), isFalse);
    });
  });

  group('cache eviction', () {
    test('evicts oldest entries when cache exceeds maxCacheSize', () {
      resolver.maxCacheSize = 4;
      final first = resolver.baseStyle(const Color(0xFF000001));

      for (var i = 2; i <= 6; i++) {
        resolver.baseStyle(Color(0xFF000000 + i));
      }

      final firstAgain = resolver.baseStyle(const Color(0xFF000001));
      expect(identical(first, firstAgain), isFalse);
    });

    test('recently added entries survive eviction', () {
      resolver.maxCacheSize = 4;

      for (var i = 1; i <= 4; i++) {
        resolver.baseStyle(Color(0xFF000000 + i));
      }

      final fourth = resolver.baseStyle(const Color(0xFF000004));
      resolver.baseStyle(const Color(0xFF000005));
      final fourthAgain = resolver.baseStyle(const Color(0xFF000004));

      expect(identical(fourth, fourthAgain), isTrue);
    });
  });
}
