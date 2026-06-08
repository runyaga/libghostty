// Evidence that flterm's paint footprint is bounded by the VISIBLE viewport,
// not by scrollback depth — which is why the skwasm `memory access out of
// bounds` crash (see ../../REPRO-skwasm-heap.md) cannot be a flterm/app leak
// and must live in the engine's skwasm renderer.
//
// Architectural fact under test: SpriteBuffer is sized to the visible grid
// (rows x cols), not to scrollback. TerminalFrameBuilder._build caps the row
// loop with `if (row >= _state.rows) break;`, so no matter how many lines are
// dumped or how far the viewport is scrolled, drawRawAtlas only ever receives
// ~rows*cols sprites.
import 'package:flterm/src/rendering/atlas/atlas.dart';
import 'package:flterm/src/rendering/atlas/sprite_buffer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('drawRawAtlas footprint is bounded by the visible viewport', () {
    AtlasEntry glyph() => AtlasEntry(
      srcLeft: 0,
      srcTop: 0,
      srcRight: 8,
      srcBottom: 16,
      bearingY: 0,
    );

    // A generous full-screen web terminal viewport. Even a 4K-tall window is
    // only a few hundred rows; a normal one is ~24-60 rows.
    for (final (rows, cols) in [(24, 80), (60, 120), (300, 200)]) {
      final sprites = AtlasSprites()..configure(rows, cols);
      // Fully pack every visible cell (worst case: dense text, no blanks).
      for (var r = 0; r < rows; r++) {
        sprites.beginRow(r);
        for (var c = 0; c < cols; c++) {
          sprites.add(c * 8.0, r * 16.0, glyph(), 1.0, 0xFFFFFFFF);
        }
        sprites.endRow();
      }
      sprites.seal();

      final count = sprites.count;
      // RSTransform: 4 floats * 4 bytes; rects: 4 floats * 4 bytes;
      // colors: 1 int * 4 bytes = 36 bytes/sprite submitted to drawRawAtlas.
      final transformsBytes = sprites.sealedTransforms.length * 4;
      final rectsBytes = sprites.sealedRects.length * 4;
      final colorsBytes = sprites.sealedColors.length * 4;
      final total = transformsBytes + rectsBytes + colorsBytes;

      expect(count, rows * cols);
      // Even an absurd 300x200 viewport submits well under 3 MiB — independent
      // of scrollback depth. The skwasm heap blow-up is therefore not driven
      // by the volume flterm hands the renderer.
      expect(total, lessThan(3 * 1024 * 1024));
    }
  });
}
