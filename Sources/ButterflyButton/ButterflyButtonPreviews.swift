// Copyright 2026 John Salerno.

import SwiftUI

/// Preview matrix used to exercise style and accessibility variants.
private struct ButterflyPreviewMatrix: View {
    @State private var isFirstOn = true
    @State private var isSecondOn = false

    private enum Constants {
        /// Spacing between preview rows.
        static let PREVIEW_SECTION_SPACING: CGFloat = 16
        /// Spin duration used in the preview variant.
        static let PREVIEW_SPIN_DURATION: TimeInterval = 1.5
    }

    var body: some View {
        let previewStyle = ButterflyButtonStyle(
            axleOrientation: .diagonalRTL,
            medallionTopImage: Image(systemName: "sun.max.fill"),
            medallionBottomImage: Image(systemName: "moon.fill"),
        )
        VStack(spacing: Constants.PREVIEW_SECTION_SPACING) {
            ButterflyButton(
                isOn: $isFirstOn,
                style: previewStyle,
            ) {
                Text("Matrix")
            }

            ButterflyButton(
                isOn: $isSecondOn,
                labelPlacement: .auto,
                spinDecelerationDuration: Constants.PREVIEW_SPIN_DURATION,
            ) {
                Text("RTL/Type")
            }
        }
        .padding()
    }
}

#Preview("Dark") {
    ButterflyPreviewMatrix()
        .preferredColorScheme(.dark)
}

#Preview("RTL") {
    ButterflyPreviewMatrix()
        .environment(\.layoutDirection, .rightToLeft)
}

#Preview("Large Type") {
    ButterflyPreviewMatrix()
        .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
}

/// Preview host showing size and orientation variants of the control.
private struct ButterflyPreviewHost: View {
    @State private var isOn = true
    @State private var second = false
    @State private var third = true
    var body: some View {
        VStack(spacing: 20) {
            ButterflyButton(
                isOn: $isOn,
                sideLength: 44,
                style: ButterflyButtonStyle(axleOrientation: .horizontal),
                label: { Text("44") },
            )
            ButterflyButton(
                isOn: $second,
                sideLength: 60,
                style: ButterflyButtonStyle(axleOrientation: .vertical),
                label: { Text("60") },
            )
            ButterflyButton(
                isOn: $third,
                sideLength: 120,
                style: ButterflyButtonStyle(axleOrientation: .diagonalLTR),
                label: { Text("120") },
            )
        }
        .padding()
    }
}

#Preview("Default") {
    ButterflyPreviewHost()
}
