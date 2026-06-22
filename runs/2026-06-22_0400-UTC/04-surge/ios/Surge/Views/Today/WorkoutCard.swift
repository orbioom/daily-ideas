import SwiftUI

struct WorkoutCard: View {
    let run: PlannedRun
    var unit: String = "km"
    var onMarkDone: (() -> Void)? = nil
    var onLogRun: (() -> Void)? = nil
    var onReschedule: (() -> Void)? = nil
    var isHighlighted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    RunTypeBadge(runType: run.type)
                    Text(run.notes.isEmpty ? run.type.description : run.notes)
                        .font(.surgeCaption)
                        .foregroundColor(.surgeTextSecondary)
                        .lineLimit(2)
                }
                Spacer()
                if run.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.surgeSuccess)
                }
            }

            // Stats row
            if run.type.isRunningWorkout && run.distanceKm > 0 {
                HStack(spacing: 0) {
                    StatCell(
                        label: "Distance",
                        value: PaceEngine.formatDistance(run.distanceKm, unit: unit)
                    )

                    Divider()
                        .background(Color.surgeDivider)
                        .padding(.vertical, 4)

                    if run.paceTargetSecondsPerKm > 0 {
                        StatCell(
                            label: "Target Pace",
                            value: PaceEngine.formatPace(run.paceTargetSecondsPerKm, unit: unit)
                        )

                        Divider()
                            .background(Color.surgeDivider)
                            .padding(.vertical, 4)

                        let totalSeconds = PaceEngine.finishTime(paceSecondsPerKm: run.paceTargetSecondsPerKm, distanceKm: run.distanceKm)
                        StatCell(
                            label: "Est. Time",
                            value: PaceEngine.formatDuration(totalSeconds)
                        )
                    }
                }
                .frame(height: 52)
                .background(Color.surgeSurfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            // Action buttons (only shown if today's run, not completed)
            if isHighlighted && !run.isCompleted {
                HStack(spacing: 10) {
                    Button(action: { onMarkDone?() }) {
                        Label("Done", systemImage: "checkmark")
                    }
                    .surgeHighlightButton()

                    Button(action: { onLogRun?() }) {
                        Label("Log Run", systemImage: "square.and.pencil")
                    }
                    .surgeSecondaryButton()
                }
            }
        }
        .surgeCard()
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    isHighlighted ? Color.surgeHighlight.opacity(0.4) : Color.clear,
                    lineWidth: 1.5
                )
        )
    }
}

struct StatCell: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(.surgeTextPrimary)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.surgeTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
