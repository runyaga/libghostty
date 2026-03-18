/// Controls when the mouse cursor hides during terminal interaction.
enum MouseAutoHide {
  /// Keeps the system cursor visible at all times.
  never,

  /// Hides the cursor after a keystroke and restores it on mouse movement.
  onInput,
}

/// Whether the terminal accepts keyboard input.
///
/// ```dart
/// TerminalView(
///   terminal: terminal,
///   inputMode: TerminalInputMode.readOnly,
/// )
/// ```
enum TerminalInputMode {
  /// Accepts keyboard and IME input (default).
  interactive,

  /// Displays terminal output but ignores keyboard input.
  readOnly,
}
