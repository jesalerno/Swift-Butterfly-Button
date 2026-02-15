#!/usr/bin/env bash
# Copyright 2026 John Salerno.
set -euo pipefail

# Basic lint gate without SwiftLint: treat compiler warnings as errors.
# This enforces code hygiene in environments where swiftlint/swift-format are unavailable.

echo "[lint] swift build (warnings as errors)"
swift build -Xswiftc -warnings-as-errors

echo "[lint] swift build --build-tests (warnings as errors)"
swift build --build-tests -Xswiftc -warnings-as-errors

echo "[lint] PASS"
