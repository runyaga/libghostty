import 'dart:ui';

import 'package:meta/meta.dart';

/// Pixel dimensions of a single terminal cell.
///
/// ```dart
/// const metrics = CellMetrics(
///   cellWidth: 8.4,
///   cellHeight: 17.0,
///   baseline: 13.0,
/// );
/// final (cols, rows) = metrics.gridSize(width, height);
/// ```
@immutable
final class CellMetrics {
  /// Width of one character cell in logical pixels.
  final double cellWidth;

  /// Height of one character cell in logical pixels.
  final double cellHeight;

  /// Distance from the top of the cell to the alphabetic baseline.
  final double baseline;

  const CellMetrics({
    required this.cellWidth,
    required this.cellHeight,
    required this.baseline,
  }) : assert(cellWidth >= 0, 'cellWidth must be non-negative'),
       assert(cellHeight >= 0, 'cellHeight must be non-negative'),
       assert(baseline >= 0, 'baseline must be non-negative');

  @override
  int get hashCode => Object.hash(cellWidth, cellHeight, baseline);

  @override
  bool operator ==(Object other) =>
      other is CellMetrics &&
      other.cellWidth == cellWidth &&
      other.cellHeight == cellHeight &&
      other.baseline == baseline;

  /// Converts a pixel [position] to terminal cell coordinates.
  (int row, int col) cellAt(Offset position) {
    final row = cellHeight > 0 ? (position.dy / cellHeight).floor() : 0;
    final col = cellWidth > 0 ? (position.dx / cellWidth).floor() : 0;
    return (row, col);
  }

  /// Returns the pixel rect for a horizontal range of cells on [row].
  Rect cellRangeRect(int row, int startCol, int endCol, Offset offset) {
    return Rect.fromLTWH(
      offset.dx + startCol * cellWidth,
      offset.dy + row * cellHeight,
      (endCol - startCol) * cellWidth,
      cellHeight,
    );
  }

  /// Returns the pixel rect for a single cell at ([row], [col]).
  Rect cellRect(int row, int col, Offset offset) {
    return cellRangeRect(row, col, col + 1, offset);
  }

  /// Computes how many columns and rows fit in the given pixel dimensions.
  (int cols, int rows) gridSize(double width, double height) {
    final cols = cellWidth > 0 ? (width / cellWidth).floor() : 0;
    final rows = cellHeight > 0 ? (height / cellHeight).floor() : 0;
    return (cols, rows);
  }

  @override
  String toString() =>
      'CellMetrics(cellWidth: $cellWidth, '
      'cellHeight: $cellHeight, baseline: $baseline)';
}
