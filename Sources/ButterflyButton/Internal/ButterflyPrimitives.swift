// Copyright 2026 John Salerno.

import SwiftUI
import OSLog
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
private typealias PlatformImage = NSImage
#elseif canImport(UIKit)
private typealias PlatformImage = UIImage
#endif

/// Renders the square mount behind the medallion.
struct MountView: View {
    let sideLength: CGFloat
    let strokeWidth: CGFloat
    let strokeColor: Color
    let background: MountBackground
    let systemBackground: Color

    var body: some View {
        ZStack {
            backgroundView
            Rectangle()
                .stroke(strokeColor, lineWidth: strokeWidth)
        }
        .frame(width: sideLength, height: sideLength)
    }

    /// Produces the mount background based on `MountBackground`.
    @ViewBuilder
    private var backgroundView: some View {
        switch background {
        case .systemAutomatic:
            Rectangle().fill(systemBackground)
        case .transparent:
            Rectangle().fill(.clear)
        case let .color(color):
            Rectangle().fill(color)
        case let .image(image):
            image
                .resizable()
                .scaledToFill()
                .clipped()
        }
    }
}

/// Draws the axle line for a given orientation.
struct AxleView: View {
    let sideLength: CGFloat
    let strokeWidth: CGFloat
    let orientation: AxleOrientation
    let color: Color

    var body: some View {
        Canvas { context, size in
            var path = Path()
            switch orientation {
            case .horizontal:
                path.move(to: CGPoint(x: 0, y: size.height / 2))
                path.addLine(to: CGPoint(x: size.width, y: size.height / 2))
            case .vertical:
                path.move(to: CGPoint(x: size.width / 2, y: 0))
                path.addLine(to: CGPoint(x: size.width / 2, y: size.height))
            case .diagonalLTR:
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: size.width, y: size.height))
            case .diagonalRTL:
                path.move(to: CGPoint(x: size.width, y: 0))
                path.addLine(to: CGPoint(x: 0, y: size.height))
            }

            context.stroke(path, with: .color(color), lineWidth: strokeWidth)
        }
        .frame(width: sideLength, height: sideLength)
        .allowsHitTesting(false)
    }
}

/// Renders the spinning medallion face, label, and border.
struct MedallionView: View {
    let diameter: CGFloat
    let strokeWidth: CGFloat
    let topColor: Color
    let bottomColor: Color
    let edgeColor: Color
    let topImage: Image?
    let bottomImage: Image?
    let topLabel: LocalizedStringKey
    let bottomLabel: LocalizedStringKey
    let labelFont: Font
    let labelColor: Color
    let shape: MedallionShape
    let rotationDegrees: Double
    let rotationAxis: ButterflyRotationAxis

    var body: some View {
        let visibleTop = ButterflyValidation.visibleTopFace(rotationDegrees: rotationDegrees)
        let faceSource = medallionFaceSource(visibleTop: visibleTop)

        ZStack {
            if shape == .square {
                Rectangle()
                    .fill(backgroundColor(visibleTop: visibleTop, faceSource: faceSource))
            } else {
                Circle()
                    .fill(backgroundColor(visibleTop: visibleTop, faceSource: faceSource))
            }

            switch faceSource {
            case let .image(image, isDefaultStone):
                if shape == .square {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: diameter, height: diameter)
                        .scaleEffect(isDefaultStone ? 2.0 : 1.0)
                        .clipShape(Rectangle())
                } else {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: diameter, height: diameter)
                        .scaleEffect(isDefaultStone ? 2.0 : 1.0)
                        .clipShape(Circle())
                }
            case .colorFallback:
                if !visibleTop {
                    Image(systemName: "xmark")
                        .resizable()
                        .scaledToFit()
                        .padding(diameter * 0.30)
                        .foregroundStyle(.white)
                }
            }

            Text(visibleTop ? topLabel : bottomLabel)
                .font(labelFont)
                .foregroundStyle(labelColor)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(6)

