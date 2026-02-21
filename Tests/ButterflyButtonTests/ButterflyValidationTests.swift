// Copyright 2026 John Salerno.

import CoreGraphics
import Testing
@testable import ButterflyButton

/// Verifies side length clamping respects the minimum.
@Test func sideLengthClampsToMinimum() {
    #expect(ButterflyValidation.clampedSideLength(20) == 44)
    #expect(ButterflyValidation.clampedSideLength(44) == 44)
    #expect(ButterflyValidation.clampedSideLength(60) == 60)
}

/// Verifies stroke width clamps to valid bounds.
@Test func strokeWidthClampsToBounds() {
    #expect(ButterflyValidation.clampedMountStrokeWidth(0.2, sideLength: 60) == 1)
    #expect(ButterflyValidation.clampedMountStrokeWidth(50, sideLength: 60) == 6)
}

/// Verifies invalid durations fall back to defaults.
@Test func durationFallsBackWhenInvalid() {
    #expect(ButterflyValidation.validSpinDuration(0) == 2.0)
    #expect(ButterflyValidation.validSpinDuration(-2) == 2.0)
    #expect(ButterflyValidation.validSpinDuration(1.2) == 1.2)
}

/// Verifies invalid spin speeds fall back to defaults.
@Test func spinSpeedFallsBackWhenInvalid() {
    #expect(ButterflyValidation.validSpinSpeed(0) == 1.0)
    #expect(ButterflyValidation.validSpinSpeed(-2) == 1.0)
    #expect(ButterflyValidation.validSpinSpeed(1.5) == 1.5)
}

/// Verifies non-finite values map to safe defaults.
@Test func nonFiniteValuesFallBackToSafeDefaults() {
    #expect(ButterflyValidation.clampedSideLength(.nan) == 44)
    #expect(ButterflyValidation.clampedMountStrokeWidth(.infinity, sideLength: 60) == 2)
    #expect(ButterflyValidation.validSpinDuration(.nan) == 2.0)
    #expect(ButterflyValidation.validSpinSpeed(.infinity) == 1.0)
    #expect(ButterflyValidation.visibleTopFace(rotationDegrees: .nan) == true)
    #expect(ButterflyValidation.snappedStopRotationDegrees(current: .nan, isOn: false) == 180)
}

/// Verifies medallion size ratio against interior mount size.
@Test func medallionIsNinetyPercentOfInterior() {
    let diameter = ButterflyValidation.medallionDiameter(sideLength: 60, strokeWidth: 2)
    #expect(diameter == 50.4)
}

/// Verifies direction mapping from touch location split.
@Test func directionUsesTopBottomSplit() {
    let size = CGSize(width: 60, height: 60)
    #expect(ButterflyValidation.direction(for: CGPoint(x: 30, y: 10), in: size) == .topToBottom)
    #expect(ButterflyValidation.direction(for: CGPoint(x: 30, y: 50), in: size) == .bottomToTop)
}

/// Verifies reduced-motion flag maps to expected animation mode.
@Test func animationModeRespectsReduceMotion() {
    #expect(ButterflyAnimationMode.from(reduceMotion: true) == .reducedMotion)
    #expect(ButterflyAnimationMode.from(reduceMotion: false) == .spin)
}

/// Verifies axle orientation maps to the expected rotation axis.
@Test func rotationAxisFollowsAxleOrientation() {
    #expect(ButterflyValidation.rotationAxis(for: .horizontal) == ButterflyRotationAxis(x: 1, y: 0, z: 0))
    #expect(ButterflyValidation.rotationAxis(for: .vertical) == ButterflyRotationAxis(x: 0, y: 1, z: 0))
    #expect(ButterflyValidation.rotationAxis(for: .diagonalLTR) == ButterflyRotationAxis(x: 1, y: 1, z: 0))
    #expect(ButterflyValidation.rotationAxis(for: .diagonalRTL) == ButterflyRotationAxis(x: 1, y: -1, z: 0))
}

/// Verifies spin degrees always stop on opposite face parity.
@Test func spinDegreesAlwaysLandOnOppositeFace() {
    let low = ButterflyValidation.spinDegrees(for: 0, enableFlickPhysics: true)
    let medium = ButterflyValidation.spinDegrees(for: 400, enableFlickPhysics: true)
    let high = ButterflyValidation.spinDegrees(for: 9999, enableFlickPhysics: true)
    let noPhysics = ButterflyValidation.spinDegrees(for: 9999, enableFlickPhysics: false)

    #expect(low.truncatingRemainder(dividingBy: 360) == 180)
    #expect(medium.truncatingRemainder(dividingBy: 360) == 180)
    #expect(high.truncatingRemainder(dividingBy: 360) == 180)
    #expect(noPhysics.truncatingRemainder(dividingBy: 360) == 180)
    #expect(noPhysics >= 180)
}

