// Copyright 2026 John Salerno.

import CoreGraphics
import Foundation
import Testing
@testable import ButterflyButton

/// Deterministic PRNG for repeatable fuzz-style tests.
private struct DeterministicRNG {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func nextUInt64() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }

    mutating func nextUnitDouble() -> Double {
        Double(nextUInt64() >> 11) / Double(1 << 53)
    }

    mutating func nextDouble(in range: ClosedRange<Double>) -> Double {
        range.lowerBound + (range.upperBound - range.lowerBound) * nextUnitDouble()
    }
}

/// Validates side-length clamping for in-bound, out-of-bound, invalid, and fuzzed inputs.
@Test func clampedSideLength_hasBoundsInvalidAndFuzzCoverage() {
    #expect(ButterflyValidation.clampedSideLength(44) == 44)
    #expect(ButterflyValidation.clampedSideLength(120) == 120)

    #expect(ButterflyValidation.clampedSideLength(-1) == 44)
    #expect(ButterflyValidation.clampedSideLength(0) == 44)

    #expect(ButterflyValidation.clampedSideLength(.nan) == 44)
    #expect(ButterflyValidation.clampedSideLength(.infinity) == 44)
    #expect(ButterflyValidation.clampedSideLength(-.infinity) == 44)

    var rng = DeterministicRNG(seed: 0xA11CE)
    for _ in 0..<500 {
        let sample = CGFloat(rng.nextDouble(in: -10_000...10_000))
        let result = ButterflyValidation.clampedSideLength(sample)
        #expect(result >= ButterflyValidation.minimumSideLength)
        #expect(result.isFinite)
    }
}

/// Validates mount-stroke clamping for in-bound, out-of-bound, invalid, and fuzzed inputs.
@Test func clampedMountStrokeWidth_hasBoundsInvalidAndFuzzCoverage() {
    #expect(ButterflyValidation.clampedMountStrokeWidth(2, sideLength: 60) == 2)

    #expect(ButterflyValidation.clampedMountStrokeWidth(-10, sideLength: 60) == 1)
    #expect(ButterflyValidation.clampedMountStrokeWidth(999, sideLength: 60) == 6)

    #expect(ButterflyValidation.clampedMountStrokeWidth(.nan, sideLength: 60) == 2)
    #expect(ButterflyValidation.clampedMountStrokeWidth(.infinity, sideLength: 60) == 2)

    var rng = DeterministicRNG(seed: 0xBADC0DE)
    for _ in 0..<500 {
        let side = CGFloat(rng.nextDouble(in: -500...500))
        let width = CGFloat(rng.nextDouble(in: -500...500))
        let result = ButterflyValidation.clampedMountStrokeWidth(width, sideLength: side)
        let maxStroke = ButterflyValidation.clampedSideLength(side) * 0.10
        #expect(result >= ButterflyValidation.minimumStrokeWidth)
        #expect(result <= maxStroke)
        #expect(result.isFinite)
    }
}

/// Validates spin-duration normalization for in-bound, out-of-bound, invalid, and fuzzed inputs.
@Test func validSpinDuration_hasBoundsInvalidAndFuzzCoverage() {
    #expect(ButterflyValidation.validSpinDuration(1.25) == 1.25)

    #expect(ButterflyValidation.validSpinDuration(0) == ButterflyValidation.defaultSpinDuration)
    #expect(ButterflyValidation.validSpinDuration(-3) == ButterflyValidation.defaultSpinDuration)

    #expect(ButterflyValidation.validSpinDuration(.nan) == ButterflyValidation.defaultSpinDuration)
    #expect(ButterflyValidation.validSpinDuration(.infinity) == ButterflyValidation.defaultSpinDuration)

    var rng = DeterministicRNG(seed: 0xD00D)
    for _ in 0..<500 {
        let value = rng.nextDouble(in: -50...50)
        let result = ButterflyValidation.validSpinDuration(value)
        #expect(result > 0)
        #expect(result.isFinite)
    }
}

/// Validates spin-speed normalization for in-bound, out-of-bound, invalid, and fuzzed inputs.
@Test func validSpinSpeed_hasBoundsInvalidAndFuzzCoverage() {
    #expect(ButterflyValidation.validSpinSpeed(1.75) == 1.75)

    #expect(ButterflyValidation.validSpinSpeed(0) == ButterflyValidation.defaultSpinSpeed)
    #expect(ButterflyValidation.validSpinSpeed(-3) == ButterflyValidation.defaultSpinSpeed)

    #expect(ButterflyValidation.validSpinSpeed(.nan) == ButterflyValidation.defaultSpinSpeed)
    #expect(ButterflyValidation.validSpinSpeed(.infinity) == ButterflyValidation.defaultSpinSpeed)

    var rng = DeterministicRNG(seed: 0x12345678)
    for _ in 0..<500 {
        let value = rng.nextDouble(in: -50...50)
        let result = ButterflyValidation.validSpinSpeed(value)
        #expect(result > 0)
        #expect(result.isFinite)
    }
}

