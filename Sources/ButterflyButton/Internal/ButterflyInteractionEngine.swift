// Copyright 2026 John Salerno.

import Foundation

enum ExternalChangeAction: Equatable {
    case none
    case animate(sign: Double)
}

/// Coordinates spin tokens and external-change animation policy.
struct ButterflyInteractionCoordinator {
    private(set) var spinToken: UInt64 = 0
    private(set) var lastRenderedIsOn: Bool?
    private(set) var suppressExternalChangeAnimation = false

    /// Initializes coordinator state for initial render value.
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
    mutating func actionForExternalStateChange(newValue: Bool, isEnabled: Bool) -> ExternalChangeAction {
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
