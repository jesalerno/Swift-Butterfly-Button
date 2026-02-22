// Copyright 2026 John Salerno.

import Foundation

/// Coordinates spin sequencing, token management, and external-change animation policy.
///
/// The coordinator ensures that only the most recent spin is considered active and that
/// external binding changes animate appropriately unless they originated from an internal
/// toggle.
struct ButterflyInteractionCoordinator {

    /// Describes how to react to an external state change.
    ///
    /// `.none` means no animation should run. `.animate(sign:)` requests an animated rotation
    /// in the specified direction (positive or negative sign).
    enum Action: Equatable {
        case none
        case animate(sign: Double)
    }

    /// Monotonically increasing token identifying the active spin.
    private(set) var spinToken: UInt64 = 0

    /// The last on/off value rendered to the UI; used to detect external changes.
    private(set) var lastRenderedIsOn: Bool?

    /// Set when the next external change is known to originate from an internal toggle.
    private(set) var suppressExternalChangeAnimation = false

    /// Initializes coordinator state for the initial render.
    ///
    /// - Parameter isOn: Initially rendered on/off state.
    mutating func initialize(isOn: Bool) {
        lastRenderedIsOn = isOn
    }

    /// Starts a new spin and returns its token.
    ///
    /// - Returns: Monotonic token identifying the active spin.
    mutating func beginSpin() -> UInt64 {
        spinToken &+= 1
        return spinToken
    }

    /// Checks whether a token is still the active spin token.
    ///
    /// - Parameter token: Token to compare.
    /// - Returns: `true` when token matches the current spin.
    func isCurrentSpinToken(_ token: UInt64) -> Bool {
        token == spinToken
    }

    /// Marks that the next external state change came from internal spin completion.
    mutating func markInternalToggle() {
        suppressExternalChangeAnimation = true
    }

    /// Resolves how to react to an externally observed state change.
    ///
    /// - Parameters:
    ///   - newValue: New external value.
    ///   - isEnabled: Whether control is currently enabled.
    /// - Returns: Animation action to apply for the change.
    mutating func actionForExternalStateChange(newValue: Bool, isEnabled: Bool) -> Action {
        if suppressExternalChangeAnimation {
            suppressExternalChangeAnimation = false
            lastRenderedIsOn = newValue
            return .none
        }

        guard let last = lastRenderedIsOn, last != newValue else {
            lastRenderedIsOn = newValue
            return .none
        }

        lastRenderedIsOn = newValue
        guard isEnabled else { return .none }
        return .animate(sign: newValue ? -1.0 : 1.0)
    }
}

