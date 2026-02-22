// Copyright 2026 John Salerno.

import SwiftUI

/// Describes where to place an optional label relative to the control.
///
/// Use `.auto` to resolve to leading/trailing based on the current layout direction.
public enum LabelPlacement: Sendable, Equatable {
    /// Place the label above the control.
    case top
    /// Place the label below the control.
    case bottom
    /// Place the label on the leading edge (mirrors in RTL).
    case leading
    /// Place the label on the trailing edge (mirrors in RTL).
    case trailing
    /// Resolve placement automatically based on layout direction.
    case auto
}

/// Orientation of the axle used to determine the medallion's rotation axis.
public enum AxleOrientation: Sendable, Equatable {
    /// Horizontal axle (rotates around the X axis).
    case horizontal
    /// Vertical axle (rotates around the Y axis).
    case vertical
    /// Diagonal from leading-to-trailing (rotates around a 45° axis).
    case diagonalLTR
    /// Diagonal from trailing-to-leading (rotates around a -45° axis).
    case diagonalRTL
}

/// Background rendering mode for the square mount behind the medallion.
public enum MountBackground: Sendable {
    /// Uses an adaptive system background color.
    case systemAutomatic
    /// Draws a fully transparent background.
    case transparent
    /// Fills with a specific color.
    case color(Color)
    /// Uses an image, scaled to fill and clipped to the square.
    case image(Image)
    /// Uses a system material; falls back to an opaque color when Reduce Transparency is enabled.
    case material(Material)
}

/// Direction inferred from a drag gesture used to determine spin sign.
public enum SpinDirection: Sendable, Equatable {
    /// Drag from top to bottom; yields a positive spin sign.
    case topToBottom
    /// Drag from bottom to top; yields a negative spin sign.
    case bottomToTop
}

/// Shape of the medallion face and border.
public enum MedallionShape: Sendable, Equatable {
    /// Circular medallion.
    case circle
    /// Square medallion.
    case square
}

/// Configures the visual appearance of a `ButterflyButton`.
///
/// The style controls mount border, background, axle orientation, medallion colors/images,
/// labels, and stroke widths. Provide nil values to accept adaptive defaults.
public struct ButterflyButtonStyle {
    /// Optional color for the mount border; falls back to a semantic default.
    public var mountStrokeColor: Color?
    /// Width of the mount border, in points.
    public var mountStrokeWidth: CGFloat
    /// Background mode for the square mount.
    public var mountBackground: MountBackground
    /// Orientation of the axle/rotation axis.
    public var axleOrientation: AxleOrientation
    /// Optional color for the axle line; defaults to accent color.
    public var axleColor: Color?
    /// Optional fallback color for the top face when no image is provided.
    public var medallionTopColor: Color?
    /// Optional fallback color for the bottom face when no image is provided.
    public var medallionBottomColor: Color?
    /// Optional color for the medallion border stroke.
    public var medallionEdgeColor: Color?
    /// Optional image for the top face of the medallion.
    public var medallionTopImage: Image?
    /// Optional image for the bottom face of the medallion.
    public var medallionBottomImage: Image?
    /// Localized label displayed on the top face.
    public var medallionTopLabel: LocalizedStringKey
    /// Localized label displayed on the bottom face.
    public var medallionBottomLabel: LocalizedStringKey
    /// Optional font for medallion labels; defaults to `.caption`.
    public var medallionLabelFont: Font?
    /// Optional color for medallion labels; defaults to a semantic color.
    public var medallionLabelColor: Color?
    /// Border stroke width for the medallion, in points.
    public var medallionStrokeWidth: CGFloat
    /// Shape of the medallion (circle or square).
    public var medallionShape: MedallionShape

    /// Creates a style configuration for `ButterflyButton`.
    ///
    /// Nil values allow the theme to choose adaptive defaults based on color scheme and contrast.
    ///
    /// - Parameters:
    ///   - mountStrokeColor: Optional mount border color.
    ///   - mountStrokeWidth: Mount border width.
    ///   - mountBackground: Mount background rendering mode.
    ///   - axleOrientation: Axis orientation used for medallion rotation.
    ///   - axleColor: Optional axle color.
    ///   - medallionTopColor: Optional top-face fallback color.
    ///   - medallionBottomColor: Optional bottom-face fallback color.
    ///   - medallionEdgeColor: Optional medallion border color.
    ///   - medallionTopImage: Optional top-face image.
    ///   - medallionBottomImage: Optional bottom-face image.
    ///   - medallionTopLabel: Top-face localized label.
    ///   - medallionBottomLabel: Bottom-face localized label.
    ///   - medallionLabelFont: Optional label font.
    ///   - medallionLabelColor: Optional label color.
    ///   - medallionStrokeWidth: Medallion border width.
    ///   - medallionShape: Medallion shape.
    public init(
        mountStrokeColor: Color? = nil,
        mountStrokeWidth: CGFloat = 2,
        mountBackground: MountBackground = .systemAutomatic,
        axleOrientation: AxleOrientation = .horizontal,
        axleColor: Color? = nil,
        medallionTopColor: Color? = nil,
        medallionBottomColor: Color? = nil,
        medallionEdgeColor: Color? = nil,
        medallionTopImage: Image? = nil,
        medallionBottomImage: Image? = nil,
        medallionTopLabel: LocalizedStringKey = "ButterflyButton.true",
        medallionBottomLabel: LocalizedStringKey = "ButterflyButton.false",
        medallionLabelFont: Font? = nil,
        medallionLabelColor: Color? = nil,
        medallionStrokeWidth: CGFloat = 2,
        medallionShape: MedallionShape = .circle,
    ) {
        self.mountStrokeColor = mountStrokeColor
        self.mountStrokeWidth = mountStrokeWidth
        self.mountBackground = mountBackground
        self.axleOrientation = axleOrientation
        self.axleColor = axleColor
        self.medallionTopColor = medallionTopColor
        self.medallionBottomColor = medallionBottomColor
        self.medallionEdgeColor = medallionEdgeColor
        self.medallionTopImage = medallionTopImage
        self.medallionBottomImage = medallionBottomImage
        self.medallionTopLabel = medallionTopLabel
        self.medallionBottomLabel = medallionBottomLabel
        self.medallionLabelFont = medallionLabelFont
        self.medallionLabelColor = medallionLabelColor
        self.medallionStrokeWidth = medallionStrokeWidth
        self.medallionShape = medallionShape
    }
}
