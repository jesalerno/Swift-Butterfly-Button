// Copyright 2026 John Salerno.

import SwiftUI

public enum LabelPlacement: Sendable, Equatable {
    case top
    case bottom
    case leading
    case trailing
    case auto
}

public enum AxleOrientation: Sendable, Equatable {
    case horizontal
    case vertical
    case diagonalLTR
    case diagonalRTL
}

public enum MountBackground {
    case systemAutomatic
    case transparent
    case color(Color)
    case image(Image)
    case material(Material)
}

public enum SpinDirection: Sendable, Equatable {
    case topToBottom
    case bottomToTop
}

public enum MedallionShape: Sendable, Equatable {
    case circle
    case square
}

/// Configures appearance values used to render a `ButterflyButton`.
public struct ButterflyButtonStyle {
    public var mountStrokeColor: Color?
    public var mountStrokeWidth: CGFloat
    public var mountBackground: MountBackground
    public var axleOrientation: AxleOrientation
    public var axleColor: Color?
    public var medallionTopColor: Color?
    public var medallionBottomColor: Color?
    public var medallionEdgeColor: Color?
    public var medallionTopImage: Image?
    public var medallionBottomImage: Image?
    public var medallionTopLabel: LocalizedStringKey
    public var medallionBottomLabel: LocalizedStringKey
    public var medallionLabelFont: Font?
    public var medallionLabelColor: Color?
    public var medallionStrokeWidth: CGFloat
    public var medallionShape: MedallionShape

    /// Creates a style configuration for `ButterflyButton`.
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
        medallionShape: MedallionShape = .circle
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
