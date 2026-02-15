// Copyright 2026 John Salerno.

import SwiftUI
import Testing
@testable import ButterflyButton

/// Verifies that the default public initializer can be constructed.
@MainActor
@Test func publicInitializerBuildsWithDefaults() {
    var value = true
    let binding = Binding(get: { value }, set: { value = $0 })
    _ = ButterflyButton(isOn: binding)
}

/// Verifies that the labeled initializer can be constructed.
@MainActor
@Test func labeledInitializerBuilds() {
    var value = false
    let binding = Binding(get: { value }, set: { value = $0 })
    _ = ButterflyButton(isOn: binding) {
        Text("Butterfly")
    }
}
