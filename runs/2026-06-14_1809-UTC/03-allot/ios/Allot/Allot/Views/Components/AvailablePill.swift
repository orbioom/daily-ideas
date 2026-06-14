import SwiftUI

/// A colored pill showing a category's available balance:
/// green when funded (≥0 with money), red when overspent, neutral at zero.
struct AvailablePill: View {
    let amount: Double
    let text: String

    private var tint: Color {
        if amount < -0.005 { return Theme.bad }
        if amount > 0.005 { return Theme.good }
        return Theme.inkSoft
    }

    private var fill: Color {
        if amount < -0.005 { return Theme.bad.opacity(0.15) }
        if amount > 0.005 { return Theme.accentSoft }
        return Theme.surfaceAlt
    }

    var body: some View {
        Text(text)
            .font(Theme.money(15, .bold))
            .monospacedDigit()
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(fill))
    }
}
