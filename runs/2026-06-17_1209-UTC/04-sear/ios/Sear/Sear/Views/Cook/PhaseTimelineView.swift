import SwiftUI

/// Vertical phase timeline highlighting the current phase.
struct PhaseTimelineView: View {
    let steps: [PhaseStep]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.element.id) { idx, step in
                HStack(alignment: .top, spacing: 12) {
                    VStack(spacing: 0) {
                        Circle()
                            .fill(dotColor(step))
                            .frame(width: 14, height: 14)
                            .overlay(
                                Image(systemName: step.isComplete ? "checkmark" : "")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(.white)
                            )
                        if idx < steps.count - 1 {
                            Rectangle()
                                .fill(step.isComplete ? Theme.accent : Theme.hairline)
                                .frame(width: 2, height: 28)
                        }
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(step.phase.label)
                            .font(Theme.rounded(15, step.isCurrent ? .bold : .medium))
                            .foregroundStyle(step.isCurrent ? Theme.accent : Theme.ink)
                        if step.isCurrent {
                            Text(step.phase.detail)
                                .font(Theme.rounded(12))
                                .foregroundStyle(Theme.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.bottom, idx < steps.count - 1 ? 12 : 0)
                    Spacer()
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(step.phase.label)\(step.isCurrent ? ", current phase" : step.isComplete ? ", complete" : "")")
            }
        }
    }

    private func dotColor(_ step: PhaseStep) -> Color {
        if step.isCurrent { return Theme.accent }
        if step.isComplete { return Theme.accent.opacity(0.7) }
        return Theme.hairline
    }
}
