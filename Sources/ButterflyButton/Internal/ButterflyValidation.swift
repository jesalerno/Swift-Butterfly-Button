// Copyright 2026 John Salerno.

import Foundation
import SwiftUI

/// Validation and math helpers used by `ButterflyButton`.
struct ButterflyValidation {
    static let minimumSideLength: CGFloat = 44
    static let minimumStrokeWidth: CGFloat = 1
    static let defaultStrokeWidth: CGFloat = 2
    static let defaultSpinDuration: TimeInterval = 2.0
    static let defaultSpinSpeed: Double = 1.0

    /// Clamps side length to a safe minimum.
    ///
    /// - Parameter value: Candidate side length.
    /// - Returns: A finite side length at or above the minimum.
    static func clampedSideLength(_ value: CGFloat) -> CGFloat {
        guard value.isFinite else { return minimumSideLength }
        return max(value, minimumSideLength)
    }

    /// Clamps mount stroke width into the allowed range for a given side length.
    ///
    /// - Parameters:
    ///   - value: Candidate stroke width.
    ///   - sideLength: Side length used to derive the maximum stroke.
    /// - Returns: A finite stroke width in the valid range.
    static func clampedMountStrokeWidth(_ value: CGFloat, sideLength: CGFloat) -> CGFloat {
        guard value.isFinite else { return defaultStrokeWidth }
        let maxStroke = clampedSideLength(sideLength) * 0.10
        return min(max(value, minimumStrokeWidth), maxStroke)
    }

    /// Returns a valid positive spin duration.
    ///
    /// - Parameter value: Candidate duration.
    /// - Returns: The candidate duration when valid, otherwise the default.
    static func validSpinDuration(_ value: TimeInterval) -> TimeInterval {
        (value.isFinite && value > 0) ? value : defaultSpinDuration
    }

    /// Returns a valid positive spin speed.
    ///
    /// - Parameter value: Candidate speed multiplier.
    /// - Returns: The candidate speed when valid, otherwise the default.
    static func validSpinSpeed(_ value: Double) -> Double {
        (value.isFinite && value > 0) ? value : defaultSpinSpeed
    }

    /// Computes medallion diameter from side length and mount stroke.
    ///
    /// - Parameters:
    ///   - sideLength: Mount side length.
    ///   - strokeWidth: Mount stroke width.
    /// - Returns: The medallion diameter.
    static func medallionDiameter(sideLength: CGFloat, strokeWidth: CGFloat) -> CGFloat {
        let clampedSide = clampedSideLength(sideLength)
        let clampedStroke = clampedMountStrokeWidth(strokeWidth, sideLength: clampedSide)
        let interior = max(clampedSide - (clampedStroke * 2), 0)
        return interior * 0.90
    }

    /// Maps a touch location to spin direction using a top/bottom split.
    ///
    /// - Parameters:
    ///   - location: Touch location.
    ///   - size: Control size.
    /// - Returns: Spin direction inferred from location.
    static func direction(for location: CGPoint, in size: CGSize) -> SpinDirection {
        location.y <= (size.height / 2) ? .topToBottom : .bottomToTop
    }
}

enum ButterflyAnimationMode: Equatable {
    case spin
    case reducedMotion

    /// Resolves animation mode from accessibility reduce-motion preference.
    ///
    /// - Parameter reduceMotion: Whether reduce motion is enabled.
    /// - Returns: The matching animation mode.
    static func from(reduceMotion: Bool) -> Self {
        reduceMotion ? .reducedMotion : .spin
    }
}

/// A 3D rotation axis for `rotation3DEffect`.
struct ButterflyRotationAxis: Equatable {
    let x: CGFloat
    let y: CGFloat
    let z: CGFloat
}

extension ButterflyValidation {
    /// Maps an axle orientation to a 3D rotation axis.
    ///
    /// - Parameter orientation: Axle orientation.
    /// - Returns: Rotation axis to use for medallion animation.
    static func rotationAxis(for orientation: AxleOrientation) -> ButterflyRotationAxis {
        switch orientation {
        case .horizontal:
            return ButterflyRotationAxis(x: 1, y: 0, z: 0)
        case .vertical:
            return ButterflyRotationAxis(x: 0, y: 1, z: 0)
        case .diagonalLTR:
            return ButterflyRotationAxis(x: 1, y: 1, z: 0)
        case .diagonalRTL:
            return ButterflyRotationAxis(x: 1, y: -1, z: 0)
        }
    }