/// Validates medallion-diameter computation for in-bound, out-of-bound, invalid, and fuzzed inputs.
@Test func medallionDiameter_hasBoundsInvalidAndFuzzCoverage() {
    #expect(ButterflyValidation.medallionDiameter(sideLength: 60, strokeWidth: 2) == 50.4)

    #expect(ButterflyValidation.medallionDiameter(sideLength: 10, strokeWidth: 999) >= 0)
    #expect(ButterflyValidation.medallionDiameter(sideLength: -10, strokeWidth: -10) >= 0)

    #expect(ButterflyValidation.medallionDiameter(sideLength: .nan, strokeWidth: 2).isFinite)
    #expect(ButterflyValidation.medallionDiameter(sideLength: 60, strokeWidth: .nan).isFinite)

    var rng = DeterministicRNG(seed: 0xCAFEBABE)
    for _ in 0..<500 {
        let side = CGFloat(rng.nextDouble(in: -500...1_000))
        let stroke = CGFloat(rng.nextDouble(in: -500...500))
        let result = ButterflyValidation.medallionDiameter(sideLength: side, strokeWidth: stroke)
        #expect(result >= 0)
        #expect(result.isFinite)
    }
}

/// Validates direction inference for in-bound, out-of-bound, invalid-edge, and fuzzed inputs.
@Test func direction_hasBoundsInvalidAndFuzzCoverage() {
    let size = CGSize(width: 60, height: 60)
    #expect(ButterflyValidation.direction(for: CGPoint(x: 30, y: 10), in: size) == .topToBottom)
    #expect(ButterflyValidation.direction(for: CGPoint(x: 30, y: 50), in: size) == .bottomToTop)

    #expect(ButterflyValidation.direction(for: CGPoint(x: -999, y: -1), in: size) == .topToBottom)
    #expect(ButterflyValidation.direction(for: CGPoint(x: 999, y: 999), in: size) == .bottomToTop)

    #expect(ButterflyValidation.direction(for: CGPoint(x: CGFloat.nan, y: CGFloat.nan), in: size) == .bottomToTop)

    var rng = DeterministicRNG(seed: 0x515151)
    for _ in 0..<500 {
        let y = CGFloat(rng.nextDouble(in: -1_000...1_000))
        let expected: SpinDirection = y <= (size.height / 2) ? .topToBottom : .bottomToTop
        #expect(ButterflyValidation.direction(for: CGPoint(x: 0, y: y), in: size) == expected)
    }
}

/// Validates spin-degree outputs for in-bound, out-of-bound, invalid, and fuzzed inputs.
@Test func spinDegrees_hasBoundsInvalidAndFuzzCoverage() {
    let bounded = ButterflyValidation.spinDegrees(duration: 2, spinSpeed: 1, velocity: 100, enableFlickPhysics: true)
    #expect(bounded.isFinite)
    #expect(bounded >= 180)

    let outBound = ButterflyValidation.spinDegrees(duration: -99, spinSpeed: -99, velocity: -99, enableFlickPhysics: true)
    #expect(outBound >= 180)
    #expect(outBound.isFinite)

    let invalid = ButterflyValidation.spinDegrees(duration: .nan, spinSpeed: .infinity, velocity: .nan, enableFlickPhysics: true)
    #expect(invalid >= 180)
    #expect(invalid.isFinite)

    let overload = ButterflyValidation.spinDegrees(for: 300, enableFlickPhysics: true)
    #expect(overload >= 180)
    #expect(overload.isFinite)

    var rng = DeterministicRNG(seed: 0x9999)
    for _ in 0..<500 {
        let duration = rng.nextDouble(in: -10...10)
        let speed = rng.nextDouble(in: -5...5)
        let velocity = CGFloat(rng.nextDouble(in: -2_000...2_000))
        let result = ButterflyValidation.spinDegrees(
            duration: duration,
            spinSpeed: speed,
            velocity: velocity,
            enableFlickPhysics: true
        )
        #expect(result.isFinite)
        #expect(result >= 180)
        #expect(result.truncatingRemainder(dividingBy: 360) == 180)
    }
}

