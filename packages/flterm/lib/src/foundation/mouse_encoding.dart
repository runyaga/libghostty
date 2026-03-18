import 'dart:convert';
import 'dart:typed_data';

import 'package:libghostty/libghostty.dart' show MouseTracking;
import 'package:meta/meta.dart';

/// Encodes a mouse event as an SGR escape sequence.
///
/// Returns null when the [mode] does not report the given [type].
@internal
Uint8List? encodeMouseEvent(
  MouseEventType type,
  MouseTracking mode,
  MouseButton button,
  int col,
  int row, {
  bool shift = false,
  bool alt = false,
  bool ctrl = false,
}) {
  final modifiers = _modifierBits(shift: shift, alt: alt, ctrl: ctrl);
  switch (type) {
    case .press:
      if (mode == .none) return null;
      return _encode(button.code | modifiers, col, row, 'M');
    case .release:
      if (mode == .none || mode == .x10) return null;
      return _encode(button.code | modifiers, col, row, 'm');
    case .motion:
      switch (mode) {
        case .none || .x10 || .normal:
          return null;
        case .button || .any:
          return _encode((button.code + 32) | modifiers, col, row, 'M');
      }
  }
}

Uint8List _encode(int code, int col, int row, String suffix) {
  return utf8.encode('\x1b[<$code;${col + 1};${row + 1}$suffix');
}

int _modifierBits({
  required bool shift,
  required bool alt,
  required bool ctrl,
}) {
  var bits = 0;
  if (shift) bits |= 4;
  if (alt) bits |= 8;
  if (ctrl) bits |= 16;
  return bits;
}

/// Mouse button codes for SGR encoding.
@internal
enum MouseButton {
  left(0),
  scrollUp(64),
  scrollDown(65);

  final int code;

  const MouseButton(this.code);
}

/// Mouse event lifecycle phases.
@internal
enum MouseEventType { press, release, motion }