    /// Computes spin degrees using default duration and speed.
    ///
    /// - Parameters:
    ///   - velocity: Gesture velocity magnitude.
    ///   - enableFlickPhysics: Whether velocity should add spin boost.
    /// - Returns: Total spin degrees snapped to an odd half-turn count.
    static func spinDegrees(for velocity: CGFloat, enableFlickPhysics: Bool) -> Double {
        spinDegrees(
            duration: defaultSpinDuration,
            spinSpeed: defaultSpinSpeed,
            velocity: velocity,
            enableFlickPhysics: enableFlickPhysics
        )
    }

    /// Computes spin degrees for a given duration, speed, and velocity.
    ///
    /// - Parameters:
    ///   - duration: Requested spin duration.
    ///   - spinSpeed: Requested speed multiplier.
    ///   - velocity: Gesture velocity magnitude.
    ///   - enableFlickPhysics: Whether velocity should add spin boost.
    /// - Returns: Total spin degrees snapped to an odd half-turn count.
    static func spinDegrees(duration: TimeInterval, spinSpeed: Double, velocity: CGFloat, enableFlickPhysics: Bool) -> Double {
        let validDuration = max(validSpinDuration(duration), 0.1)
        let validSpeed = validSpinSpeed(spinSpeed)
        let clampedVelocity = (velocity.isFinite && velocity > 0) ? velocity : 0
        let baseDegrees = 1080.0 * validDuration * validSpeed
        let velocityBoost = enableFlickPhysics
            ? min(Double(clampedVelocity) * 0.6, 900)
            : 0
        let rawDegrees = max(baseDegrees + velocityBoost, 180)

        var halfTurns = Int(rawDegrees / 180.0)
        if halfTurns < 1 { halfTurns = 1 }
        if halfTurns.isMultiple(of: 2) { halfTurns += 1 } // ensure opposite face at stop
        return Double(halfTurns) * 180.0
    }

    /// Fits requested half-turns to a duration budget while keeping odd parity.
    ///
    /// - Parameters:
    ///   - totalDegrees: Requested spin degrees.
    ///   - duration: Total duration budget.
    ///   - minimumSegmentDuration: Minimum duration per half-turn segment.
    /// - Returns: A positive odd half-turn count.
    static func fittedHalfTurns(
        from totalDegrees: Double,
        duration: TimeInterval,
        minimumSegmentDuration: TimeInterval
    ) -> Int {
        guard totalDegrees.isFinite, duration.isFinite, minimumSegmentDuration.isFinite else {
            return 1
        }
        let requestedHalfTurns = max(Int(totalDegrees / 180.0), 1)
        let maxAllowedHalfTurns = max(Int(duration / max(minimumSegmentDuration, 0.001)), 1)
        var fitted = min(requestedHalfTurns, maxAllowedHalfTurns)

        if fitted.isMultiple(of: 2) {
            fitted = max(fitted - 1, 1)
        }
        return fitted
    }

    /// Determines whether the top face should be visible at a rotation.
    ///
    /// - Parameter rotationDegrees: Current rotation in degrees.
    /// - Returns: `true` when top face is visible.
    static func visibleTopFace(rotationDegrees: Double) -> Bool {
        guard rotationDegrees.isFinite else { return true }
        let normalizedHalfTurns = Int(floor(abs(rotationDegrees) / 180.0))
        return normalizedHalfTurns.isMultiple(of: 2)
    }

    /// Returns baseline rotation for a boolean state.
    ///
    /// - Parameter isOn: Current state.
    /// - Returns: `0` when on, `180` when off.
    static func baselineRotationDegrees(for isOn: Bool) -> Double {
        isOn ? 0 : 180
    }

    /// Snaps a rotation to the nearest parity matching the given state.
    ///
    /// - Parameters:
    ///   - current: Current rotation in degrees.
    ///   - isOn: Target state parity.
    /// - Returns: Snapped rotation in half-turn increments.
    static func snappedStopRotationDegrees(current: Double, isOn: Bool) -> Double {
        guard current.isFinite else { return baselineRotationDegrees(for: isOn) }
        var halfTurns = Int(current / 180.0)
        let parity = abs(halfTurns) % 2
        let desiredParity = isOn ? 0 : 1

        if parity != desiredParity {
            halfTurns += current >= 0 ? 1 : -1
        }

        return Double(halfTurns) * 180.0
    }
}

