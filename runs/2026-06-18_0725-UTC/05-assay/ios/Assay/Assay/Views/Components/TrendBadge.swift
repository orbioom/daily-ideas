import SwiftUI

/// Small arrow + percentage badge describing a marker's latest movement
/// relative to what is "good" for that marker.
struct TrendBadge: View {
    let trend: MarkerTrend

    private var color: Color {
        switch trend.direction {
        case .improving: return Theme.good
        case .worsening: return Theme.bad
        case .stable: return Theme.inkSoft
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: trend.direction.symbol)
                .font(.system(size: 12, weight: .semibold))
            if let pct = trend.percentChange {
                Text(Fmt.signedPercent(pct))
                    .font(Theme.rounded(12, .semibold))
            } else {
                Text(trend.direction.label)
                    .font(Theme.rounded(12, .semibold))
            }
        }
        .foregroundStyle(color)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Trend")
        .accessibilityValue(trendAccessibility)
    }

    private var trendAccessibility: String {
        if let pct = trend.percentChange {
            return "\(trend.direction.label), \(Fmt.signedPercent(pct)) since last reading"
        }
        return trend.direction.label
    }
}
