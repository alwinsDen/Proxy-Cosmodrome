#  Proxy Cosmodrome

Mac runner tool.

| Requirement | Version |
|-------------|---------|
| Xcode | 26.4.1 |
| MacOS | 26.4.1 |
| rustc | 1.94 |

## setup & build
1. Before opening the project with Xcode
```shell
# currently aarch64-apple-darwin has been hardcoded xcode proj.
cargo build --target aarch64-apple-darwin
```
or trigger an inital Xcode build itself [will compile rust & swift].

## integration steps
If recreating the process to configure rustc-swift, below is the SOP
1. Definite archiecture as arm64, Build Settings -> Architectures -> Release -> arm64
2. Define Build Settings -> Library Search Paths -> 
    * DEBUG -> `$(PROJECT_DIR)/target/aarch64-apple-darwin/debug`
    * RELEASE -> `$(PROJECT_DIR)/target/aarch64-apple-darwin/release`
3. Build Settings -> Other Linker Flags -> -lProxy_CosmodromeRustCore.
    * Here `Proxy_CosmodromeRustCore` is derived from name of `.a` in target/aarch64-apple-darwin/debug/
4. Swift Compiler - General -> Briding headers -> $(SRCROOT)/bridging-header.h (set for both Debug & Release)
5. Error fix for ```Nonisolated deinitializer 'deinit' has different actor isolation from main actor-isolated overridden declaration```
   * Swift Compiler -> Concurrency -> Default Actor Isolation -> nonisolated
