#!/bin/bash
set -e

cargo build --target x86_64-apple-darwin
swiftc -L target/x86_64-apple-darwin/debug/ -lswift_and_rust -import-objc-header bridging-header.h \
  main.swift lib.swift ./generated/swift-and-rust/swift-and-rust.swift ./generated/SwiftBridgeCore.swift