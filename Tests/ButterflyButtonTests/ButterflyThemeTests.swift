// Copyright 2026 John Salerno.

import SwiftUI
import Testing
@testable import ButterflyButton

// MARK: - ThemeInput convenience init

/// Verifies the convenience init forwards all six color fields from a style.
@Test func themeInputConvenienceInit_mapsAllColorFieldsFromStyle() {
    let style = ButterflyButtonStyle(
        mountStrokeColor: .red,
        axleColor: .blue,
        medallionTopColor: .green,
        medallionBottomColor: .yellow,
        medallionEdgeColor: .orange,
        medallionLabelColor: .purple
    )
    let input = ThemeInput(
        style: style,
        colorScheme: .light,
        contrast: .standard,
        isEnabled: true
    )

    #expect(input.colorScheme == .light)
    #expect(input.contrast == .standard)
    #expect(input.isEnabled == true)
    #expect(input.mountStrokeColor == .red)
    #expect(input.axleColor == .blue)
    #expect(input.medallionTopColor == .green)
    #expect(input.medallionBottomColor == .yellow)
    #expect(input.medallionEdgeColor == .orange)
    #expect(input.medallionLabelColor == .purple)
}

/// Verifies the convenience init forwards nil color overrides correctly.
@Test func themeInputConvenienceInit_forwardsNilColors() {
    let style = ButterflyButtonStyle()
    let input = ThemeInput(
        style: style,
        colorScheme: .dark,
        contrast: .increased,
        isEnabled: false
    )

    #expect(input.colorScheme == .dark)
    #expect(input.contrast == .increased)
    #expect(input.isEnabled == false)
    #expect(input.mountStrokeColor == nil)
    #expect(input.axleColor == nil)
    #expect(input.medallionTopColor == nil)
    #expect(input.medallionBottomColor == nil)
    #expect(input.medallionEdgeColor == nil)
    #expect(input.medallionLabelColor == nil)
}

/// Regression: the memberwise init must still work after the convenience init exists.
/// This catches the bug where placing the convenience init inside the struct body
/// suppresses the auto-generated memberwise initializer.
@Test func themeInputMemberwiseInit_stillWorksAlongsideConvenienceInit() {
    let input = ThemeInput(
        colorScheme: .light,
        contrast: .standard,
        isEnabled: true,
        mountStrokeColor: .red,
        axleColor: .blue,
        medallionTopColor: .green,
        medallionBottomColor: .yellow,
        medallionEdgeColor: .orange,
        medallionLabelColor: .purple
    )

    #expect(input.mountStrokeColor == .red)
    #expect(input.axleColor == .blue)
}

// MARK: - ButterflyTheme.resolve — disabled path

/// Disabled state always enters the disabled path, ignoring color overrides.
@Test func themeResolve_disabledIgnoresColorOverrides() {
    let input = ThemeInput(
        colorScheme: .light,
        contrast: .standard,
        isEnabled: false,
        mountStrokeColor: .red,
        axleColor: .blue,
        medallionTopColor: .green,
        medallionBottomColor: .yellow,
        medallionEdgeColor: .orange,
        medallionLabelColor: .purple
    )
    let theme = ButterflyTheme.resolve(input)

    // Disabled theme uses .gray/.secondary/.white opacities — NOT the overrides.
    // We can't compare Color equality directly, but we verify the disabled code
    // path is entered by confirming the result differs from enabled.
    let enabledInput = ThemeInput(
        colorScheme: .light,
        contrast: .standard,
        isEnabled: true,
        mountStrokeColor: .red,
        axleColor: .blue,
        medallionTopColor: .green,
        medallionBottomColor: .yellow,
        medallionEdgeColor: .orange,
        medallionLabelColor: .purple
    )
    let enabledTheme = ButterflyTheme.resolve(enabledInput)

    // The disabled theme must differ from the enabled theme on at least one property.
    // medallionTop is .gray.opacity(0.45) disabled vs .green enabled — definitely different.
    #expect(theme.medallionTop != enabledTheme.medallionTop)
}

/// Disabled state produces the same theme regardless of color scheme or contrast.
@Test func themeResolve_disabledIsConsistentAcrossSchemes() {
    let lightStandard = ButterflyTheme.resolve(ThemeInput(
        colorScheme: .light, contrast: .standard, isEnabled: false,
        mountStrokeColor: nil, axleColor: nil, medallionTopColor: nil,
        medallionBottomColor: nil, medallionEdgeColor: nil, medallionLabelColor: nil
    ))
    let darkIncreased = ButterflyTheme.resolve(ThemeInput(
        colorScheme: .dark, contrast: .increased, isEnabled: false,
        mountStrokeColor: nil, axleColor: nil, medallionTopColor: nil,
        medallionBottomColor: nil, medallionEdgeColor: nil, medallionLabelColor: nil
    ))

    // Disabled path ignores contrast and scheme for most colors.
    #expect(lightStandard.medallionTop == darkIncreased.medallionTop)
    #expect(lightStandard.medallionBottom == darkIncreased.medallionBottom)
    #expect(lightStandard.medallionLabel == darkIncreased.medallionLabel)
    #expect(lightStandard.axle == darkIncreased.axle)
    #expect(lightStandard.mountStroke == darkIncreased.mountStroke)
}

