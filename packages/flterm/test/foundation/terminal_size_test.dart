import 'package:flterm/src/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TerminalSize', () {
    test('equality and hashCode', () {
      const a = TerminalSize(cols: 80, rows: 24);
      const b = TerminalSize(cols: 80, rows: 24);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(const TerminalSize(cols: 81, rows: 24))));
      expect(a, isNot(equals(const TerminalSize(cols: 80, rows: 25))));
    });
  });
}
