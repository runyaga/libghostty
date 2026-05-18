@Tags(['ffi'])
library;

import 'dart:typed_data';

import 'package:libghostty/libghostty.dart';
import 'package:test/test.dart';

void main() {
  group('LibGhostty', () {
    late Terminal terminal;

    setUp(() => terminal = Terminal(cols: 80, rows: 24));

    tearDown(() {
      terminal.dispose();
      LibGhostty.clearLogger();
    });

    group('setLogger', () {
      test('receives decoded log emissions', () {
        final captured = <_LogEntry>[];
        LibGhostty.setLogger((level, scope, message) {
          captured.add((level: level, scope: scope, message: message));
        });

        terminal.write(_logTrigger);

        expect(captured, isNotEmpty);
        expect(captured.single.level, SysLogLevel.warning);
        expect(captured.single.scope, 'stream');
        expect(captured.single.message, contains('invalid C0 character'));
      });

      test('replaces previous logger', () {
        final first = <String>[];
        final second = <String>[];
        LibGhostty.setLogger((_, _, msg) => first.add(msg));
        LibGhostty.setLogger((_, _, msg) => second.add(msg));

        terminal.write(_logTrigger);

        expect(first, isEmpty);
        expect(second, isNotEmpty);
      });
    });

    group('clearLogger', () {
      test('stops delivering messages', () {
        final captured = <String>[];
        LibGhostty.setLogger((_, _, msg) => captured.add(msg));
        LibGhostty.clearLogger();

        terminal.write(_logTrigger);

        expect(captured, isEmpty);
      });

      test('can be called without installed logger', () {
        expect(LibGhostty.clearLogger, returnsNormally);
      });
    });

    group('useStderrLogger', () {
      test('accepts emissions', () {
        LibGhostty.useStderrLogger();
        expect(() => terminal.write(_logTrigger), returnsNormally);
      });

      test('replaces previous logger', () {
        final captured = <String>[];
        LibGhostty.setLogger((_, _, msg) => captured.add(msg));
        LibGhostty.useStderrLogger();

        terminal.write(_logTrigger);

        expect(captured, isEmpty);
      });
    });
  });
}

final _logTrigger = Uint8List.fromList([0x03]);

typedef _LogEntry = ({SysLogLevel level, String scope, String message});
