// Copyright 2026 John Salerno.

import SwiftUI

struct ThemeInput {
    let colorScheme: ColorScheme
    let contrast: ColorSchemeContrast
    let isEnabled: Bool
    let mountStrokeColor: Color?
    let axleColor: Color?
    let medallionTopColor: Color?
    let medallionBottomColor: Color?
    let medallionEdgeColor: Color?
    let medallionLabelColor: Color?
}

extension ThemeInput {
    /// Convenience initializer that extracts color overrides from a `ButterflyButtonStyle`.
    ///
    /// Defined in an extension so Swift preserves the auto-generated memberwise initializer.
    ///
    /// - Parameters:
    ///   - style: Style providing optional color overrides.
    ///   - colorScheme: Current environment color scheme.
    ///   - contrast: Current environment contrast level.
    ///   - isEnabled: Whether the control is enabled.
    init(style: ButterflyButtonStyle, colorScheme: ColorScheme, contrast: ColorSchemeContrast, isEnabled: Bool) {
        self.init(
            colorScheme: colorScheme,
            contrast: contrast,
            isEnabled: isEnabled,
            mountStrokeColor: style.mountStrokeColor,
            axleColor: style.axleColor,
            medallionTopColor: style.medallionTopColor,
            medallionBottomColor: style.medallionBottomColor,
            medallionEdgeColor: style.medallionEdgeColor,
            medallionLabelColor: style.medallionLabelColor
        )
    }
}

/// Resolved color values used by `ButterflyButton` rendering primitives.
struct ButterflyTheme {
    let mountStroke: Color
    let mountBackground: Color
    let axle: Color
    let medallionTop: Color
    let medallionBottom: Color
    let medallionEdge: Color
    let medallionLabel: Color

    // MARK: - Theme Constants
    /// Namespaced constants for `ButterflyTheme`.
    enum Constants {
        // MARK: Background
        /// Opacity for the mount background when the system is in Dark Mode.
        static let DARK_MOUNT_BACKGROUND_OPACITY: Double = 0.08
        /// Opacity for the mount background when the system is in Light Mode.
        static let LIGHT_MOUNT_BACKGROUND_OPACITY: Double = 0.04

        // MARK: Contrast
        /// Opacity for the medallion edge when not in increased contrast mode.
        static let MEDALLION_EDGE_LOW_CONTRAST_OPACITY: Double = 0.7

        // MARK: Disabled state
        /// Base opacity for disabled surfaces (HIG range 0.06–0.12).
        static let DISABLED_OPACITY: Double = 0.09
        /// Opacity for the mount stroke when disabled.
        static let DISABLED_STROKE_OPACITY: Double = 0.6
        /// Opacity for the axle when disabled.
        static let DISABLED_AXLE_OPACITY: Double = 0.09
        /// Opacity for the medallion top face when disabled.
        static let DISABLED_MEDALLION_TOP_OPACITY: Double = 0.45
        /// Opacity for the medallion bottom face when disabled.
        static let DISABLED_MEDALLION_BOTTOM_OPACITY: Double = 0.65
        /// Opacity for the medallion edge when disabled.
        static let DISABLED_MEDALLION_EDGE_OPACITY: Double = 0.7
        /// Opacity for the medallion label when disabled.
        static let DISABLED_MEDALLION_LABEL_OPACITY: Double = 0.85
    }

    // MARK: - Test/Preview Constants (exposed for testability)
    /// A small set of constants exposed for tests and previews.
    enum PreviewConstants {
        /// Opacity for the mount background in Dark Mode.
        static let DARK_MOUNT_BACKGROUND_OPACITY = Constants.DARK_MOUNT_BACKGROUND_OPACITY
        /// Opacity for the mount background in Light Mode.
        static let LIGHT_MOUNT_BACKGROUND_OPACITY = Constants.LIGHT_MOUNT_BACKGROUND_OPACITY
        /// Disabled base opacity for surfaces.
        static let DISABLED_OPACITY = Constants.DISABLED_OPACITY
    }

    /// Resolves theme colors from environment and style overrides.
    ///
    /// - Parameters:
    ///   - input: A `ThemeInput` struct containing environment and override parameters.
    /// - Returns: Resolved theme colors.
    static func resolve(_ input: ThemeInput) -> Self {
        if !input.isEnabled {
            return Self.disabled(colorScheme: input.colorScheme)
        }

        let highContrast = input.contrast == .increased
        let baseStroke = input.mountStrokeColor ?? .secondary
        let baseAxle = input.axleColor ?? .accentColor

        return Self(
            mountStroke: highContrast ? .primary : baseStroke,
            mountBackground: input.colorScheme == .dark
                ? Color.white.opacity(Constants.DARK_MOUNT_BACKGROUND_OPACITY)
                : Color.black.opacity(Constants.LIGHT_MOUNT_BACKGROUND_OPACITY),
            axle: highContrast ? .primary : baseAxle,
            medallionTop: input.medallionTopColor ?? .accentColor,
            medallionBottom: input.medallionBottomColor ?? .secondary,
            medallionEdge: input.medallionEdgeColor ?? .primary.opacity(highContrast ? 1 : Constants.MEDALLION_EDGE_LOW_CONTRAST_OPACITY),
            medallionLabel: input.medallionLabelColor ?? .primary
        )
    }

    /// Returns disabled-state colors for the provided color scheme.
    ///
    /// - Parameter colorScheme: Current color scheme.
    /// - Returns: Theme values for disabled rendering.
    private static func disabled(colorScheme: ColorScheme) -> Self {
        let background = Color.secondary.opacity(Constants.DISABLED_OPACITY)
        return Self(
            mountStroke: .secondary.opacity(Constants.DISABLED_STROKE_OPACITY),
            mountBackground: background,
            axle: .secondary.opacity(Constants.DISABLED_AXLE_OPACITY),
            medallionTop: .gray.opacity(Constants.DISABLED_MEDALLION_TOP_OPACITY),
            medallionBottom: .gray.opacity(Constants.DISABLED_MEDALLION_BOTTOM_OPACITY),
            medallionEdge: .secondary.opacity(Constants.DISABLED_MEDALLION_EDGE_OPACITY),
            medallionLabel: .white.opacity(Constants.DISABLED_MEDALLION_LABEL_OPACITY)
        )
    }
}

