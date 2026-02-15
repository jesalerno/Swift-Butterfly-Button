<!-- Copyright 2026 John Salerno. -->

# ButterflyButton

`ButterflyButton` is a SwiftUI-first, production-focused control package for macOS, iOS, and iPadOS.

## Requirements
- Xcode 15.4+
- Swift 5.10+
- iOS 17+
- macOS 14+

## Installation
Add the package in Xcode via **File -> Add Packages...** and point to your repository URL.

## Quick Start
```swift
import SwiftUI
import ButterflyButton

struct ContentView: View {
    @State private var isOn = false

    var body: some View {
        ButterflyButton(
            isOn: $isOn,
            sideLength: 60,
            style: ButterflyButtonStyle(axleOrientation: .horizontal),
            spinDecelerationDuration: 2.0,
            spinSpeed: 1.0,
            onSpinCompleted: { newValue in
                print("isOn changed:", newValue)
            }
        ) {
            Text("Butterfly")
        }
    }
}
```

## API Notes
- `ButterflyButton` is `@MainActor`.
- Input interrupt policy is deterministic: a new interaction interrupts an in-flight spin.
- Event order:
  1. `onSpinBegan`
  2. animation starts
  3. `isOn` updates on completion
  4. `onSpinCompleted(newValue)`

## Accessibility and Localization
- Exposes toggle semantics and localized state value.
- Includes localized defaults:
  - `ButterflyButton.true`
  - `ButterflyButton.false`
- Supports Dynamic Type, increased contrast, and reduced motion behavior.

## Testing
```bash
swift test
```

## Lint
```bash
./scripts/lint.sh
```

This lint gate compiles with warnings treated as errors.

## macOS Visual Demo App
Run the sample app target that is designed for visual control testing on macOS 26.x runtime/devices in Xcode:

```bash
swift run ButterflyButtonMacDemo
```

Xcode run flow:
- Open `/Users/johnsalerno/Documents/DevWorkspace/AI Coding/buttery-fly-button-codex/Package.swift` in Xcode.
- Select scheme `ButterflyButtonMacDemo`.
- Choose a macOS 26.x runtime/device destination.
- Run to open the interactive test surface (size/orientation/animation/event log controls).

## iOS Visual Demo App
Run the sample iOS app target for visual control testing on iOS 26.x (for example iPhone 17 Pro simulator/device):

```bash
swift run ButterflyButtoniOSDemo
```

Xcode run flow:
- Open `/Users/johnsalerno/Documents/DevWorkspace/AI Coding/buttery-fly-button-codex/Package.swift` in Xcode.
- Select scheme `ButterflyButtoniOSDemo`.
- Choose an iOS 26.x destination (e.g. iPhone 17 Pro).
- Run to open the mobile interactive test surface (single control + grid tabs).

## Vulnerability Scan
```bash
./scripts/vulnerability_scan.sh
```

The scanner creates a report at `reports/vulnerability_report.json` and fails on High/Critical findings for direct dependencies.

## Platform Compatibility
See `/Users/johnsalerno/Documents/DevWorkspace/AI Coding/buttery-fly-button-codex/docs/compatibility.md`.
