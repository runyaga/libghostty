// Uses --dart-define (REPRO_LINES) to tune the repro; that is the intended
// configuration mechanism here.
// ignore_for_file: do_not_use_environment
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flterm/flterm.dart';
import 'package:flutter/material.dart';

/// Reproduces the **skwasm WASM-heap crash** seen with `flutter build web
/// --wasm`: an uncaught WebAssembly trap from `skwasm.wasm`
/// (`memory access out of bounds`), which *freezes the canvas* while JS keeps
/// running.
///
/// Recipe (confirmed live, Chrome, devicePixelRatio 2):
///   1. Stream a large scrollback (~100k lines) of **wide** lines (long glyph
///      runs ⇒ a big per-row text atlas).
///   2. While streaming, churn the viewport with big top⇄bottom scroll jumps.
///      Each jump re-rasterizes a different scrollback region into skwasm's
///      WASM linear heap.
///
/// Renderer matrix:
///   * `flutter build web --wasm`  → **skwasm**  → FAILS: canvas seizes,
///     console shows a WebAssembly trap / `memory access out of bounds`.
///   * `flutter build web`         → **skia / CanvasKit** → PASSES: keeps
///     rendering and the churn counter keeps advancing.
///
/// The app paint is renderer-agnostic and viewport-bounded (see
/// `test/rendering/atlas_sizing_test.dart`), so this is an engine-level skwasm
/// bug, not a flterm/app leak.
///
/// Launch via `--dart-define=SKWASM_REPRO=true` (see `main.dart`).
class SkwasmReproPage extends StatefulWidget {
  const SkwasmReproPage({super.key});

  @override
  State<SkwasmReproPage> createState() => _SkwasmReproPageState();
}

class _SkwasmReproPageState extends State<SkwasmReproPage> {
  // 50 MB scrollback so all ~100k wide lines are retained (default is 10 MB).
  late final _controller = TerminalController(
    config: const TerminalConfig(scrollbackLimit: 50_000_000),
  );
  final _scroll = TerminalScrollController();

  static const _line =
      'Paragraph: the good-enough mother adapts to her infant; the '
      'transitional object lives in the intermediate area of experiencing -- '
      'Winnicott 1951, the repository of creative living';

  // Total wide lines to stream, and how many per tick.
  static const _target =
      int.fromEnvironment('REPRO_LINES', defaultValue: 100000);
  static const _chunk = 400;

  var _written = 0;
  var _churns = 0;
  var _running = false;
  Timer? _timer;

  void _write(String s) =>
      _controller.write(Uint8List.fromList(utf8.encode(s)));

  // One tick: stream a chunk of wide lines, then make a big scroll swing
  // (top on even ticks, bottom on odd). Streaming + scroll-jump repaint churn
  // is what exhausts skwasm's WASM heap.
  void _tick() {
    if (_written < _target) {
      final end = (_written + _chunk).clamp(0, _target);
      final b = StringBuffer();
      for (var i = _written; i < end; i++) {
        b.write(_line);
        b.write('\r\n');
      }
      _write(b.toString());
      _written = end;
    }
    try {
      if (_churns.isEven) {
        _controller.scrollToTop();
      } else {
        _controller.scrollToBottom();
      }
    } on Object catch (_) {
      // Scroll may be a no-op before the view attaches; ignore.
    }
    setState(() => _churns++);
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(milliseconds: 80), (_) => _tick());
  }

  @override
  void initState() {
    super.initState();
    // Print a banner immediately so the terminal is non-empty even before the
    // stream starts, then auto-run the repro once the view has attached.
    _write('skwasm WASM-heap repro -- streaming $_target wide lines + '
        'scroll churn\r\n');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(seconds: 1), () {
        if (mounted && !_running) _toggle();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ExcludeFocus(
            child: TerminalView(
              controller: _controller,
              scrollController: _scroll,
              theme: TerminalTheme.dark(),
              showKeyboard: false,
            ),
          ),
        ),
        // Liveness HUD. When skwasm faults the canvas freezes, so this counter
        // visibly stops advancing even though the timer keeps firing — that is
        // the repro signal (alongside the console WebAssembly trap). Under
        // CanvasKit it keeps counting.
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: Colors.black54,
            child: Text(
              'skwasm-repro · streamed=$_written/$_target · '
              'churns=$_churns · ${_running ? "RUNNING" : "idle"}',
              style: const TextStyle(
                color: Colors.greenAccent,
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
          ),
        ),
        Positioned(
          left: 8,
          bottom: 8,
          // Wrapped in Material: a bare FloatingActionButton in a Stack has
          // no Material ancestor (Scaffold only supplies one for its FAB slot).
          child: Material(
            color: Colors.transparent,
            child: FloatingActionButton.extended(
              onPressed: _toggle,
              backgroundColor: Colors.black54,
              foregroundColor: Colors.white,
              icon: Icon(_running ? Icons.stop : Icons.play_arrow),
              label: Text(_running ? 'Stop churn' : 'Start churn'),
            ),
          ),
        ),
      ],
    );
  }
}
