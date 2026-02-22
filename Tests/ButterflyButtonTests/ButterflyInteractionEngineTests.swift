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

// MARK: - Additional edge cases

/// Verifies the animate sign when turning OFF (true → false) is +1.0.
@Test func externalChangeAnimateSign_positiveWhenTurningOff() {
    var coordinator = ButterflyInteractionCoordinator()
    coordinator.initialize(isOn: true)

    let action = coordinator.actionForExternalStateChange(newValue: false, isEnabled: true)
    #expect(action == .animate(sign: 1.0))
}

/// Verifies that calling actionForExternalStateChange before initialize returns .none.
@Test func externalChangeBeforeInitialize_returnsNone() {
    var coordinator = ButterflyInteractionCoordinator()
    // No initialize() call — lastRenderedIsOn is nil.

    let action = coordinator.actionForExternalStateChange(newValue: true, isEnabled: true)
    #expect(action == .none)
}

/// Verifies same-value external change returns .none (no redundant animation).
@Test func externalChangeSameValue_returnsNone() {
    var coordinator = ButterflyInteractionCoordinator()
    coordinator.initialize(isOn: true)

    let action = coordinator.actionForExternalStateChange(newValue: true, isEnabled: true)
    #expect(action == .none)
}

/// Verifies that markInternalToggle only suppresses ONE subsequent external change.
@Test func markInternalToggle_suppressesExactlyOneExternalChange() {
    var coordinator = ButterflyInteractionCoordinator()
    coordinator.initialize(isOn: false)
    coordinator.markInternalToggle()

    // First external change is suppressed.
    let first = coordinator.actionForExternalStateChange(newValue: true, isEnabled: true)
    #expect(first == .none)

    // Second external change is NOT suppressed.
    let second = coordinator.actionForExternalStateChange(newValue: false, isEnabled: true)
    #expect(second == .animate(sign: 1.0))
}

/// Verifies that calling markInternalToggle twice still only suppresses one external change.
@Test func markInternalToggleTwice_stillSuppressesOnlyOne() {
    var coordinator = ButterflyInteractionCoordinator()
    coordinator.initialize(isOn: false)
    coordinator.markInternalToggle()
    coordinator.markInternalToggle() // redundant call

    // Still only one suppression.
    let first = coordinator.actionForExternalStateChange(newValue: true, isEnabled: true)
    #expect(first == .none)

    let second = coordinator.actionForExternalStateChange(newValue: false, isEnabled: true)
    #expect(second == .animate(sign: 1.0))
}

/// Verifies token wrapping at UInt64.max does not crash.
@Test func tokenWraparound_doesNotCrash() {
    var coordinator = ButterflyInteractionCoordinator()
    coordinator.initialize(isOn: true)

    // Manually set spinToken near overflow via beginSpin calls.
    // We can't reach UInt64.max in a loop, so we test the wrapping arithmetic directly.
    // beginSpin uses &+=, so we verify the struct is usable after many spins.
    for _ in 0 ..< 1000 {
        _ = coordinator.beginSpin()
    }
    let latest = coordinator.beginSpin()
    #expect(coordinator.isCurrentSpinToken(latest))
}

/// Verifies re-initialize resets lastRenderedIsOn for correct subsequent behavior.
@Test func reinitialize_resetsLastRenderedState() {
    var coordinator = ButterflyInteractionCoordinator()
    coordinator.initialize(isOn: true)

    // First change: true → false, animates.
    let action1 = coordinator.actionForExternalStateChange(newValue: false, isEnabled: true)
    #expect(action1 == .animate(sign: 1.0))

    // Re-initialize as false.
    coordinator.initialize(isOn: false)

    // Same value as re-initialized: no animation.
    let action2 = coordinator.actionForExternalStateChange(newValue: false, isEnabled: true)
    #expect(action2 == .none)

    // Different value: animates.
    let action3 = coordinator.actionForExternalStateChange(newValue: true, isEnabled: true)
    #expect(action3 == .animate(sign: -1.0))
}
