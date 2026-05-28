# Proxy Cosmodrome

A macOS desktop app that helps you launch and manage applications installed on your local system. Think of it as a mission control for your Mac's apps.

Built with SwiftUI on the frontend and Rust powering the backend logic, connected through `swift-bridge`.

<img width="1045" height="666" alt="image" src="https://github.com/user-attachments/assets/9ef55b2b-dd70-41f2-b85f-ad3d956a49b9" />

## Getting started
| Requirement | Version |
|-------------|---------|
| Xcode | 26.4.1 |
| macOS | 26.4.1 |
| rustc | 1.94 |

```bash
# 1. Build the Rust backend first
cargo build --target aarch64-apple-darwin

# 2. Open the Xcode project and build/run
open Proxy-Cosmodrome.xcodeproj
```

Or from the command line:

```bash
cargo build --target aarch64-apple-darwin
xcodebuild build -project Proxy-Cosmodrome.xcodeproj -scheme Proxy-Cosmodrome -destination 'platform=macOS'
```

## Running tests

```bash
# Swift unit tests
xcodebuild test -project Proxy-Cosmodrome.xcodeproj -scheme Proxy-Cosmodrome -destination 'platform=macOS'

# Rust tests
cargo test
```

## Tech stack

- **SwiftUI** — native macOS UI
- **Rust** — backend logic compiled as a static library
- **swift-bridge** — generates Swift bindings for Rust functions automatically
- **FontAwesomeSwiftUI** — icon library via Swift Package Manager

## Project structure

| Directory | Contents |
|-----------|----------|
| `Proxy-Cosmodrome/` | SwiftUI views and components |
| `src/` | Rust source (FFI bridge in `lib.rs`) |
| `generated/` | Auto-generated Swift/C bridge code — do not edit |
| `.github/workflows/` | CI configuration (builds on push to `main`) |

## Xcode setup (one-time)

If you need to configure the Swift-Rust bridge from scratch:

1. Set **Architectures → Release** to `arm64`
2. Add **Library Search Paths** for the Rust build output (`target/aarch64-apple-darwin/debug` for Debug, `release` for Release)
3. Add **Other Linker Flags** → `-lProxy_CosmodromeRustCore`
4. Set **Bridging Header** → `$(SRCROOT)/bridging-header.h`
5. Fix actor isolation error by setting **Default Actor Isolation** → `nonisolated`
