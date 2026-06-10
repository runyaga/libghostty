import 'package:libghostty/libghostty.dart';

/// Callback for terminal grid resize events.
///
/// Fires when the [TerminalView] layout changes and produces a different
/// number of character [cols] and [rows]. Set on [TerminalController.onResize]
/// to forward size changes to the backend (PTY, SSH, etc.).
///
/// ```dart
/// controller.onResize = (cols, rows) => pty.resize(cols, rows);
/// ```
typedef OnResize = void Function(int cols, int rows);

/// Mouse event data from the gesture detector to the controller.
///
/// Carries the raw pixel coordinates and the semantic action/button so
/// the controller can encode mouse reports for the terminal. Pixel
/// coordinates are relative to the terminal grid origin (after padding).
///
/// ```dart
/// final event = (
///   action: MouseAction.press,
///   button: MouseButton.left,
///   pixelX: offset.dx,
///   pixelY: offset.dy,
/// );
/// controller.handleMouseEvent(event);
/// ```
typedef TerminalMouseEvent = ({
  MouseAction action,
  MouseButton button,
  double pixelX,
  double pixelY,
});

/// Data for a modifier-click (⌘ on macOS / Ctrl elsewhere) over a path/URL
/// token or an OSC 8 hyperlink. Fired on [TerminalController.onLinkTap].
///
/// [token] is the path/URL-shaped text under the clicked cell (empty when the
/// cell isn't link-shaped); [uri] is the OSC 8 hyperlink URI when the cell
/// carries one (else null); [tail] is the row's text from the token start to
/// end-of-row, letting the host greedy-extend across spaces in filenames.
/// [row]/[col] are the clicked viewport cell. The host resolves/opens these.
typedef LinkTap = ({int row, int col, String token, String? uri, String tail});
