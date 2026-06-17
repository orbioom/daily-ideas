import SwiftUI

/// A small rounded tag/label.
struct Pill: View {
    let text: String
    var systemImage: String? = nil
    var tint: Color = Theme.accent
    var filled: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 10, weight: .semibold))
                    .accessibilityHidden(true)
            }
            Text(text)
                .font(Theme.rounded(12, .semibold))
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(
            Capsule().fill(filled ? tint : tint.opacity(0.15))
        )
        .foregroundStyle(filled ? .white : tint)
    }
}
