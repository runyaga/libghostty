import 'package:flterm/src/rendering/measure_cell_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('measureCellMetrics', () {
    testWidgets('returns valid dimensions', (tester) async {
      final metrics = measureCellMetrics(
        fontFamily: 'monospace',
        fontSize: 14.0,
      );
      expect(metrics.cellWidth, greaterThan(0));
      expect(metrics.cellHeight, greaterThan(0));
      expect(metrics.baseline, greaterThan(0));
      expect(metrics.baseline, lessThanOrEqualTo(metrics.cellHeight));
    });

    testWidgets('larger font produces larger dimensions', (tester) async {
      final small = measureCellMetrics(fontFamily: 'monospace', fontSize: 10);
      final large = measureCellMetrics(fontFamily: 'monospace', fontSize: 24);
      expect(large.cellWidth, greaterThan(small.cellWidth));
      expect(large.cellHeight, greaterThan(small.cellHeight));
    });

    testWidgets('accepts fontFamilyFallback', (tester) async {
      final metrics = measureCellMetrics(
        fontFamily: 'monospace',
        fontSize: 14.0,
        fontFamilyFallback: const ['serif'],
      );
      expect(metrics.cellWidth, greaterThan(0));
      expect(metrics.cellHeight, greaterThan(0));
    });
  });
}
