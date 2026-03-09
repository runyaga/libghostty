# Changelog

## 0.0.2

### Added

- **Sealed `TerminalEvent` hierarchy** — typed events (`BellReceived`,
  `TitleChanged`, `CursorChanged`, `MouseShapeChanged`, `ResponseReceived`,
  `ScreenChanged`, `ModeChanged`) replace ad-hoc state polling.
- **`TerminalOptions`** — configure foreground/background color and scrollback
  limit at terminal creation.
- **Mouse support** — `MouseShape` and `MouseTracking` exposed via the
  terminal API.
- **`DirtyState` enum** — `clean`/`partial`/`full` for render-level dirty
  tracking on `Screen`.
- **Reusable viewport buffer** — `Screen` reuses a single buffer across reads,
  reducing per-frame allocations.
- **Row wrapping detection** — `Screen` and `Scrollback` report whether a row
  is soft-wrapped.
- **Scrollback grapheme support** — `Scrollback` returns full grapheme
  clusters.
- **`CellWidth` and `SemanticContent`** — new cell metadata types.
- **256-color palette** — CIELAB interpolation and full 256-color palette
  generation with base16 theme support.

### Changed

- **`TerminalViewport` removed** — viewport reading now lives on `Screen`
  directly.
- Bumped upstream ghostty to `055ed285`.

## [0.0.1] - 2026-02-25

### Added

- **Terminal emulation**: Full VT parser and screen buffer
    - Screen, Line, Cell API for inspecting terminal content
    - Cursor control and styling
    - Terminal modes tracking
    - Scrollback buffer support
- **Key encoding**: Kitty keyboard protocol implementation
    - KeyEvent, KeyAction, Mods for key handling
    - KeyEncoder for encoding key events to bytes
- **SGR parsing**: Parse Select Graphic Rendition escape sequences
- **OSC parsing**: Parse Operating System Commands (window title, hyperlinks)
- **Paste validation**: Security-focused paste validation to prevent injection attacks
- **WASM support**: WebAssembly build for browser environments

### Supported Platforms

- Android, iOS, macOS, Linux, Windows, Web

## 0.0.1-dev.3

- Fix release artifact filenames and download URLs

## 0.0.1-dev.2

- Add release automation with build and release workflows
- Add download_asset_hashes.dart script for preparing releases

## 0.0.1-dev.1

- Initial pre-release
