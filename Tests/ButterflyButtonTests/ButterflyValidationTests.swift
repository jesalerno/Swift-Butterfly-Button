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
