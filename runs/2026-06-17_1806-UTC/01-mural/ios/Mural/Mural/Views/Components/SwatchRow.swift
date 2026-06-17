import SwiftUI

/// A horizontal row of palette color swatches.
struct SwatchRow: View {
    let colors: [Color]
    var height: CGFloat = 28
    var cornerRadius: CGFloat = 8

    var body: some View {
        HStack(spacing: 0) {
            if colors.isEmpty {
                Rectangle().fill(Theme.hairline)
            } else {
                ForEach(Array(colors.enumerated()), id: \.offset) { _, color in
                    Rectangle().fill(color)
                }
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        )
        .accessibilityElement()
        .accessibilityLabel("Palette with \(colors.count) colors")
    }
}
