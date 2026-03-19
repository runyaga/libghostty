import 'package:libghostty/libghostty.dart';

/// Returns the visible text for [cell], or a space if the cell is empty,
/// invisible, or blink-hidden.
String cellText(Cell cell, {required bool blinkVisible}) {
  if (cell.content.isEmpty) return ' ';
  if (cell.style.invisible) return ' ';
  if (cell.style.blink && !blinkVisible) return ' ';
  return cell.content;
}
