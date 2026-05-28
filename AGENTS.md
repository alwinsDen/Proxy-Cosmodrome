# Proxy-Cosmodrome

macOS app that launches and manages various applications from the user's local system. Built with SwiftUI + Rust backend.

## Build

### Rust (must build first):
```bash
cargo build --target aarch64-apple-darwin
```
For release: `cargo build --target aarch64-apple-darwin --release`

### Swift / Xcode:
Open `Proxy-Cosmodrome.xcodeproj` in Xcode and build, or:
```bash
xcodebuild build -project Proxy-Cosmodrome.xcodeproj -scheme Proxy-Cosmodrome -destination 'platform=macOS'
```

Always build Rust first before building/running the Xcode project.

Xcode project requires **Default Actor Isolation → `nonisolated`** (Build Settings → Swift Compiler). Without this, builds fail with actor isolation errors.

## Bridge

Swift-Rust bridging is handled by `swift-bridge`. The bridging code lives in `src/lib.rs` (Rust FFI module) and `generated/` (auto-generated Swift/C headers, produced by `build.rs`). After editing Rust FFI, rebuild Rust to regenerate bridging code.

`bridging-header.h` at project root imports the generated headers and connects them to Swift. If it's missing or misconfigured, nothing compiles.

## Tests

### Unit tests (Swift Testing):
```bash
xcodebuild test -project Proxy-Cosmodrome.xcodeproj -scheme Proxy-Cosmodrome -destination 'platform=macOS'
```

### UI tests (XCTest):
```bash
xcodebuild test -project Proxy-Cosmodrome.xcodeproj -scheme Proxy-Cosmodrome -destination 'platform=macOS' -testPlan Proxy-CosmodromeUITests
```

### Rust tests:
```bash
cargo test
```

Note: Unit tests use Swift Testing (`@Test`, `#expect`). UI tests use XCTest (`XCTestCase`, `XCTAssert`).

## Code style

- **Swift:** 4-space indent, PascalCase for types, camelCase for properties/functions, `@State` marked `private`, trailing commas in collections
- **Rust:** standard Rust 2024 edition idioms, snake_case, 4-space indent

## Architecture

- `Proxy-Cosmodrome/` — SwiftUI app layer (views, components)
- `Proxy-Cosmodrome/InteractiveComponents/` — reusable SwiftUI components (ProjectRunners, ConfigEditorView, CodeEditorView)
- `src/` — Rust backend logic (FFI bridge, file I/O, config management)
- `generated/` — auto-generated bridge bindings (do not edit directly)

**Rust does all OS operations** (file I/O, process execution, networking). **Swift handles UI only** — it calls Rust via FFI for any system interaction.

## Config persistence

User configuration is stored at `~/.proxy-cosmodrome/default-configs.json`. All file I/O is handled by Rust via FFI.

- **Rust (`src/lib.rs`):** `load_config()` creates the file on first launch with `{"base_config_location": "..."}`; `save_config(json)` writes content; `get_config_dir()` returns the directory path
- **Swift (`ContentView.swift`):** calls `load_config()` on appear to populate the editor
- **Swift (`ConfigEditorView.swift`):** calls `save_config()` after JSON validation on Save

## Dependencies

- Rust: `swift-bridge` 0.1, `serde` 1, `serde_json` 1, `dirs` 5
- Swift (SPM): `FontAwesomeSwiftUI`

## Important

Whenever there is an architecture change in the codebase (new modules, restructuring, file moves, changes to the bridge or build system), update this AGENTS.md file to reflect the current state.

Whenever AGENTS.md is updated, ensure README.md is also updated with the latest features and developer documentation.

## CI

GitHub Actions workflow at `.github/workflows/swift.yml` — builds Rust + Xcode on push/PR to `main`. Only builds; does not run tests.

CI builds Rust with `--release` (local dev uses debug). The `target/aarch64-apple-darwin/release` directory does not exist locally unless you also run a release build.
