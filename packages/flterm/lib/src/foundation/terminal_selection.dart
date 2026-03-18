import 'dart:math' as math;

import 'package:meta/meta.dart';

/// A selected range of terminal cells.
///
/// Normalized bounds are available via [topRow], [topCol], [bottomRow],
/// [bottomCol] regardless of selection direction.
///
/// ```dart
/// const selection = TerminalSelection(
///   startRow: 0,
///   startCol: 5,
///   endRow: 2,
///   endCol: 10,
/// );
/// if (selection.contains(1, 7)) print('Cell is selected');
/// ```
@immutable
final class TerminalSelection {
  final int startRow;
  final int startCol;
  final int endRow;
  final int endCol;
  final TerminalSelectionMode mode;

  const TerminalSelection({
    required this.startRow,
    required this.startCol,
    required this.endRow,
    required this.endCol,
    this.mode = .normal,
  });

  /// Normalized bottom column (exclusive).
  ///
  /// In block mode, the larger of [startCol] and [endCol].
  /// In normal mode, the column of whichever endpoint is lower in the grid.
  int get bottomCol {
    if (mode == .block) return math.max(startCol, endCol);
    if (startRow < endRow) return endCol;
    if (startRow > endRow) return startCol;
    return math.max(startCol, endCol);
  }

  /// Normalized bottom row (inclusive). The larger of [startRow] and [endRow].
  int get bottomRow => startRow <= endRow ? endRow : startRow;

  @override
  int get hashCode => Object.hash(startRow, startCol, endRow, endCol, mode);

  /// Normalized top column (inclusive).
  ///
  /// In block mode, the smaller of [startCol] and [endCol].
  /// In normal mode, the column of whichever endpoint is higher in the grid.
  int get topCol {
    if (mode == .block) return math.min(startCol, endCol);
    if (startRow < endRow) return startCol;
    if (startRow > endRow) return endCol;
    return math.min(startCol, endCol);
  }

  /// Normalized top row (inclusive). The smaller of [startRow] and [endRow].
  int get topRow => startRow <= endRow ? startRow : endRow;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TerminalSelection &&
          startRow == other.startRow &&
          startCol == other.startCol &&
          endRow == other.endRow &&
          endCol == other.endCol &&
          mode == other.mode;

  /// Returns true if the cell at ([row], [col]) falls within this selection.
  bool contains(int row, int col) {
    if (row < topRow || row > bottomRow) return false;
    if (mode == .block) return col >= topCol && col < bottomCol;
    if (topRow == bottomRow) return col >= topCol && col < bottomCol;
    if (row == topRow) return col >= topCol;
    if (row == bottomRow) return col < bottomCol;
    return true;
  }

  /// Returns a new selection with the end point shifted by [dRow] rows
  /// and [dCol] columns.
  ///
  /// In normal mode, horizontal movement wraps across rows.
  /// In block mode, columns clamp without wrapping.
  /// The result is clamped within [totalCols] columns and [totalRows] rows.
  TerminalSelection moveEnd(
    int dRow,
    int dCol, {
    required int totalCols,
    required int totalRows,
  }) {
    var newRow = endRow + dRow;
    var newCol = endCol + dCol;

    if (mode == .block) {
      return TerminalSelection(
        startRow: startRow,
        startCol: startCol,
        endRow: newRow.clamp(0, totalRows - 1),
        endCol: newCol.clamp(0, totalCols),
        mode: mode,
      );
    }

    if (dRow == 0) {
      if (newCol > totalCols) {
        newRow++;
        newCol = 0;
      } else if (newCol < 0) {
        newRow--;
        newCol = totalCols;
      }
      if (newRow < 0) {
        newRow = 0;
        newCol = 0;
      } else if (newRow >= totalRows) {
        newRow = totalRows - 1;
        newCol = totalCols;
      }
    } else {
      newRow = newRow.clamp(0, totalRows - 1);
    }

    return TerminalSelection(
      startRow: startRow,
      startCol: startCol,
      endRow: newRow,
      endCol: newCol,
      mode: mode,
    );
  }

  /// Returns a new selection with both rows shifted by [delta].
  TerminalSelection scroll(int delta) {
    if (delta == 0) return this;
    return TerminalSelection(
      startRow: startRow + delta,
      startCol: startCol,
      endRow: endRow + delta,
      endCol: endCol,
      mode: mode,
    );
  }
}

/// How a selection region is shaped.
enum TerminalSelectionMode {
  /// Contiguous text across lines, the standard terminal selection mode.
  normal,

  /// Rectangular column range across rows (Alt+drag in most terminals).
  block,
}