/// Validates fitted-half-turn behavior for in-bound, out-of-bound, invalid, and fuzzed inputs.
@Test func fittedHalfTurns_hasBoundsInvalidAndFuzzCoverage() {
    #expect(
        ButterflyValidation.fittedHalfTurns(
            from: 1080,
            duration: 1.0,
            minimumSegmentDuration: 0.05
        ) > 0
    )

    let outBound = ButterflyValidation.fittedHalfTurns(
        from: -1_000,
        duration: -1.0,
        minimumSegmentDuration: -0.1
    )
    #expect(outBound >= 1)
    #expect(outBound % 2 == 1)

    let invalid = ButterflyValidation.fittedHalfTurns(
        from: .nan,
        duration: .nan,
        minimumSegmentDuration: .nan
    )
    #expect(invalid >= 1)
    #expect(invalid % 2 == 1)

    var rng = DeterministicRNG(seed: 0xDEADBEEF)
    for _ in 0..<500 {
        let degrees = rng.nextDouble(in: -100_000...100_000)
        let duration = rng.nextDouble(in: -10...10)
        let minimum = rng.nextDouble(in: -1...1)
        let result = ButterflyValidation.fittedHalfTurns(
            from: degrees,
            duration: duration,
            minimumSegmentDuration: minimum
        )
        #expect(result >= 1)
        #expect(result % 2 == 1)
    }
}

/// Validates rotation-state helpers for in-bound, out-of-bound, invalid, and fuzzed inputs.
@Test func rotationStateHelpers_haveBoundsInvalidAndFuzzCoverage() {
    #expect(ButterflyValidation.visibleTopFace(rotationDegrees: 0))
    #expect(!ButterflyValidation.visibleTopFace(rotationDegrees: 180))
    #expect(ButterflyValidation.baselineRotationDegrees(for: true) == 0)
    #expect(ButterflyValidation.baselineRotationDegrees(for: false) == 180)

    let huge = ButterflyValidation.snappedStopRotationDegrees(current: 1_000_000, isOn: false)
    #expect(huge.isFinite)
    #expect(!ButterflyValidation.visibleTopFace(rotationDegrees: huge))

    #expect(ButterflyValidation.visibleTopFace(rotationDegrees: .nan))
    #expect(ButterflyValidation.snappedStopRotationDegrees(current: .nan, isOn: true) == 0)

    var rng = DeterministicRNG(seed: 0xABCD)
    for _ in 0..<500 {
        let current = rng.nextDouble(in: -100_000...100_000)
        let onSnap = ButterflyValidation.snappedStopRotationDegrees(current: current, isOn: true)
        let offSnap = ButterflyValidation.snappedStopRotationDegrees(current: current, isOn: false)
        #expect(ButterflyValidation.visibleTopFace(rotationDegrees: onSnap))
        #expect(!ButterflyValidation.visibleTopFace(rotationDegrees: offSnap))
    }
}

/// Validates mode/axis mapping for all supported values.
@Test func animationModeAndRotationAxis_haveExhaustiveExpectedMappings() {
    #expect(ButterflyAnimationMode.from(reduceMotion: true) == .reducedMotion)
    #expect(ButterflyAnimationMode.from(reduceMotion: false) == .spin)

    let expectedH = ButterflyRotationAxis(x: 1, y: 0, z: 0)
    let expectedV = ButterflyRotationAxis(x: 0, y: 1, z: 0)
    let expectedLTR = ButterflyRotationAxis(x: 1, y: 1, z: 0)
    let expectedRTL = ButterflyRotationAxis(x: 1, y: -1, z: 0)

    #expect(ButterflyValidation.rotationAxis(for: .horizontal) == expectedH)
    #expect(ButterflyValidation.rotationAxis(for: .vertical) == expectedV)
    #expect(ButterflyValidation.rotationAxis(for: .diagonalLTR) == expectedLTR)
    #expect(ButterflyValidation.rotationAxis(for: .diagonalRTL) == expectedRTL)
}

/// Validates coordinator behavior for in-bound, out-of-bound, expected handling, and fuzzed sequences.
@Test func interactionCoordinator_hasBoundsInvalidAndFuzzCoverage() {
    var coordinator = ButterflyInteractionCoordinator()
    coordinator.initialize(isOn: true)

    let t1 = coordinator.beginSpin()
    let t2 = coordinator.beginSpin()
    #expect(!coordinator.isCurrentSpinToken(t1))
    #expect(coordinator.isCurrentSpinToken(t2))

    #expect(!coordinator.isCurrentSpinToken(.max))

    coordinator.markInternalToggle()
    #expect(coordinator.actionForExternalStateChange(newValue: false, isEnabled: true) == .none)
    #expect(coordinator.actionForExternalStateChange(newValue: true, isEnabled: true) == .animate(sign: -1.0))
    #expect(coordinator.actionForExternalStateChange(newValue: false, isEnabled: false) == .none)

    var rng = DeterministicRNG(seed: 0xF00D)
    coordinator.initialize(isOn: false)
    for _ in 0..<500 {
        let enabled = (rng.nextUInt64() & 1) == 1
        let newValue = (rng.nextUInt64() & 1) == 1
        let action = coordinator.actionForExternalStateChange(newValue: newValue, isEnabled: enabled)
        if case .animate = action {
            #expect(enabled)
        }
    }
}

