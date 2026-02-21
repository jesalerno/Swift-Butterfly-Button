// Copyright 2026 John Salerno.

import CoreGraphics
import Testing
@testable import ButterflyButton

// MARK: - Parameterized rotation axis tests

/// Verifies rotation axis mapping for each axle orientation using parameterized inputs.
@Test("Rotation axis for orientation", arguments: [
    (AxleOrientation.horizontal, ButterflyRotationAxis(x: 1, y: 0, z: 0)),
    (AxleOrientation.vertical, ButterflyRotationAxis(x: 0, y: 1, z: 0)),
    (AxleOrientation.diagonalLTR, ButterflyRotationAxis(x: 1, y: 1, z: 0)),
    (AxleOrientation.diagonalRTL, ButterflyRotationAxis(x: 1, y: -1, z: 0)),
])
func rotationAxisParameterized(orientation: AxleOrientation, expected: ButterflyRotationAxis) {
    #expect(ButterflyValidation.rotationAxis(for: orientation) == expected)
}

// MARK: - Parameterized animation mode tests

/// Verifies animation mode mapping using parameterized inputs.
@Test("Animation mode from reduceMotion", arguments: [
    (true, ButterflyAnimationMode.reducedMotion),
    (false, ButterflyAnimationMode.spin),
])
func animationModeParameterized(reduceMotion: Bool, expected: ButterflyAnimationMode) {
    #expect(ButterflyAnimationMode.from(reduceMotion: reduceMotion) == expected)
}

// MARK: - Parameterized baseline rotation

/// Verifies baseline rotation degrees for both boolean states.
@Test("Baseline rotation for isOn", arguments: [
    (true, 0.0),
    (false, 180.0),
])
func baselineRotationParameterized(isOn: Bool, expected: Double) {
    #expect(ButterflyValidation.baselineRotationDegrees(for: isOn) == expected)
}

// MARK: - Parameterized visible top face boundary

/// Verifies visible top face at key rotation boundaries.
@Test("Visible top face at boundary", arguments: [
    (0.0, true),
    (89.0, true),
    (90.0, true),
    (179.0, true),
    (180.0, false),
    (269.0, false),
    (270.0, false),
    (359.0, false),
    (360.0, true),
    (540.0, false),
    (720.0, true),
])
func visibleTopFaceParameterized(degrees: Double, expectedTop: Bool) {
    #expect(ButterflyValidation.visibleTopFace(rotationDegrees: degrees) == expectedTop)
}

// MARK: - Parameterized side length clamping

/// Verifies side length clamping across representative values.
@Test("Side length clamping", arguments: [
    (-100.0 as CGFloat, 44.0 as CGFloat),
    (0.0 as CGFloat, 44.0 as CGFloat),
    (20.0 as CGFloat, 44.0 as CGFloat),
    (43.99 as CGFloat, 44.0 as CGFloat),
    (44.0 as CGFloat, 44.0 as CGFloat),
    (44.01 as CGFloat, 44.01 as CGFloat),
    (100.0 as CGFloat, 100.0 as CGFloat),
    (1000.0 as CGFloat, 1000.0 as CGFloat),
])
func sideLengthClampingParameterized(input: CGFloat, expected: CGFloat) {
    #expect(ButterflyValidation.clampedSideLength(input) == expected)
}

// MARK: - Parameterized spin duration validation

/// Verifies spin duration validation across representative values.
@Test("Spin duration validation", arguments: [
    (-5.0, 2.0),
    (0.0, 2.0),
    (0.001, 0.001),
    (1.5, 1.5),
    (10.0, 10.0),
])
func spinDurationParameterized(input: Double, expected: Double) {
    #expect(ButterflyValidation.validSpinDuration(input) == expected)
}

// MARK: - Parameterized spin speed validation

/// Verifies spin speed validation across representative values.
@Test("Spin speed validation", arguments: [
    (-5.0, 1.0),
    (0.0, 1.0),
    (0.001, 0.001),
    (1.75, 1.75),
    (5.0, 5.0),
])
func spinSpeedParameterized(input: Double, expected: Double) {
    #expect(ButterflyValidation.validSpinSpeed(input) == expected)
}
