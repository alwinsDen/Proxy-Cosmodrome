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

## Bridge

Swift-Rust bridging is handled by `swift-bridge`. The bridging code lives in `src/lib.rs` (Rust FFI module) and `generated/` (auto-generated Swift/C headers, produced by `build.rs`). After editing Rust FFI, rebuild Rust to regenerate bridging code.

## Tests

### Unit tests (Swift Testing):
```bash
xcodebuild test -project Proxy-Cosmodrome.xcodeproj -scheme Proxy-Cosmodrome -destination 'platform=macOS'
```

### Rust tests:
```bash
cargo test
```

## Code style

- **Swift:** 4-space indent, PascalCase for types, camelCase for properties/functions, `@State` marked `private`, trailing commas in collections
- **Rust:** standard Rust 2024 edition idioms, snake_case, 4-space indent

## Architecture

- `Proxy-Cosmodrome/` — SwiftUI app layer (views, components)
- `Proxy-Cosmodrome/InteractiveComponents/` — reusable SwiftUI components
- `src/` — Rust backend logic (FFI bridge)
- `generated/` — auto-generated bridge bindings (do not edit directly)

## Dependencies

- Rust: `swift-bridge` 0.1
- Swift (SPM): `FontAwesomeSwiftUI`

## Important

Whenever there is an architecture change in the codebase (new modules, restructuring, file moves, changes to the bridge or build system), update this AGENTS.md file to reflect the current state.

Whenever AGENTS.md is updated, ensure README.md is also updated with the latest features and developer documentation.

## CI

GitHub Actions workflow at `.github/workflows/swift.yml` — builds Rust + Xcode on push/PR to `main`. Only builds; does not run tests.
