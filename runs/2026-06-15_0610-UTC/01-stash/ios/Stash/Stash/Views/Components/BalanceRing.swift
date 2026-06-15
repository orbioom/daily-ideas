import SwiftUI

/// A circular progress ring showing the remaining fraction of a gift-card balance.
/// Color shifts from accent → warn → bad as the balance depletes.
struct BalanceRing: View {
    /// 0...1 fraction remaining.
    let fraction: Double
    var lineWidth: CGFloat = 8
    var label: String? = nil

    private var ringColor: Color {
        if fraction <= 0.001 { return Theme.bad }
        if fraction < 0.25 { return Theme.warn }
        return Theme.accent
    }

    private var clamped: Double { min(max(fraction, 0), 1) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.surfaceAlt, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(ringColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            if let label {
                Text(label)
                    .font(Theme.rounded(13, .bold))
                    .foregroundStyle(Theme.ink)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .padding(2)
            }
        }
        .accessibilityHidden(true)
    }
}
