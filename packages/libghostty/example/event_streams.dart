// ignore_for_file: avoid_print

import 'dart:typed_data';

import 'package:libghostty/libghostty.dart';

void main() {
  final terminal = Terminal(cols: 80, rows: 24);

  terminal.onEvent.listen((event) {
    switch (event) {
      case BellReceived():
        print('Bell!');
      case TitleChanged(:final title):
        print('Title: $title');
      case CursorChanged(:final cursor):
        print('Cursor: ${cursor.col}, ${cursor.row}');
      case MouseShapeChanged(:final shape):
        print('Mouse shape: $shape');
      case ModeChanged(:final modes):
        print('Mode changed: $modes');
      case ScreenChanged():
        print('Screen changed');
      case ResponseReceived(:final response):
        print('Response available: $response');
    }
  });

  terminal.write(.fromList('\x1b]0;Tab Name\x07'.codeUnits));
  terminal.write(.fromList('Hello\x07'.codeUnits));

  print('Bracketed paste: ${terminal.modes.bracketedPaste}');
  terminal.write(Uint8List.fromList('\x1b[?2004h'.codeUnits));
  print('Bracketed paste: ${terminal.modes.bracketedPaste}');

  terminal.dispose();
}
