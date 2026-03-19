import 'dart:ui';

import 'package:libghostty/libghostty.dart';

import '../foundation.dart';
import 'cell_style_key.dart';

typedef ResolvedColors = (Color foreground, Color background);

/// Resolves terminal cell attributes into Flutter [TextStyle] objects.
///
/// Caches resolved styles keyed by color or [CellStyleKey]. Eviction uses
/// insertion-order (FIFO via [LinkedHashMap]) rather than LRU to avoid
/// per-lookup overhead: LRU requires a remove+reinsert on every cache hit,
/// which is too costly when called per-cell during row rebuilds. FIFO is
/// sufficient because terminal style diversity is typically low.
class StyleResolver {
  final TerminalTheme theme;
  final ParagraphStyle paragraphStyle;
  final Map<Color, TextStyle> _baseStyleCache = {};
  final Map<CellStyleKey, TextStyle> _styleCache = {};
  final Map<Color, TextStyle> _wideGlyphStyleCache = {};
  double _wideGlyphFontSize = 0;
  var maxCacheSize = 4096;

  StyleResolver(this.theme)
    : paragraphStyle = ParagraphStyle(
        fontFamily: theme.fontFamily,
        fontSize: theme.fontSize,
      );

  TextStyle baseStyle(Color foreground) {
    _evictIfNeeded(_baseStyleCache);
    return _baseStyleCache.putIfAbsent(
      foreground,
      () => _buildBaseUiStyle(foreground, theme.fontSize),
    );
  }

  TextStyle buildStyle(CellStyleKey key) {
    return _styleCache.putIfAbsent(
      key,
      () => key
          .buildTextStyle(
            theme.fontFamily,
            theme.fontSize,
            theme.fontFamilyFallback,
          )
          .getTextStyle(),
    );
  }

  void clearStyleCaches() {
    _baseStyleCache.clear();
    _wideGlyphStyleCache.clear();
    _styleCache.clear();
  }

  ResolvedColors resolveColors(Cell cell) {
    var foreground = theme.resolveColor(cell.foreground, isForeground: true);
    var background = theme.resolveColor(cell.background, isForeground: false);
    if (cell.style.inverse) (foreground, background) = (background, foreground);

    if (cell.style.faint) {
      foreground = foreground.withValues(alpha: foreground.a * 0.5);
    }
    return (foreground, background);
  }

  TextStyle resolveStyle(Cell cell, Color foreground) {
    _evictIfNeeded(_styleCache);
    final key = CellStyleKey(
      bold: cell.style.bold,
      foreground: foreground,
      faint: cell.style.faint,
      italic: cell.style.italic,
      overline: cell.style.overline,
      underline: cell.style.underline,
      strikethrough: cell.style.strikethrough,
      underlineColor: switch (cell.underlineColor) {
        final CellColor value => theme.resolveColor(value, isForeground: true),
        null => null,
      },
    );

    return _styleCache.putIfAbsent(
      key,
      () => key
          .buildTextStyle(
            theme.fontFamily,
            theme.fontSize,
            theme.fontFamilyFallback,
          )
          .getTextStyle(),
    );
  }

  TextStyle wideGlyphStyle(Color foreground, double fontSize) {
    if (fontSize != _wideGlyphFontSize) {
      _wideGlyphStyleCache.clear();
      _wideGlyphFontSize = fontSize;
    }
    return _wideGlyphStyleCache.putIfAbsent(
      foreground,
      () => _buildBaseUiStyle(foreground, fontSize),
    );
  }

  TextStyle _buildBaseUiStyle(Color foreground, double fontSize) {
    return TextStyle(
      color: foreground,
      decoration: TextDecoration.none,
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.normal,
      fontSize: fontSize,
      fontFamily: theme.fontFamily,
      fontFamilyFallback: theme.fontFamilyFallback,
    );
  }

  void _evictIfNeeded(Map<Object, Object> cache) {
    if (cache.length <= maxCacheSize) return;
    // We evict down to 3/4 of max size to avoid thrashing around the limit when
    // the cache is being heavily used.
    final targetSize = maxCacheSize * 3 ~/ 4;
    while (cache.length > targetSize) {
      cache.remove(cache.keys.first);
    }
  }
}