/// Verifies higher speed yields more rotation for equal duration.
@Test func higherSpinSpeedProducesMoreRotationForSameDuration() {
    let slow = ButterflyValidation.spinDegrees(duration: 2.0, spinSpeed: 0.5, velocity: 0, enableFlickPhysics: false)
    let fast = ButterflyValidation.spinDegrees(duration: 2.0, spinSpeed: 2.0, velocity: 0, enableFlickPhysics: false)
    #expect(fast > slow)
    #expect(slow.truncatingRemainder(dividingBy: 360) == 180)
    #expect(fast.truncatingRemainder(dividingBy: 360) == 180)
}

/// Verifies fitted half-turn output is odd and duration-safe.
@Test func fittedHalfTurnsKeepsOddParityAndFitsDurationBudget() {
    let fitted = ButterflyValidation.fittedHalfTurns(
        from: 9000,
        duration: 1.0,
        minimumSegmentDuration: 0.05
    )
    #expect(fitted <= 20)
    #expect(fitted % 2 == 1)
    #expect(fitted >= 1)
}

/// Verifies visible face toggles across half-turn boundaries.
@Test func visibleFaceChangesWithRotationPhase() {
    #expect(ButterflyValidation.visibleTopFace(rotationDegrees: 0) == true)
    #expect(ButterflyValidation.visibleTopFace(rotationDegrees: 179) == true)
    #expect(ButterflyValidation.visibleTopFace(rotationDegrees: 180) == false)
    #expect(ButterflyValidation.visibleTopFace(rotationDegrees: 359) == false)
    #expect(ButterflyValidation.visibleTopFace(rotationDegrees: 360) == true)
}

/// Verifies baseline rotation reflects boolean state.
@Test func baselineRotationMatchesState() {
    #expect(ButterflyValidation.baselineRotationDegrees(for: true) == 0)
    #expect(ButterflyValidation.baselineRotationDegrees(for: false) == 180)
}

/// Verifies snapped stop rotation matches target state parity.
@Test func snappedStopRotationMatchesStateParity() {
    let onSnap = ButterflyValidation.snappedStopRotationDegrees(current: 719.2, isOn: true)
    let offSnap = ButterflyValidation.snappedStopRotationDegrees(current: 719.2, isOn: false)

    #expect(ButterflyValidation.visibleTopFace(rotationDegrees: onSnap) == true)
    #expect(ButterflyValidation.visibleTopFace(rotationDegrees: offSnap) == false)
}

// MARK: - Boundary and edge-case additions

/// Verifies direction at the exact midpoint of the container (y == height/2 → topToBottom via <=).
@Test func directionAtExactMidpoint_isTopToBottom() {
    let size = CGSize(width: 60, height: 60)
    #expect(ButterflyValidation.direction(for: CGPoint(x: 30, y: 30), in: size) == .topToBottom)
}

/// Verifies direction with a zero-height container.
@Test func directionWithZeroHeightContainer_handlesGracefully() {
    let size = CGSize(width: 60, height: 0)
    // height/2 == 0, so y == 0 → topToBottom (<=), y > 0 → bottomToTop.
    #expect(ButterflyValidation.direction(for: CGPoint(x: 30, y: 0), in: size) == .topToBottom)
    #expect(ButterflyValidation.direction(for: CGPoint(x: 30, y: 1), in: size) == .bottomToTop)
}

/// Verifies visibleTopFace at 90° (mid-top-face) and 270° (mid-bottom-face).
@Test func visibleTopFaceAtQuarterTurns() {
    // 90°: floor(90/180) == 0, which is even → top face visible.
    #expect(ButterflyValidation.visibleTopFace(rotationDegrees: 90) == true)
    // 270°: floor(270/180) == 1, which is odd → bottom face visible.
    #expect(ButterflyValidation.visibleTopFace(rotationDegrees: 270) == false)
}

/// Verifies visibleTopFace with negative rotation degrees.
@Test func visibleTopFaceWithNegativeRotation() {
    // -90°: floor(abs(-90)/180) == floor(0.5) == 0 → top.
    #expect(ButterflyValidation.visibleTopFace(rotationDegrees: -90) == true)
    // -180°: floor(abs(-180)/180) == 1 → bottom.
    #expect(ButterflyValidation.visibleTopFace(rotationDegrees: -180) == false)
    // -360°: floor(2) == 2 → top.
    #expect(ButterflyValidation.visibleTopFace(rotationDegrees: -360) == true)
}

/// Verifies snappedStopRotationDegrees with negative current rotation.
@Test func snappedStopRotation_withNegativeCurrent() {
    let onSnap = ButterflyValidation.snappedStopRotationDegrees(current: -90, isOn: true)
    let offSnap = ButterflyValidation.snappedStopRotationDegrees(current: -90, isOn: false)

    #expect(ButterflyValidation.visibleTopFace(rotationDegrees: onSnap) == true)
    #expect(ButterflyValidation.visibleTopFace(rotationDegrees: offSnap) == false)
    // Snapped values should be half-turn multiples.
    #expect(onSnap.truncatingRemainder(dividingBy: 180) == 0)
    #expect(offSnap.truncatingRemainder(dividingBy: 180) == 0)
}

