<!-- Copyright 2026 John Salerno. -->

# ButterflyButton

`ButterflyButton` is a SwiftUI-first, production-focused control package for macOS, iOS, and iPadOS.

## Requirements
- Xcode 26.2+
- Swift 6.2+
- iOS 26+
- macOS 26+

## Installation
Add the package in Xcode via **File -> Add Packages...** and point to your repository URL.

## Known Issues

**SwiftLint warnings not visible in Xcode Issue Navigator** — A regression introduced in Xcode 16.3 ([realm/SwiftLint#6041](https://github.com/realm/SwiftLint/issues/6041)) prevents SPM Build Tool Plugin diagnostics from appearing in the Issue Navigator. The plugin runs and detects violations, but Xcode silently discards the output. Warnings are still visible in the Report Navigator build log. As a workaround, run SwiftLint from the command line:

```bash
swift package --allow-writing-to-package-directory swiftlint lint
```

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

