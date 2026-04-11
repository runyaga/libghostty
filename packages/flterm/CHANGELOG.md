# Changelog

## 0.0.1

Initial release.

### Added

- **`TerminalView`**: a Flutter widget that renders a terminal and
  adapts its input to the host. Mouse and keyboard on desktop, touch
  and soft keyboard on mobile, both on web.
- **`TerminalController`**: owns the terminal and bridges it with the
  view. Connects to a backend (PTY, SSH, socket) via `onOutput`,
  `onResize`, `onBell`, and `onTitleChanged`. Exposes I/O (`write`,
  `sendText`, `sendKey`), selection (`selectAll`, `selectWord`,
  `selectLine`), focus, scrolling, paste, clear, and mode toggling.
- **Themes**: ANSI 16, 256-color, and truecolor palettes; cursor
  shape, color, and blink; hyperlink style; font family, size, and
  fallback; minimum contrast. Immutable and `lerp`-able.
- **Wide characters**: CJK, color emoji, VS16, and combining marks
  render correctly; selection snaps to whole cells.
- **Mouse selection**: drag, double-click word, triple-click line,
  and Alt+drag block. Configurable via `TerminalGestureSettings`.
- **Shortcuts**: built-in copy, paste, select all, and clear with
  platform-aware defaults (Cmd on macOS/iOS, Ctrl+Shift on
  Linux/Windows). Extend or replace with any Flutter `Intent`.
- **OSC 8 hyperlinks**: idle and highlighted styles with click
  hit-testing.
- **Cross-platform**: Android, iOS, Linux, macOS, Web (WASM), Windows.
