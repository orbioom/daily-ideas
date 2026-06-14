import SwiftUI

/// A thin rounded progress bar in the accent gradient.
struct ProgressBar: View {
    let fraction: Double
    var height: CGFloat = 6

    private var clamped: Double { min(max(fraction, 0), 1) }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.hairline)
                Capsule()
                    .fill(LinearGradient(colors: [Theme.accent, Theme.violet],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(0, geo.size.width * clamped))
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}
