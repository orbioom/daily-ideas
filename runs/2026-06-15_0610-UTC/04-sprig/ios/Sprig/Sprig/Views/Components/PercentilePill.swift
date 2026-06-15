import SwiftUI

/// A compact percentile readout used in the Home list snapshot.
struct PercentilePill: View {
    let measure: GrowthMeasure
    let result: PercentileResult?

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: measure.symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            if let result {
                Text(PercentileEngine.ordinal(result.percentile))
                    .font(Theme.rounded(15, .bold))
                    .foregroundStyle(Theme.ink)
            } else {
                Text("—")
                    .font(Theme.rounded(15, .bold))
                    .foregroundStyle(Theme.inkFaint)
            }
            Text(measure.shortTitle)
                .font(Theme.rounded(10))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                .fill(Theme.surfaceAlt)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        if let result {
            return "\(measure.title): \(PercentileEngine.ordinal(result.percentile)) percentile"
        }
        return "\(measure.title): no measurement yet"
    }
}
