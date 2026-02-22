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

/// Renders the square mount behind the medallion, including background and border.
///
/// This is an internal rendering primitive; it is not part of the public API surface.
struct MountView: View {
    /// Side length for the square mount.
    let sideLength: CGFloat
    /// Border stroke width for the mount.
    let strokeWidth: CGFloat
    /// Color used to draw the mount border.
    let strokeColor: Color
    /// Background rendering mode for the mount.
    let background: MountBackground
    /// System background color used when `.systemAutomatic` or as opaque fallback.
    let systemBackground: Color
    /// Whether Reduce Transparency is enabled (forces opaque fallback).
    let reduceTransparencyEnabled: Bool

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
        case let .material(material):
            if reduceTransparencyEnabled {
                Rectangle().fill(systemBackground) // opaque fallback per HIG
            } else {
                Rectangle().fill(material)
            }
        case let .image(image):
            image
                .resizable()
                .scaledToFill()
                .clipped()
        }
    }
}

/// Draws the axle line for a given orientation using a Canvas.
///
/// This is an internal rendering primitive.
struct AxleView: View {
    /// The length of the square side containing the axle.
    let sideLength: CGFloat
    /// The stroke width of the axle line.
    let strokeWidth: CGFloat
    /// The orientation of the axle line (horizontal, vertical, diagonal).
    let orientation: AxleOrientation
    /// The color used to draw the axle line.
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

/// Renders the spinning medallion face, label and edge, applying 3D rotation.
///
/// This is an internal rendering primitive.
struct MedallionView: View {
    /// Diameter of the medallion circle or square side.
    let diameter: CGFloat
    /// Stroke width of the medallion border.
    let strokeWidth: CGFloat
    /// Background color for the top face.
    let topColor: Color
    /// Background color for the bottom face.
    let bottomColor: Color
    /// Color used for the medallion edge/border.
    let edgeColor: Color
    /// Optional custom image for the top face.
    let topImage: Image?
    /// Optional custom image for the bottom face.
    let bottomImage: Image?
    /// Localized label displayed on the top face.
    let topLabel: LocalizedStringKey
    /// Localized label displayed on the bottom face.
    let bottomLabel: LocalizedStringKey
    /// Font used for the face labels.
    let labelFont: Font
    /// Color used for the face labels.
    let labelColor: Color
    /// Shape of the medallion (circle or square).
    let shape: MedallionShape
    /// Current rotation angle in degrees.
    let rotationDegrees: Double
    /// Axis of rotation for the medallion.
    let rotationAxis: ButterflyRotationAxis

    /// SwiftUI shape resolved from the `MedallionShape` enum,
    /// used for background fill, image clipping, and border stroke.
    private var resolvedShape: AnyShape {
        shape == .square ? AnyShape(Rectangle()) : AnyShape(Circle())
    }

    var body: some View {
        let visibleTop = ButterflyValidation.visibleTopFace(rotationDegrees: rotationDegrees)
        let faceSource = medallionFaceSource(visibleTop: visibleTop)

        ZStack {
            resolvedShape
                .fill(backgroundColor(visibleTop: visibleTop, faceSource: faceSource))

            switch faceSource {
            case let .image(image, isDefaultStone):
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: diameter, height: diameter)
                    .scaleEffect(isDefaultStone ? 2.0 : 1.0)
                    .clipShape(resolvedShape)
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

            resolvedShape
                .stroke(edgeColor, lineWidth: strokeWidth)
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
                ? [
                    "square-white-stone-64",
                    "square-white-stone-128"
                  ]
                : [
                    "square-black-stone-64",
                    "square-black-stone-128"
                  ]
        case .circle:
            candidateNames = visibleTop
                ? [
                    "white-stone-64",
                    "white-stone-128"
                  ]
                : [
                    "black-stone-64",
                    "black-stone-128"
                  ]
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

/// Loads and caches default bundled stone images for the medallion faces.
///
/// Errors are logged to the OS logger when resources are missing or fail to load.
private enum DefaultStoneImageCache {
    private static let logger = Logger(subsystem: "com.integracode.ButterflyButton", category: "resources")

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

/// Places an optional outer label around the mount content at the requested placement.
///
/// This is an internal composition helper.
struct OuterLabelView<Mount: View>: View {
    /// The side length of the mount content area.
    let sideLength: CGFloat
    /// Padding spacing between the label and mount.
    let labelPadding: CGFloat
    /// Desired placement of the label relative to the mount.
    let placement: LabelPlacement
    /// Whether layout is right-to-left, affects auto-placement.
    let effectiveRTL: Bool
    /// The optional label view to display.
    let label: AnyView?
    /// The mount view wrapped by this outer label.
    let mount: Mount

    var body: some View {
        // resolvedPlacement always returns a cardinal placement (.top/.bottom/.leading/.trailing);
        // the default branch is unreachable but kept for exhaustiveness.
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
        default:
            mount
        }
    }

    /// Resolves `.auto` to a concrete leading/trailing placement based on RTL.
    private var resolvedPlacement: LabelPlacement {
        if placement != .auto { return placement }
        return effectiveRTL ? .trailing : .leading
    }

    /// Conditionally renders the provided label view when available.
    @ViewBuilder
    private var labelView: some View {
        if let label {
            label
        }
    }
}

