import SwiftUI

/// A slim progress bar plus percent label showing how much of a recipe you can make.
struct MatchBar: View {
    /// 0...1
    let percent: Double
    var tint: Color = Theme.accent

    private var clamped: Double { min(1, max(0, percent)) }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Theme.hairline)
                Capsule()
                    .fill(tint)
                    .frame(width: max(0, geo.size.width * clamped))
            }
        }
        .frame(height: 6)
        .accessibilityElement()
        .accessibilityLabel("Match")
        .accessibilityValue("\(Int((clamped * 100).rounded())) percent")
    }
}
