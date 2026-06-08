# Repro: skwasm WASM-heap crash (`memory access out of bounds`)

## Summary

When flterm is built for the web with the **WasmGC / skwasm renderer**
(`flutter build web --wasm`), rendering a large scrollback of **wide** lines and
then **scrolling through it** eventually crashes the renderer with:

```
Uncaught RuntimeError: memory access out of bounds        (at skwasm.wasm:0x…)
```

(sometimes also `Uncaught RuntimeError: operation does not support unaligned
accesses`). The **canvas freezes** — it stops repainting and input does nothing
— while the surrounding JS keeps running. To a user the terminal "seizes up."

The same app built with the default **skia / CanvasKit (dart2js)** renderer
(`flutter build web`) does **not** crash under the identical workload.

| Renderer | Build | Result |
| --- | --- | --- |
| **skwasm** (WasmGC) | `flutter build web --wasm` | ❌ **FAILS** — `memory access out of bounds`, canvas freezes |
| **skia / CanvasKit** (dart2js) | `flutter build web` | ✅ **PASSES** — keeps rendering under the same churn |

## Root cause (where it lives)

It is an **engine-level bug in Flutter's skwasm renderer**, not in flterm or the
embedding app:

- flterm's paint is **bounded by the visible viewport**, independent of
  scrollback depth — `SpriteBuffer` is sized to `rows × cols` and
  `TerminalFrameBuilder` caps the row loop at the visible rows. A worst-case
  300×200 viewport submits **< 3 MiB** to `drawRawAtlas`. See
  [`test/rendering/atlas_sizing_test.dart`](test/rendering/atlas_sizing_test.dart).
- The app code, widget tree, and `drawRawAtlas`/`Picture` calls are **identical**
  across renderers; only skwasm crashes. The fault is in skwasm's WASM linear
  heap (atlas/surface/`Picture` allocations accumulating or fragmenting faster
  than they are reclaimed during scroll-driven re-rasterization).

## The recipe

Confirmed live in Chrome at **`devicePixelRatio: 2`** (retina). DPR 2 is an
accelerant: ~4× the surface bytes per frame vs DPR 1, which is why headless
DPR-1 runs never reproduced it.

1. Fill a large scrollback (~100k lines) with **wide** lines. Wide glyph runs
   make each row's text atlas large — width matters more than line count.
2. Churn the viewport: large **top ⇄ bottom scroll jumps** while more output
   streams. Each jump re-rasterizes a different scrollback region.

It trips cheaply once primed — often within a handful of scroll repaints.

## Run it

The example app embeds a one-click repro page (`SkwasmReproPage`): it streams
~100k wide lines while auto-churning the viewport (top⇄bottom scroll jumps).
Launch it with `--dart-define=SKWASM_REPRO=true`.

> **skwasm needs cross-origin isolation.** A `--wasm` build uses
> SharedArrayBuffer, so it must be served with COOP/COEP headers
> (`Cross-Origin-Opener-Policy: same-origin`,
> `Cross-Origin-Embedder-Policy: require-corp`) or it won't start.
> `flutter run` sets these automatically; a static server must add them. The
> CanvasKit build does **not** need them (and COEP will block the CDN-hosted
> `canvaskit.wasm` — serve CanvasKit from a plain server, or build with
> `--no-web-resources-cdn`).

```bash
cd packages/flterm/example

# FAILS — skwasm. Console shows `RuntimeError: memory access out of bounds`
# within seconds and the on-screen `churns=` counter freezes.
flutter run -d chrome --wasm --dart-define=SKWASM_REPRO=true
#   …or build + serve with COOP/COEP:
flutter build web --wasm --release --dart-define=SKWASM_REPRO=true

# PASSES — skia / CanvasKit. Same workload, no crash; the counter keeps ticking
# (observed 1200+ churns after streaming all 100k lines).
flutter run -d chrome --dart-define=SKWASM_REPRO=true
#   …or build + serve from a plain server:
flutter build web --release --dart-define=SKWASM_REPRO=true
```

Tunables (via `--dart-define`):

- `REPRO_LINES` — wide lines to stream (default `100000`).

The HUD counter (top-right) is the liveness signal: under skwasm it freezes when
the renderer faults even though the churn timer keeps firing; under CanvasKit it
keeps advancing.

### Confirmed

- **skwasm** (`flutter build web --wasm`, served with COOP/COEP), Chrome at
  `devicePixelRatio: 2` — **including headless** — faults with
  `RuntimeError: memory access out of bounds` within seconds of the churn.
- **CanvasKit** (`flutter build web`), same workload — renders all 100k lines
  and keeps churning (`churns` well past 1000) with no fault.

> **Note on the bundled wasm.** `example/assets/libghostty-wasm32-freestanding.wasm`
> must match the resolved `libghostty` Dart package (here `0.0.9`); a mismatched
> build fails `initializeForWeb` with a dart:ffi `_Struct` runtime type-check
> error before the terminal ever renders. This example bundles the
> 0.0.9-compatible build.

## Environment where this was confirmed

- Flutter **3.41.6** (stable), Dart 3.x — nix toolchain.
- Chrome, macOS, retina display (`devicePixelRatio: 2`).

## Mitigation

Until the upstream skwasm bug is fixed, build the web app with the **dart2js /
CanvasKit** renderer (drop `--wasm`). The downstream embedder (klangk) does this
in `scripts/flutterbuildweb.sh`.
