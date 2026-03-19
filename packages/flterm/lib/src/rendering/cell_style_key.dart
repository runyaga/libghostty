import 'package:flutter/painting.dart';
import 'package:libghostty/libghostty.dart';
import 'package:meta/meta.dart';

/// Cache key mapping a unique combination of visual cell attributes to one
/// [TextStyle] object shared across all rows.
///
/// [blink] and [invisible] are excluded: they suppress content (cell renders
/// as a space) rather than changing the TextStyle.
///
/// [inverse] is excluded: it is resolved into [foreground] before the key
/// is constructed, so the key captures post-inverse colors.
@immutable
final class CellStyleKey {
  final bool bold;
  final bool italic;
  final bool faint;
  final bool strikethrough;
  final bool overline;

  /// Resolved foreground color after applying inverse and faint.
  final Color foreground;

  final UnderlineStyle underline;

  /// Resolved underline color. Null when no explicit underline color is set.
  final Color? underlineColor;

  const CellStyleKey({
    required this.bold,
    required this.italic,
    required this.faint,
    required this.strikethrough,
    required this.overline,
    required this.foreground,
    required this.underline,
    this.underlineColor,
  });

  @override
  int get hashCode => Object.hash(
    bold,
    italic,
    faint,
    strikethrough,
    overline,
    foreground,
    underline,
    underlineColor,
  );

  @override
  bool operator ==(Object other) =>
      other is CellStyleKey &&
      other.bold == bold &&
      other.italic == italic &&
      other.faint == faint &&
      other.strikethrough == strikethrough &&
      other.overline == overline &&
      other.foreground == foreground &&
      other.underline == underline &&
      other.underlineColor == underlineColor;

  TextStyle buildTextStyle(
    String fontFamily,
    double fontSize,
    List<String> fontFamilyFallback,
  ) {
    final decorations = <TextDecoration>[];
    TextDecorationStyle? decorationStyle;

    if (underline != UnderlineStyle.none) {
      decorations.add(TextDecoration.underline);
      decorationStyle = switch (underline) {
        UnderlineStyle.single => TextDecorationStyle.solid,
        UnderlineStyle.doubleLine => TextDecorationStyle.double,
        UnderlineStyle.curly => TextDecorationStyle.wavy,
        UnderlineStyle.dotted => TextDecorationStyle.dotted,
        UnderlineStyle.dashed => TextDecorationStyle.dashed,
        UnderlineStyle.none => null,
      };
    }
    if (strikethrough) decorations.add(TextDecoration.lineThrough);
    if (overline) decorations.add(TextDecoration.overline);

    return TextStyle(
      color: foreground,
      fontSize: fontSize,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      decoration: decorations.isEmpty ? .none : .combine(decorations),
      decorationStyle: decorationStyle,
      decorationColor: underlineColor,
    );
  }
}
