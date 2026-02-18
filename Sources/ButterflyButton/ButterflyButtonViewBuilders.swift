import SwiftUI

/// Static view builders to keep ButterflyButton body concise.
enum ButterflyButtonViewBuilders {
    static func mountLayer(sideLength: CGFloat,
                           strokeWidth: CGFloat,
                           strokeColor: Color,
                           background: MountBackground,
                           systemBackground: Color,
                           reduceTransparencyEnabled: Bool) -> some View {
        MountView(
            sideLength: sideLength,
            strokeWidth: strokeWidth,
            strokeColor: strokeColor,
            background: background,
            systemBackground: systemBackground,
            reduceTransparencyEnabled: reduceTransparencyEnabled
        )
    }

    static func axleLayer(sideLength: CGFloat,
                          strokeWidth: CGFloat,
                          orientation: AxleOrientation,
                          color: Color) -> some View {
        AxleView(
            sideLength: sideLength,
            strokeWidth: strokeWidth,
            orientation: orientation,
            color: color
        )
    }

    static func medallionLayer(diameter: CGFloat,
                               strokeWidth: CGFloat,
                               topColor: Color,
                               bottomColor: Color,
                               edgeColor: Color,
                               topImage: Image?,
                               bottomImage: Image?,
                               topLabel: LocalizedStringKey,
                               bottomLabel: LocalizedStringKey,
                               labelFont: Font,
                               labelColor: Color,
                               shape: MedallionShape,
                               rotationDegrees: Double,
                               rotationAxis: ButterflyRotationAxis,
                               scale: CGFloat) -> some View {
        MedallionView(
            diameter: diameter,
            strokeWidth: strokeWidth,
            topColor: topColor,
            bottomColor: bottomColor,
            edgeColor: edgeColor,
            topImage: topImage,
            bottomImage: bottomImage,
            topLabel: topLabel,
            bottomLabel: bottomLabel,
            labelFont: labelFont,
            labelColor: labelColor,
            shape: shape,
            rotationDegrees: rotationDegrees,
            rotationAxis: rotationAxis
        )
        .scaleEffect(scale)
    }
}
