# Proxy-Cosmodrome

macOS app (SwiftUI + Rust backend via `swift-bridge`) that manages and runs user-defined application projects.

## Build

Rust first, then Xcode:

```bash
cargo build --target aarch64-apple-darwin
# release: cargo build --target aarch64-apple-darwin --release
xcodebuild build -project Proxy-Cosmodrome.xcodeproj -scheme Proxy-Cosmodrome -destination 'platform=macOS'
```

After editing Rust FFI in `src/lib.rs`, rebuild Rust to regenerate bridge code into `generated/` (via `build.rs`). `bridging-header.h` at project root imports the generated headers.

## Tests

```bash
# unit tests (Swift Testing)
xcodebuild test -project Proxy-Cosmodrome.xcodeproj -scheme Proxy-Cosmodrome -destination 'platform=macOS'
# UI tests (XCTest) — separate test plan
xcodebuild test -project Proxy-Cosmodrome.xcodeproj -scheme Proxy-Cosmodrome -destination 'platform=macOS' -testPlan Proxy-CosmodromeUITests
# Rust
cargo test
```

CI (`.github/workflows/swift.yml`) only builds — no tests.

## Sandbox & Security

**App Sandbox and Hardened Runtime are both disabled** in all build configs. Child process file access (via `sh`/`zsh`) depends on this. If either is re-enabled, runners will get "Operation not permitted" errors.

## Architecture

- `Proxy-Cosmodrome/` — SwiftUI views. **Swift handles UI only.**
- `src/lib.rs` — Rust backend (file I/O, process execution, config). **Rust does all OS operations.**
- `generated/` — auto-generated Swift/C bridge bindings (do not edit directly).
- `Proxy-Cosmodrome/InteractiveComponents/` — reusable components (ProjectRunners, ConfigEditorView, CodeEditorView, CreateNewProjectView, EditProjectView).
- Config persisted at `~/.proxy-cosmodrome/default-configs.json` (JSON with `"projects"` array). All I/O via Rust FFI.

## Runner Execution

Rust's `run_command` spawns the user's login shell (`$SHELL` / `zsh`) with `zsh -l -c` so PATH includes Homebrew etc. It wipes inherited env vars (`env_clear()`) and preserves only `HOME`. This prevents Xcode-injected vars (e.g. `MTL_DEBUG_LAYER`) from leaking into child processes.

Secrets are injected in **Swift**, not Rust — filtered by `runnerName` (empty = all runners), logged as `🔑 Injected secret: KEY`, then prepended as `KEY='shell-escaped-value'` env prefix on the command. Uses `String.shellEscaped` extension (single-quote wrapping with `'\''` for embedded quotes).

**Never pass secrets to Rust** — they'd appear in the command string unescaped.

## Terminal Panel

Bottom panel with tabbed multi-runner output (each runner click = new tab). Tabs are closable. Height is draggable via a thin resize handle (clamped 80–500pt).

## Key conventions

- `@State` marked `private`
- trailing commas in collections
- `ForEach(Array(projects.enumerated()), id: \.element.id)` pattern for indexed lists
- Rust: 2024 edition, snake_case, 4-space indent
- Swift: 4-space indent, PascalCase types, camelCase props/fns

## Dependencies

- Rust: `swift-bridge` 0.1, `serde` 1, `serde_json` 1, `dirs` 5
- Swift SPM: `FontAwesomeSwiftUI`
