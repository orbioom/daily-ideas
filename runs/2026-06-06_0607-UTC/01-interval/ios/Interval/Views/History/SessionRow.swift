import SwiftUI

/// A compact row summarising one logged session.
struct SessionRow: View {
    var session: Session
    var showRoutineName: Bool

    private var dateText: String {
        session.startedAt.formatted(date: .abbreviated, time: .shortened)
    }

    private var statusTint: Color {
        session.finishedFully ? Brand.live : Brand.text3
    }

    var body: some View {
        GlassCard(padding: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(statusTint.opacity(0.16)).frame(width: 40, height: 40)
                    Image(systemName: session.finishedFully ? "checkmark" : "flag.checkered")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(statusTint)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    if showRoutineName {
                        Text(session.routineNameSnapshot)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Brand.text)
                            .lineLimit(1)
                    }
                    Text(dateText)
                        .font(showRoutineName ? .caption : .subheadline.weight(.medium))
                        .foregroundStyle(showRoutineName ? Brand.text3 : Brand.text)
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(DurationFormat.compact(session.activeSeconds))
                        .font(Brand.mono(15, weight: .semibold))
                        .foregroundStyle(Brand.text)
                    Text(session.finishedFully ? "Complete"
                                               : "\(session.completedSteps)/\(session.totalSteps) steps")
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(showRoutineName ? session.routineNameSnapshot + ", " : "")\(dateText)")
        .accessibilityValue(
            (session.finishedFully ? "Completed" : "Ended at \(session.completedSteps) of \(session.totalSteps) steps")
            + ", \(DurationFormat.compact(session.activeSeconds)) active"
        )
    }
}

#Preview {
    VStack(spacing: 12) {
        SessionRow(session: Session(startedAt: .now, endedAt: .now, activeSeconds: 600,
                                    workSeconds: 320, completedSteps: 20, totalSteps: 20,
                                    finishedFully: true, routineNameSnapshot: "Classic HIIT"),
                   showRoutineName: true)
        SessionRow(session: Session(startedAt: .now, endedAt: .now, activeSeconds: 180,
                                    workSeconds: 80, completedSteps: 6, totalSteps: 20,
                                    finishedFully: false, routineNameSnapshot: "Tabata"),
                   showRoutineName: true)
    }
    .padding()
    .background(Brand.pageBackground)
}
