import SwiftUI

/// A single ranked correlation, shown as a card: factor → outcome, a strength/direction line, the
/// coefficient, a confidence note, and a strength meter.
struct CorrelationCard: View {
    let result: CorrelationEngine.Result

    private var dirColor: Color {
        result.direction == .positive ? Theme.positive : Theme.negative
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(result.factorName)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.inkFaint)
                    .accessibilityHidden(true)
                Text(result.outcomeName)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                Spacer(minLength: 0)
                Text(String(format: "%@%.2f", result.direction.sign, abs(result.r)))
                    .font(Theme.mono(16, .bold))
                    .foregroundStyle(dirColor)
                    .accessibilityHidden(true)
            }

            HStack(spacing: 8) {
                Pill(text: result.strength.label, color: dirColor)
                Pill(text: result.direction == .positive ? "Raises it" : "Lowers it", color: dirColor)
                if result.lag == 1 {
                    Pill(text: "Next day", color: Theme.accent)
                }
                Spacer(minLength: 0)
            }

            // Strength meter.
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.surfaceAlt)
                    Capsule().fill(dirColor)
                        .frame(width: max(6, geo.size.width * CGFloat(abs(result.r))))
                }
            }
            .frame(height: 7)
            .accessibilityHidden(true)

            Text(result.confidenceLabel)
                .font(Theme.rounded(12))
                .foregroundStyle(result.n < 7 ? Theme.warn : Theme.inkSoft)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(result.factorName) to \(result.outcomeName)")
        .accessibilityValue("\(result.strength.label) \(result.direction == .positive ? "positive" : "negative") correlation, coefficient \(String(format: "%.2f", result.r)), based on \(result.n) days. Double-tap for the chart.")
    }
}
