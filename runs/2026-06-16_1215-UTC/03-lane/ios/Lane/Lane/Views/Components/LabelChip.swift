import SwiftUI

/// Small colored pill for a label.
struct LabelChip: View {
    let name: String
    let colorHex: Int
    var compact: Bool = false

    var body: some View {
        let color = Color(hex: UInt(max(0, colorHex)))
        Group {
            if compact {
                Capsule()
                    .fill(color)
                    .frame(width: 22, height: 6)
                    .accessibilityLabel("Label \(name)")
            } else {
                Text(name)
                    .font(Theme.rounded(12, .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(color, in: Capsule())
                    .accessibilityLabel("Label \(name)")
            }
        }
    }
}