// MARK: - ButterflyTheme.resolve — enabled, color overrides vs defaults

/// When color overrides are provided, they pass through to the resolved theme.
@Test func themeResolve_enabledColorOverridesPassThrough() {
    let input = ThemeInput(
        colorScheme: .light,
        contrast: .standard,
        isEnabled: true,
        mountStrokeColor: .red,
        axleColor: .blue,
        medallionTopColor: .green,
        medallionBottomColor: .yellow,
        medallionEdgeColor: .orange,
        medallionLabelColor: .purple
    )
    let theme = ButterflyTheme.resolve(input)

    #expect(theme.medallionTop == .green)
    #expect(theme.medallionBottom == .yellow)
    #expect(theme.medallionLabel == .purple)

    // mountStroke and axle use the override in standard contrast.
    #expect(theme.mountStroke == .red)
    #expect(theme.axle == .blue)
}

/// When no color overrides are provided, defaults are used.
@Test func themeResolve_enabledNilColorsFallBackToDefaults() {
    let input = ThemeInput(
        colorScheme: .light,
        contrast: .standard,
        isEnabled: true,
        mountStrokeColor: nil,
        axleColor: nil,
        medallionTopColor: nil,
        medallionBottomColor: nil,
        medallionEdgeColor: nil,
        medallionLabelColor: nil
    )
    let theme = ButterflyTheme.resolve(input)

    // Defaults are .accentColor, .secondary, .primary etc.
    #expect(theme.medallionLabel == .primary)
}

// MARK: - ButterflyTheme.resolve — high contrast

/// High contrast overrides mountStroke and axle to .primary regardless of style overrides.
@Test func themeResolve_highContrastForcesPrimaryForStrokeAndAxle() {
    let input = ThemeInput(
        colorScheme: .light,
        contrast: .increased,
        isEnabled: true,
        mountStrokeColor: .red,
        axleColor: .blue,
        medallionTopColor: nil,
        medallionBottomColor: nil,
        medallionEdgeColor: nil,
        medallionLabelColor: nil
    )
    let theme = ButterflyTheme.resolve(input)

    #expect(theme.mountStroke == .primary)
    #expect(theme.axle == .primary)
}

/// Standard contrast uses the override color for mountStroke and axle.
@Test func themeResolve_standardContrastUsesOverrideColors() {
    let input = ThemeInput(
        colorScheme: .light,
        contrast: .standard,
        isEnabled: true,
        mountStrokeColor: .red,
        axleColor: .blue,
        medallionTopColor: nil,
        medallionBottomColor: nil,
        medallionEdgeColor: nil,
        medallionLabelColor: nil
    )
    let theme = ButterflyTheme.resolve(input)

    #expect(theme.mountStroke == .red)
    #expect(theme.axle == .blue)
}

// MARK: - ButterflyTheme.resolve — dark vs light background

/// Dark scheme produces a different mount background than light scheme.
@Test func themeResolve_darkAndLightSchemesProduceDifferentBackgrounds() {
    let dark = ButterflyTheme.resolve(ThemeInput(
        colorScheme: .dark, contrast: .standard, isEnabled: true,
        mountStrokeColor: nil, axleColor: nil, medallionTopColor: nil,
        medallionBottomColor: nil, medallionEdgeColor: nil, medallionLabelColor: nil
    ))
    let light = ButterflyTheme.resolve(ThemeInput(
        colorScheme: .light, contrast: .standard, isEnabled: true,
        mountStrokeColor: nil, axleColor: nil, medallionTopColor: nil,
        medallionBottomColor: nil, medallionEdgeColor: nil, medallionLabelColor: nil
    ))

    #expect(dark.mountBackground != light.mountBackground)
}

// MARK: - PreviewConstants match internal Constants

/// Ensures PreviewConstants stay in sync with internal Constants.
@Test func previewConstantsMatchInternalConstants() {
    #expect(ButterflyTheme.PreviewConstants.DARK_MOUNT_BACKGROUND_OPACITY == 0.08)
    #expect(ButterflyTheme.PreviewConstants.LIGHT_MOUNT_BACKGROUND_OPACITY == 0.04)
    #expect(ButterflyTheme.PreviewConstants.DISABLED_OPACITY == 0.09)
}

// MARK: - High contrast medallion edge opacity

/// High contrast produces full-opacity medallion edge; standard contrast uses reduced opacity.
@Test func themeResolve_medallionEdgeOpacityDiffersWithContrast() {
    let standard = ButterflyTheme.resolve(ThemeInput(
        colorScheme: .light, contrast: .standard, isEnabled: true,
        mountStrokeColor: nil, axleColor: nil, medallionTopColor: nil,
        medallionBottomColor: nil, medallionEdgeColor: nil, medallionLabelColor: nil
    ))
    let high = ButterflyTheme.resolve(ThemeInput(
        colorScheme: .light, contrast: .increased, isEnabled: true,
        mountStrokeColor: nil, axleColor: nil, medallionTopColor: nil,
        medallionBottomColor: nil, medallionEdgeColor: nil, medallionLabelColor: nil
    ))

    // Standard uses .primary.opacity(0.7); high contrast uses .primary at full opacity.
    #expect(standard.medallionEdge != high.medallionEdge)
}
