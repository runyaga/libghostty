import 'package:meta/meta.dart';

import 'mouse.dart' show MouseTracking;

/// Which screen buffer the terminal is using.
enum ScreenMode {
  /// Normal screen with scrollback history.
  primary,

  /// Separate buffer for full-screen apps like vim (DECSET 1049).
  alternate,
}

/// Terminal mode flags set by DECSET/DECRST and SM/RM sequences.
@immutable
class TerminalModes {
  /// Marks pasted text so apps can tell it apart from keystrokes (DECSET 2004).
  final bool bracketedPaste;

  /// Which screen buffer is active (DECSET 1049).
  final ScreenMode screenMode;

  /// Arrow keys emit app-mode sequences instead of ANSI cursors (DECSET 1).
  final bool cursorKeyApplication;

  /// Numpad emits app-mode sequences instead of digits (DECSET 66).
  final bool keypadApplication;

  /// Text wraps at the right margin; when off, overwrites the last
  /// column (DECSET 7).
  final bool autoWrap;

  /// Cursor addressing is relative to the scroll region (DECSET 6).
  final bool originMode;

  /// Characters insert and shift text right instead of overwriting (SM 4).
  final bool insertMode;

  /// Which mouse events the terminal reports to the application.
  final MouseTracking mouseTracking;

  /// Scroll wheel sends cursor keys on the alternate screen (DECSET 1007).
  final bool mouseAlternateScroll;

  const TerminalModes({
    this.bracketedPaste = false,
    this.screenMode = .primary,
    this.cursorKeyApplication = false,
    this.keypadApplication = false,
    this.autoWrap = true,
    this.originMode = false,
    this.insertMode = false,
    this.mouseTracking = MouseTracking.none,
    this.mouseAlternateScroll = true,
  });

  @override
  int get hashCode => Object.hash(
    bracketedPaste,
    screenMode,
    cursorKeyApplication,
    keypadApplication,
    autoWrap,
    originMode,
    insertMode,
    mouseTracking,
    mouseAlternateScroll,
  );

  @override
  bool operator ==(Object other) =>
      other is TerminalModes &&
      other.bracketedPaste == bracketedPaste &&
      other.screenMode == screenMode &&
      other.cursorKeyApplication == cursorKeyApplication &&
      other.keypadApplication == keypadApplication &&
      other.autoWrap == autoWrap &&
      other.originMode == originMode &&
      other.insertMode == insertMode &&
      other.mouseTracking == mouseTracking &&
      other.mouseAlternateScroll == mouseAlternateScroll;

  TerminalModes copyWith({
    bool? bracketedPaste,
    ScreenMode? screenMode,
    bool? cursorKeyApplication,
    bool? keypadApplication,
    bool? autoWrap,
    bool? originMode,
    bool? insertMode,
    MouseTracking? mouseTracking,
    bool? mouseAlternateScroll,
  }) {
    return TerminalModes(
      bracketedPaste: bracketedPaste ?? this.bracketedPaste,
      screenMode: screenMode ?? this.screenMode,
      cursorKeyApplication: cursorKeyApplication ?? this.cursorKeyApplication,
      keypadApplication: keypadApplication ?? this.keypadApplication,
      autoWrap: autoWrap ?? this.autoWrap,
      originMode: originMode ?? this.originMode,
      insertMode: insertMode ?? this.insertMode,
      mouseTracking: mouseTracking ?? this.mouseTracking,
      mouseAlternateScroll: mouseAlternateScroll ?? this.mouseAlternateScroll,
    );
  }

  @override
  String toString() {
    final flags = <String>[];
    if (bracketedPaste) flags.add('bracketedPaste');
    if (screenMode != .primary) flags.add('screenMode:${screenMode.name}');
    if (cursorKeyApplication) flags.add('cursorKeyApplication');
    if (keypadApplication) flags.add('keypadApplication');
    if (autoWrap) flags.add('autoWrap');
    if (originMode) flags.add('originMode');
    if (insertMode) flags.add('insertMode');
    if (mouseTracking != .none) {
      flags.add('mouseTracking:${mouseTracking.name}');
    }
    if (mouseAlternateScroll) flags.add('mouseAlternateScroll');
    return 'TerminalModes(${flags.join(', ')})';
  }
}
