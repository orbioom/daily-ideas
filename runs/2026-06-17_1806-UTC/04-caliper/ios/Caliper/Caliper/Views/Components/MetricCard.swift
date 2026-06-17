import SwiftUI

/// Direction of a change relative to a goal, used to color the delta.
enum ChangeIntent {
    case neutral, good, bad

    func color() -> Color {
        switch self {
        case .neutral: return Theme.inkSoft
        case .good: return Theme.good
        case .bad: return Theme.bad
        }
    }
}

/// A summary card showing a metric's latest value, change, and a sparkline.
struct MetricCard: View {
    let title: String
    let icon: String
    let valueText: String
    let unitText: String
    let changeText: String?
    let intent: ChangeIntent
    let sparkValues: [Double]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text(title)
                    .font(Theme.rounded(14, .semibold))
                    .foregroundStyle(Theme.inkSoft)
                Spacer(minLength: 0)
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(valueText)
                    .font(Theme.rounded(30, .bold))
                    .foregroundStyle(Theme.ink)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(unitText)
                    .font(Theme.rounded(14, .semibold))
                    .foregroundStyle(Theme.inkSoft)
            }

            Sparkline(values: sparkValues)
                .frame(height: 30)

            if let changeText {
                Text(changeText)
                    .font(Theme.rounded(13, .semibold))
                    .foregroundStyle(intent.color())
            } else {
                Text("No prior entry")
                    .font(Theme.rounded(13, .medium))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue("\(valueText) \(unitText). \(changeText ?? "No prior entry")")
    }
}
