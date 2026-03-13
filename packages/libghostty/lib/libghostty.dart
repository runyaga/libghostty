/// Terminal emulation powered by libghostty.
///
/// ```dart
/// import 'package:libghostty/libghostty.dart';
/// ```
library;

export 'src/bindings/bindings.dart' show initializeForWeb;
export 'src/color.dart';
export 'src/enums/key.dart' show Key;
export 'src/enums/key_action.dart' show KeyAction;
export 'src/enums/kitty_key_flags.dart' show KittyKeyFlags;
export 'src/enums/mods.dart' show Mods;
export 'src/enums/option_as_alt.dart' show OptionAsAlt;
export 'src/enums/underline_style.dart' show UnderlineStyle;
export 'src/exceptions.dart';
export 'src/key_encoder.dart' show KeyEncoder;
export 'src/key_event.dart' show KeyEvent;
export 'src/paste.dart';
export 'src/terminal/cell.dart'
    show Cell, CellStyle, CellWidth, SemanticContent;
export 'src/terminal/cursor.dart' show Cursor, CursorShape;
export 'src/terminal/line.dart' show Line;
export 'src/terminal/modes.dart' show ScreenMode, TerminalModes;
export 'src/terminal/mouse.dart' show MouseShape, MouseTracking;
export 'src/terminal/screen.dart' show DirtyState, Screen;
export 'src/terminal/scrollback.dart' show Scrollback;
export 'src/terminal/terminal.dart' show Terminal;
export 'src/terminal/terminal_event.dart';
export 'src/terminal/terminal_options.dart' show TerminalOptions;
