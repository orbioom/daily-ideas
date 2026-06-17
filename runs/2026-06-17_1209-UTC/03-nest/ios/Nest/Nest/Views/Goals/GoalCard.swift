import SwiftUI

/// A goal summary card with a progress ring, saved/target, and status badge.
struct GoalCard: View {
    let goal: Goal
    let settings: AppSettings

    private var summary: GoalSummary { GoalEngine.summary(for: goal) }
    private var tint: Color { Color.fromGoalHex(goal.colorHex) }

    var body: some View {
        Card {
            HStack(spacing: 16) {
                ZStack {
                    ProgressRing(fraction: summary.progressFraction,
                                 color: tint,
                                 lineWidth: 8,
                                 symbolName: goal.symbolName)
                }
                .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(goal.name)
                            .font(Theme.rounded(17, .semibold))
                            .foregroundStyle(Theme.ink)
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        StatusBadge(status: summary.status)
                    }
                    Text("\(settings.displayDecimal(summary.saved)) of \(settings.displayDecimal(summary.target))")
                        .font(Theme.money(14, .medium))
                        .foregroundStyle(Theme.inkSoft)
                    ProgressView(value: summary.progressFraction)
                        .tint(tint)
                        .accessibilityHidden(true)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(goal.name)
        .accessibilityValue("\(Int((summary.progressFraction * 100).rounded())) percent saved, \(summary.status.title)")
    }
}
