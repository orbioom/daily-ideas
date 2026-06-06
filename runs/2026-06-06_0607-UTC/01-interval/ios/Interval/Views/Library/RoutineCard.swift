import SwiftUI

/// A glass summary card for a routine in the library list.
struct RoutineCard: View {
    var routine: Routine

    private var summary: String {
        let steps = routine.stepCount
        let total = DurationFormat.compact(routine.totalDuration)
        if steps == 0 { return "No segments yet" }
        let stepWord = steps == 1 ? "step" : "steps"
        return "\(steps) \(stepWord) · \(total)"
    }

    var body: some View {
        GlassCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Brand.glassStroke.opacity(0.25))
                        .frame(width: 46, height: 46)
                    Image(systemName: routine.glyph)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Brand.text)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(routine.displayName)
                        .font(.headline)
                        .foregroundStyle(Brand.text)
                        .lineLimit(1)
                    Text(summary)
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                    if !routine.isRunnable {
                        Text("Add a segment to run")
                            .font(.caption)
                            .foregroundStyle(Brand.rest)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Brand.text3)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(routine.displayName)
        .accessibilityValue(summary)
        .accessibilityHint("Opens routine details")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 14) {
            ForEach(SampleData.makeRoutines()) { RoutineCard(routine: $0) }
        }
        .padding()
    }
    .background(Brand.pageBackground)
}
