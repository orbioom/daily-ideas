import SwiftUI

/// Horizontal bar gauge showing sleep debt over the last 14 nights.
struct DebtGauge: View {
    /// Rolling debt in hours (can be negative = well-rested).
    let debt: Double
    /// Maximum scale for the gauge bar (default 14h = worst case).
    var maxDebt: Double = 14.0
    let label: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    private var fillFraction: Double {
        guard maxDebt > 0 else { return 0 }
        return min(max(debt, 0) / maxDebt, 1.0)
    }

    private var gaugeColor: Color {
        if debt <= 0  { return Brand.live }
        if debt < 3   { return Brand.warn }
        return Brand.danger
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Eyebrow(text: "Sleep Debt · 14 nights")
                Spacer()
                Text(debt <= 0 ? "Well-rested" : "\(Format.hoursDecimal(debt)) deficit")
                    .font(Brand.mono(13, weight: .semibold))
                    .foregroundStyle(gaugeColor)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(Brand.hairline)
                        .frame(height: 10)

                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(gaugeColor)
                        .frame(
                            width: geo.size.width * (reduceMotion ? fillFraction : (appeared ? fillFraction : 0)),
                            height: 10
                        )
                        .animation(reduceMotion ? nil : Brand.ease(0.6), value: appeared)
                }
            }
            .frame(height: 10)

            Text(label)
                .font(.caption)
                .foregroundStyle(Brand.text3)
        }
        .onAppear {
            if !reduceMotion { appeared = true }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Sleep debt over last 14 nights")
        .accessibilityValue(debt <= 0 ? "Well-rested, no debt" : "\(Format.hoursDecimal(debt)) hour deficit. \(label)")
    }
}
