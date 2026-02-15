// Copyright 2026 John Salerno.

import Testing
@testable import ButterflyButton

/// Ensures newer spin tokens invalidate older in-flight completions.
@Test func interruptPolicyInvalidatesOlderToken() {
    var coordinator = ButterflyInteractionCoordinator()
    coordinator.initialize(isOn: true)

    let first = coordinator.beginSpin()
    let second = coordinator.beginSpin()

    #expect(coordinator.isCurrentSpinToken(first) == false)
    #expect(coordinator.isCurrentSpinToken(second) == true)
}

/// Ensures enabled external changes produce an animation action.
@Test func externalChangeAnimatesWhenEnabled() {
    var coordinator = ButterflyInteractionCoordinator()
    coordinator.initialize(isOn: false)

    let action = coordinator.actionForExternalStateChange(newValue: true, isEnabled: true)
    #expect(action == .animate(sign: -1.0))
}

/// Ensures disabled external changes do not animate.
@Test func externalChangeDoesNotAnimateWhenDisabled() {
    var coordinator = ButterflyInteractionCoordinator()
    coordinator.initialize(isOn: false)

    let action = coordinator.actionForExternalStateChange(newValue: true, isEnabled: false)
    #expect(action == .none)
}

/// Ensures an internal toggle suppresses the next external animation.
@Test func internalToggleSuppressesNextExternalAnimation() {
    var coordinator = ButterflyInteractionCoordinator()
    coordinator.initialize(isOn: false)
    coordinator.markInternalToggle()

    let action = coordinator.actionForExternalStateChange(newValue: true, isEnabled: true)
    #expect(action == .none)
}
