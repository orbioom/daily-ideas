import SwiftUI
import SwiftData

/// Full detail of one completed session: every logged set, volume, duration.
struct SessionDetailView: View {
    @Bindable var session: WorkoutSession
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @State private var showDeleteConfirm = false

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    summaryCard
                    ForEach(session.orderedExercises) { exercise in
                        exerciseCard(exercise)
                    }
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete session", systemImage: "trash")
                            .font(Theme.rounded(15, .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .foregroundStyle(Theme.bad)
                }
                .padding(20)
            }
        }
        .navigationTitle(session.dayName)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete this session?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { deleteSession() }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var summaryCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text(session.programName)
                    .font(Theme.rounded(13, .bold))
                    .foregroundStyle(Theme.accent)
                Text(session.date.formatted(date: .complete, time: .shortened))
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                HStack(spacing: 18) {
                    metric("\(session.completedSetCount)", "sets")
                    metric("\(session.durationSeconds / 60)", "min")
                    metric(settings.number(session.totalVolumeKg), "\(settings.unit.label) vol")
                }
            }
        }
    }

    private func metric(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(Theme.num(22, .heavy))
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
            Text(label)
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkSoft)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }

    private func exerciseCard(_ exercise: LoggedExercise) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(exercise.name)
                        .font(Theme.rounded(17, .bold))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    MuscleBadge(group: exercise.group)
                }
                ForEach(exercise.orderedSets) { set in
                    HStack {
                        Text(set.isWarmup ? "Warmup" : "Set \(set.setIndex + 1)")
                            .font(Theme.rounded(13, .medium))
                            .foregroundStyle(set.isWarmup ? Theme.steel : Theme.inkSoft)
                        Spacer()
                        Text("\(settings.weight(set.weightKg)) × \(set.reps)")
                            .font(Theme.num(16, .bold))
                            .foregroundStyle(set.isComplete ? Theme.ink : Theme.inkFaint)
                            .monospacedDigit()
                        Image(systemName: set.isComplete ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(set.isComplete ? Theme.good : Theme.inkFaint)
                            .font(.system(size: 16))
                            .accessibilityHidden(true)
                    }
                }
                if exercise.orderedSets.isEmpty {
                    Text("No sets logged.")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkFaint)
                }
            }
        }
    }

    private func deleteSession() {
        context.delete(session)
        try? context.save()
        Haptics.warning(settings.hapticsEnabled)
        dismiss()
    }
}
