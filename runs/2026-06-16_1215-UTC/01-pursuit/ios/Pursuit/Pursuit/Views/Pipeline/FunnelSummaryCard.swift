import SwiftUI

/// Sticky summary card at the top of the Pipeline showing counts and rates.
struct FunnelSummaryCard: View {
    let engine: PipelineEngine

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(engine.total)")
                        .font(Theme.rounded(34, .bold))
                        .foregroundStyle(.white)
                    Text(engine.total == 1 ? "active application" : "active applications")
                        .font(Theme.rounded(13, .medium))
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(engine.thisWeekCount)/\(engine.weeklyGoal)")
                        .font(Theme.rounded(20, .bold))
                        .foregroundStyle(.white)
                    Text("this week")
                        .font(Theme.rounded(12, .medium))
                        .foregroundStyle(.white.opacity(0.85))
                }
            }

            HStack(spacing: 10) {
                ratePill(engine.responseRate)
                ratePill(engine.interviewRate)
                ratePill(engine.offerRate)
            }
        }
        .padding(18)
        .background(Theme.heroGradient, in: RoundedRectangle(cornerRadius: Theme.radiusL, style: .continuous))
        .shadow(color: Theme.accent.opacity(0.25), radius: 14, y: 6)
        .accessibilityElement(children: .contain)
    }

    private func ratePill(_ metric: RateMetric) -> some View {
        VStack(spacing: 2) {
            Text(metric.display)
                .font(Theme.rounded(18, .bold))
                .foregroundStyle(.white)
            Text(shortTitle(metric.id))
                .font(Theme.rounded(10, .medium))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: Theme.radiusS, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(metric.title)
        .accessibilityValue("\(metric.display), \(metric.subtitle)")
    }

    private func shortTitle(_ id: String) -> String {
        switch id {
        case "response": return "Response"
        case "interview": return "Interview"
        case "offer": return "Offer"
        default: return id.capitalized
        }
    }
}
