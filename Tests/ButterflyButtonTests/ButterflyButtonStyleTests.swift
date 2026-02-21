// Copyright 2026 John Salerno.

import SwiftUI
import Testing
@testable import ButterflyButton

// MARK: - Default values

/// Verifies the public API default values are stable contracts.
@Test func butterflyButtonStyle_hasExpectedDefaults() {
    let style = ButterflyButtonStyle()

    #expect(style.mountStrokeWidth == 2)
    #expect(style.medallionStrokeWidth == 2)
    #expect(style.medallionShape == .circle)
    #expect(style.axleOrientation == .horizontal)

    // Optional color overrides default to nil.
    #expect(style.mountStrokeColor == nil)
    #expect(style.axleColor == nil)
    #expect(style.medallionTopColor == nil)
    #expect(style.medallionBottomColor == nil)
    #expect(style.medallionEdgeColor == nil)
    #expect(style.medallionLabelColor == nil)
    #expect(style.medallionLabelFont == nil)
    #expect(style.medallionTopImage == nil)
    #expect(style.medallionBottomImage == nil)
}

// MARK: - Mutation

/// Verifies that style properties can be individually mutated.
@Test func butterflyButtonStyle_supportsIndividualPropertyMutation() {
    var style = ButterflyButtonStyle()

    style.mountStrokeWidth = 5
    #expect(style.mountStrokeWidth == 5)

    style.medallionShape = .square
    #expect(style.medallionShape == .square)

    style.axleOrientation = .diagonalLTR
    #expect(style.axleOrientation == .diagonalLTR)

    style.mountStrokeColor = .red
    #expect(style.mountStrokeColor == .red)
}

// MARK: - Custom init with all parameters

/// Verifies the full initializer stores every value correctly.
@Test func butterflyButtonStyle_fullInitStoresAllValues() {
    let style = ButterflyButtonStyle(
        mountStrokeColor: .red,
        mountStrokeWidth: 4,
        mountBackground: .transparent,
        axleOrientation: .vertical,
        axleColor: .blue,
        medallionTopColor: .green,
        medallionBottomColor: .yellow,
        medallionEdgeColor: .orange,
        medallionTopImage: nil,
        medallionBottomImage: nil,
        medallionTopLabel: "On",
        medallionBottomLabel: "Off",
        medallionLabelFont: .title,
        medallionLabelColor: .purple,
        medallionStrokeWidth: 3,
        medallionShape: .square
    )

    #expect(style.mountStrokeColor == .red)
    #expect(style.mountStrokeWidth == 4)
    #expect(style.axleOrientation == .vertical)
    #expect(style.axleColor == .blue)
    #expect(style.medallionTopColor == .green)
    #expect(style.medallionBottomColor == .yellow)
    #expect(style.medallionEdgeColor == .orange)
    #expect(style.medallionLabelColor == .purple)
    #expect(style.medallionStrokeWidth == 3)
    #expect(style.medallionShape == .square)
    #expect(style.medallionLabelFont == .title)
}

// MARK: - Enum cases exhaustiveness

/// Verifies MedallionShape has exactly the expected cases.
@Test func medallionShape_hasExpectedCases() {
    let allCases: [MedallionShape] = [.circle, .square]
    #expect(allCases.count == 2)
}

/// Verifies SpinDirection has exactly the expected cases.
@Test func spinDirection_hasExpectedCases() {
    let allCases: [SpinDirection] = [.topToBottom, .bottomToTop]
    #expect(allCases.count == 2)
}

/// Verifies AxleOrientation has exactly the expected cases.
@Test func axleOrientation_hasExpectedCases() {
    let allCases: [AxleOrientation] = [.horizontal, .vertical, .diagonalLTR, .diagonalRTL]
    #expect(allCases.count == 4)
}

/// Verifies LabelPlacement has exactly the expected cases.
@Test func labelPlacement_hasExpectedCases() {
    let allCases: [LabelPlacement] = [.top, .bottom, .leading, .trailing, .auto]
    #expect(allCases.count == 5)
}

// MARK: - Sendable conformance compile-time checks

/// Verifies MountBackground conforms to Sendable (compile-time check).
@Test func mountBackground_isSendable() {
    let _: any Sendable = MountBackground.systemAutomatic
    let _: any Sendable = MountBackground.transparent
    let _: any Sendable = MountBackground.color(.red)
}
