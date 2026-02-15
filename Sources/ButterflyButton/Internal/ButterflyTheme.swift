// Copyright 2026 John Salerno.

import SwiftUI

/// Resolved color values used by `ButterflyButton` rendering primitives.
struct ButterflyTheme {
    let mountStroke: Color
    let mountBackground: Color
    let axle: Color
    let medallionTop: Color
    let medallionBottom: Color
    let medallionEdge: Color
    let medallionLabel: Color

    /// Resolves theme colors from environment and style overrides.
    ///
    /// - Parameters:
    ///   - colorScheme: Current color scheme.
    ///   - contrast: Current contrast setting.
    ///   - isEnabled: Whether control is enabled.
    ///   - mountStrokeColor: Optional mount stroke override.
    ///   - axleColor: Optional axle color override.
    ///   - medallionTopColor: Optional top-face color override.
    ///   - medallionBottomColor: Optional bottom-face color override.
    ///   - medallionEdgeColor: Optional medallion edge color override.
    ///   - medallionLabelColor: Optional medallion label color override.
    /// - Returns: Resolved theme colors.
    static func resolve(
        colorScheme: ColorScheme,
        contrast: ColorSchemeContrast,
        isEnabled: Bool,
        mountStrokeColor: Color?,
        axleColor: Color?,
        medallionTopColor: Color?,
        medallionBottomColor: Color?,
        medallionEdgeColor: Color?,
        medallionLabelColor: Color?
    ) -> Self {
        if !isEnabled {
            return Self.disabled(colorScheme: colorScheme)
        }

        let highContrast = contrast == .increased
        let baseStroke = mountStrokeColor ?? .secondary
        let baseAxle = axleColor ?? .accentColor

        return Self(
            mountStroke: highContrast ? .primary : baseStroke,
            mountBackground: colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04),
            axle: highContrast ? .primary : baseAxle,
            medallionTop: medallionTopColor ?? .accentColor,
            medallionBottom: medallionBottomColor ?? .secondary,
            medallionEdge: medallionEdgeColor ?? .primary.opacity(highContrast ? 1 : 0.7),
            medallionLabel: medallionLabelColor ?? .primary
        )
    }

    /// Returns disabled-state colors for the provided color scheme.
    ///
    /// - Parameter colorScheme: Current color scheme.
    /// - Returns: Theme values for disabled rendering.
    private static func disabled(colorScheme: ColorScheme) -> Self {
        let bg = colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.06)
        return Self(
            mountStroke: .secondary.opacity(0.6),
            mountBackground: bg,
            axle: .secondary.opacity(0.6),
            medallionTop: .gray.opacity(0.45),
            medallionBottom: .gray.opacity(0.65),
            medallionEdge: .secondary.opacity(0.7),
            medallionLabel: .white.opacity(0.85)
        )
    }
}
