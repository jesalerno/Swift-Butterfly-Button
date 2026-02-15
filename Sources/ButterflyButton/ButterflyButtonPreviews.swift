// Copyright 2026 John Salerno.

import SwiftUI

/// Preview matrix used to exercise style and accessibility variants.
private struct ButterflyPreviewMatrix: View {
    @State private var a = true
    @State private var b = false

    var body: some View {
        VStack(spacing: 16) {
            ButterflyButton(
                isOn: $a,
                style: ButterflyButtonStyle(
                    axleOrientation: .diagonalRTL,
                    medallionTopImage: Image(systemName: "sun.max.fill"),
                    medallionBottomImage: Image(systemName: "moon.fill")
                )
            ) {
                Text("Matrix")
            }

            ButterflyButton(isOn: $b, labelPlacement: .auto, spinDecelerationDuration: 1.5) {
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
