import 'package:flutter/painting.dart'
    show TextDirection, TextPainter, TextSpan, TextStyle;

import '../foundation.dart' show CellMetrics;

/// Measures cell dimensions by laying out a reference character ('M') with
/// the given font configuration.
CellMetrics measureCellMetrics({
  required String fontFamily,
  required double fontSize,
  List<String>? fontFamilyFallback,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: 'M',
      style: TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        fontSize: fontSize,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  final metrics = CellMetrics(
    cellWidth: painter.width,
    cellHeight: painter.height,
    baseline: painter.computeDistanceToActualBaseline(.alphabetic),
  );

  painter.dispose();

  return metrics;
}
