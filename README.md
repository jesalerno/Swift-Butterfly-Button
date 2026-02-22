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

