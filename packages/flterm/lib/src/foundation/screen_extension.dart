import 'package:libghostty/libghostty.dart' show CellWidth, Screen;

final _isWord = RegExp(r'\w');

/// Utilities for querying terminal screen content.
extension ScreenExtension on Screen {
  /// Returns the bounds of the terminal line at [row].
  ///
  /// Walks up past wrapped predecessors and down past wrapped successors
  /// to find the full extent of a soft-wrapped line. On the final row,
  /// [endCol] is the exclusive column after the last content cell rather
  /// than [cols], so trailing empty cells are excluded.
  ({int startRow, int endRow, int endCol}) lineBoundaryAt(int row) {
    if (row < 0 || row >= rows) {
      return (startRow: row, endRow: row, endCol: 0);
    }
    var start = row;
    while (start > 0 && isRowWrapped(start - 1)) {
      start--;
    }
    var end = row;
    while (end < rows - 1 && isRowWrapped(end)) {
      end++;
    }
    var endCol = cols;
    while (endCol > 0) {
      final cell = cellAt(end, endCol - 1);
      if (cell.content.isNotEmpty || cell.wide == CellWidth.spacerTail) break;
      endCol--;
    }
    return (startRow: start, endRow: end, endCol: endCol);
  }

  /// Snaps [col] to a wide character boundary on [row].
  ///
  /// When [inclusive] is true (for the leading edge of a selection), snaps
  /// to the wide character's start column. When false (for the trailing
  /// exclusive edge), snaps past the wide character's end.
  ///
  /// Returns [col] unchanged for narrow cells or out-of-bounds coordinates.
  int snapColToWideBoundary(int row, int col, {required bool inclusive}) {
    if (row < 0 || row >= rows || col < 0 || col >= cols) return col;
    final cell = cellAt(row, col);
    if (cell.isWide) return inclusive ? col : col + 2;
    if (cell.wide == CellWidth.spacerTail) {
      return inclusive ? col - 1 : col + 1;
    }
    return col;
  }

  /// Snaps both columns of a selection range to wide character boundaries.
  ///
  /// Determines which column is inclusive (leading edge) vs exclusive
  /// (trailing edge) based on row/column ordering, then snaps each
  /// using [snapColToWideBoundary].
  (int startCol, int endCol) snapSelectionCols(
    int startRow,
    int startCol,
    int endRow,
    int endCol,
  ) {
    final startIsTop = startRow != endRow
        ? startRow < endRow
        : startCol <= endCol;

    if (startIsTop) {
      return (
        snapColToWideBoundary(startRow, startCol, inclusive: true),
        snapColToWideBoundary(endRow, endCol, inclusive: false),
      );
    }
    return (
      snapColToWideBoundary(startRow, startCol, inclusive: false),
      snapColToWideBoundary(endRow, endCol, inclusive: true),
    );
  }

  /// Returns the column range `(start, end)` of the word at ([row], [col]).
  ///
  /// The range is inclusive at [start] and exclusive at [end]. If the cell
  /// is not a word character, returns a single-cell range.
  ///
  /// ```dart
  /// // Screen contains "hello world" on row 0
  /// final (start, end) = screen.wordBoundaryAt(0, 2);
  /// // start == 0, end == 5
  /// ```
  (int start, int end) wordBoundaryAt(int row, int col) {
    if (row < 0 || row >= rows) return (col, col + 1);

    final maxCol = cols;
    if (col < 0 || col >= maxCol) return (col, col + 1);

    final snapped = cellAt(row, col).wide == .spacerTail && col > 0
        ? col - 1
        : col;

    final charAtPos = cellAt(row, snapped).content;
    if (charAtPos.isEmpty || !_isWord.hasMatch(charAtPos)) {
      final span = cellAt(row, snapped).isWide ? 2 : 1;
      return (snapped, snapped + span);
    }

    var start = snapped;
    while (start > 0) {
      final cell = cellAt(row, start - 1);
      if (cell.wide == .spacerTail) {
        start--;
        continue;
      }
      if (cell.content.isEmpty || !_isWord.hasMatch(cell.content)) break;
      start--;
    }

    var end = snapped + 1;
    while (end < maxCol) {
      final cell = cellAt(row, end);
      if (cell.wide == .spacerTail) {
        end++;
        continue;
      }
      if (cell.content.isEmpty || !_isWord.hasMatch(cell.content)) break;
      end++;
    }

    return (start, end);
  }
}