            if shape == .square {
                Rectangle().stroke(edgeColor, lineWidth: strokeWidth)
            } else {
                Circle().stroke(edgeColor, lineWidth: strokeWidth)
            }
        }
        .frame(width: diameter, height: diameter)
        .rotation3DEffect(
            .degrees(rotationDegrees),
            axis: (x: rotationAxis.x, y: rotationAxis.y, z: rotationAxis.z),
            perspective: 0.75
        )
    }

    private enum FaceSource {
        case image(Image, isDefaultStone: Bool)
        case colorFallback
    }

    /// Chooses the image/color source for the currently visible face.
    ///
    /// - Parameter visibleTop: Whether top face is currently visible.
    /// - Returns: Face source for rendering.
    private func medallionFaceSource(visibleTop: Bool) -> FaceSource {
        if let custom = (visibleTop ? topImage : bottomImage) {
            return .image(custom, isDefaultStone: false)
        }
        if let bundleDefault = defaultStoneImage(visibleTop: visibleTop, shape: shape) {
            return .image(bundleDefault, isDefaultStone: true)
        }
        return .colorFallback
    }

    /// Resolves the medallion fill color for the active face source.
    ///
    /// - Parameters:
    ///   - visibleTop: Whether top face is currently visible.
    ///   - faceSource: Selected face source.
    /// - Returns: Background color used for rendering.
    private func backgroundColor(visibleTop: Bool, faceSource: FaceSource) -> Color {
        switch faceSource {
        case .image:
            return visibleTop ? topColor : bottomColor
        case .colorFallback:
            return visibleTop ? .orange : .purple
        }
    }

    /// Loads the default bundled stone image for a face and shape.
    ///
    /// - Parameters:
    ///   - visibleTop: Whether top face is currently visible.
    ///   - shape: Active medallion shape.
    /// - Returns: Default face image when available.
    private func defaultStoneImage(visibleTop: Bool, shape: MedallionShape) -> Image? {
        let candidateNames: [String]
        switch shape {
        case .square:
            candidateNames = visibleTop
                ? ["square-white-stone-64", "square-white-stone-128"]
                : ["square-black-stone-64", "square-black-stone-128"]
        case .circle:
            candidateNames = visibleTop
                ? ["white-stone-64", "white-stone-128"]
                : ["black-stone-64", "black-stone-128"]
        }

        for name in candidateNames {
            #if canImport(AppKit)
            if let image = DefaultStoneImageCache.image(named: name) {
                return Image(nsImage: image)
            }
            #elseif canImport(UIKit)
            if let image = DefaultStoneImageCache.image(named: name) {
                return Image(uiImage: image)
            }
            #endif
        }
        return nil
    }
}

private enum DefaultStoneImageCache {
    private static let logger = Logger(subsystem: "com.integracode.ButterfylButton", category: "resources")

    private static let names = [
        "white-stone-64",
        "white-stone-128",
        "black-stone-64",
        "black-stone-128",
        "square-white-stone-64",
        "square-white-stone-128",
        "square-black-stone-64",
        "square-black-stone-128"
    ]

    static let loaded: [String: PlatformImage] = {
        var images: [String: PlatformImage] = [:]
        for name in names {
            guard let url = Bundle.module.url(forResource: name, withExtension: "png") else {
                logger.error("Missing bundled resource: \(name, privacy: .public).png")
                continue
            }
            #if canImport(AppKit)
            if let image = NSImage(contentsOf: url) {
                images[name] = image
            } else {
                logger.error("Failed to load bundled resource at path: \(url.path, privacy: .public)")
            }
            #elseif canImport(UIKit)
            if let image = UIImage(contentsOfFile: url.path) {
                images[name] = image
            } else {
                logger.error("Failed to load bundled resource at path: \(url.path, privacy: .public)")
            }
            #endif
        }
        return images
    }()

    /// Returns a cached bundled image by resource name.
    ///
    /// - Parameter name: Resource base name without extension.
    /// - Returns: Cached platform image when available.
    static func image(named name: String) -> PlatformImage? {
        loaded[name]
    }
}

/// Places an optional outer label around the mount content.
struct OuterLabelView<Mount: View>: View {
    let sideLength: CGFloat
    let labelPadding: CGFloat
    let placement: LabelPlacement
    let effectiveRTL: Bool
    let label: AnyView?
    let mount: Mount

    var body: some View {
        switch resolvedPlacement {
        case .top:
            VStack(spacing: labelPadding) {
                labelView
                mount
            }
        case .bottom:
            VStack(spacing: labelPadding) {
                mount
                labelView
            }
        case .leading:
            HStack(spacing: labelPadding) {
                labelView
                mount
            }
        case .trailing:
            HStack(spacing: labelPadding) {
                mount
                labelView
            }
        case .auto:
            EmptyView()
        }
    }

    private var resolvedPlacement: LabelPlacement {
        if placement != .auto { return placement }
        return effectiveRTL ? .trailing : .leading
    }

    @ViewBuilder
    private var labelView: some View {
        if let label {
            label
        }
    }
}
