import SwiftUI

/// A labeled horizontal progress bar for per-op mastery.
struct MasteryBar: View {
    let title: String
    let fraction: Double      // 0...1
    var tint: Color = Theme.accent
    var trailing: String? = nil

    private var clamped: Double { min(1, max(0, fraction)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text(trailing ?? "\(Int((clamped * 100).rounded()))%")
                    .font(Theme.rounded(14, .bold))
                    .foregroundStyle(tint)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.surfaceAlt)
                    Capsule().fill(tint)
                        .frame(width: max(0, geo.size.width * clamped))
                }
            }
            .frame(height: 12)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue("\(Int((clamped * 100).rounded())) percent mastered")
    }
}
