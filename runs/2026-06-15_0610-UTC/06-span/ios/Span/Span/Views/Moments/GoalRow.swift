import SwiftUI

/// A future goal with a live countdown. Uses `TimelineView` so the days/weeks tick down
/// without manual timers. Past-due goals read "arrived".
struct GoalRow: View {
    let goal: FutureGoal

    private var color: Color { Color(hexString: goal.colorHex, fallback: Theme.accent) }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let days = SpanEngine.daysBetween(context.date, goal.targetDate)
            row(daysRemaining: days)
        }
    }

    private func row(daysRemaining days: Int) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(color.opacity(0.18)).frame(width: 46, height: 46)
                Image(systemName: days >= 0 ? "hourglass" : "checkmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(color)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(goal.title)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                Text(Fmt.mediumDate.string(from: goal.targetDate))
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                if days > 0 {
                    Text("\(Fmt.grouped(days))")
                        .font(Theme.mono(20, .bold))
                        .foregroundStyle(color)
                    Text(days == 1 ? "day" : "days")
                        .font(Theme.rounded(11))
                        .foregroundStyle(Theme.inkFaint)
                    Text("≈ \(Fmt.grouped(days / 7)) wk")
                        .font(Theme.rounded(11))
                        .foregroundStyle(Theme.inkFaint)
                } else if days == 0 {
                    Text("Today")
                        .font(Theme.rounded(15, .bold))
                        .foregroundStyle(Theme.accent)
                } else {
                    Text("Arrived")
                        .font(Theme.rounded(14, .semibold))
                        .foregroundStyle(Theme.good)
                    Text("\(Fmt.grouped(-days))d ago")
                        .font(Theme.rounded(11))
                        .foregroundStyle(Theme.inkFaint)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(countdownLabel(days: days))
    }

    private func countdownLabel(days: Int) -> String {
        if days > 0 {
            return "\(goal.title), \(days) days remaining"
        } else if days == 0 {
            return "\(goal.title), today"
        } else {
            return "\(goal.title), arrived \(-days) days ago"
        }
    }
}