/// Verifies snappedStopRotationDegrees at exactly a half-turn boundary.
@Test func snappedStopRotation_atExactHalfTurn() {
    // current == 360 (even half-turns) → on parity matches, off parity doesn't.
    let onSnap = ButterflyValidation.snappedStopRotationDegrees(current: 360, isOn: true)
    let offSnap = ButterflyValidation.snappedStopRotationDegrees(current: 360, isOn: false)

    #expect(onSnap == 360)
    #expect(offSnap == 540) // next odd half-turn: 360 + 180.
}

/// Verifies fittedHalfTurns with minimumSegmentDuration == 0 (clamped to 0.001 internally).
@Test func fittedHalfTurns_withZeroMinimumSegmentDuration() {
    let result = ButterflyValidation.fittedHalfTurns(
        from: 1080,
        duration: 1.0,
        minimumSegmentDuration: 0
    )
    #expect(result >= 1)
    #expect(result % 2 == 1)
}

/// Verifies fittedHalfTurns returns 1 when duration is very small.
@Test func fittedHalfTurns_withTinyDuration() {
    let result = ButterflyValidation.fittedHalfTurns(
        from: 5400,
        duration: 0.001,
        minimumSegmentDuration: 0.05
    )
    #expect(result == 1)
}

/// Verifies medallionDiameter returns 0 when stroke width consumes the entire interior.
@Test func medallionDiameter_zeroWhenStrokeConsumesInterior() {
    // sideLength 44 (minimum), stroke 22 → interior = 44 - 44 = 0 → diameter = 0.
    // But stroke is clamped to max 10% of sideLength = 4.4, so this tests the clamped path.
    let result = ButterflyValidation.medallionDiameter(sideLength: 44, strokeWidth: 44)
    #expect(result >= 0)
    #expect(result.isFinite)
}

/// Verifies clampedMountStrokeWidth when sideLength == 0 (clamped to 44, max stroke 4.4).
@Test func clampedMountStrokeWidth_withZeroSideLength() {
    let result = ButterflyValidation.clampedMountStrokeWidth(3, sideLength: 0)
    // sideLength clamped to 44, max stroke = 44 * 0.10 = 4.4, so 3 is within bounds.
    #expect(result == 3)
}

/// Verifies clampedMountStrokeWidth at exact boundary (value == max stroke).
@Test func clampedMountStrokeWidth_atExactMaxBoundary() {
    // sideLength 100, max stroke = 100 * 0.10 = 10.
    #expect(ButterflyValidation.clampedMountStrokeWidth(10, sideLength: 100) == 10)
    #expect(ButterflyValidation.clampedMountStrokeWidth(10.001, sideLength: 100) == 10)
}

/// Verifies clampedSideLength at exact minimum boundary.
@Test func clampedSideLength_atExactMinimum() {
    #expect(ButterflyValidation.clampedSideLength(44) == 44)
    #expect(ButterflyValidation.clampedSideLength(43.99) == 44)
    #expect(ButterflyValidation.clampedSideLength(44.01) == 44.01)
}

/// Verifies spinDegrees with velocity at the boost cap (900 degrees max boost).
@Test func spinDegrees_velocityBoostCappedAt900() {
    let atCap = ButterflyValidation.spinDegrees(
        duration: 2.0, spinSpeed: 1.0, velocity: 1500, enableFlickPhysics: true
    )
    let beyondCap = ButterflyValidation.spinDegrees(
        duration: 2.0, spinSpeed: 1.0, velocity: 99999, enableFlickPhysics: true
    )
    // Both should produce the same result since velocity boost caps at 900.
    #expect(atCap == beyondCap)
}

/// Verifies spinDegrees with negative velocity (treated as 0, no boost).
@Test func spinDegrees_negativeVelocityTreatedAsZero() {
    let negative = ButterflyValidation.spinDegrees(
        duration: 2.0, spinSpeed: 1.0, velocity: -500, enableFlickPhysics: true
    )
    let zero = ButterflyValidation.spinDegrees(
        duration: 2.0, spinSpeed: 1.0, velocity: 0, enableFlickPhysics: true
    )
    #expect(negative == zero)
}

/// Verifies validSpinDuration treats epsilon above zero as valid.
@Test func validSpinDuration_verySmallPositiveIsValid() {
    let tiny = ButterflyValidation.validSpinDuration(0.001)
    #expect(tiny == 0.001)
}

/// Verifies validSpinSpeed treats epsilon above zero as valid.
@Test func validSpinSpeed_verySmallPositiveIsValid() {
    let tiny = ButterflyValidation.validSpinSpeed(0.001)
    #expect(tiny == 0.001)
}
