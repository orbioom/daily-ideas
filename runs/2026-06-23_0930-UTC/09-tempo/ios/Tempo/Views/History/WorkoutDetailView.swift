import SwiftUI
import SwiftData

/// Read-only breakdown of a finished workout, with delete + note editing.
struct WorkoutDetailView: View {
    @Bindable var workout: Workout
    let prefs: AppSettings
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var showDelete = false
    @State private var editingNotes = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    headerCard
                    notesCard
                    ForEach(workout.exercises) { exercise in
                        exerciseSection(exercise)
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle(workout.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { editingNotes = true } label: { Label("Edit Notes", systemImage: "square.and.pencil") }
                    Button(role: .destructive) { showDelete = true } label: { Label("Delete Workout", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Workout options")
            }
        }
        .alert("Delete workout?", isPresented: $showDelete) {
            Button("Delete", role: .destructive) {
                context.delete(workout)
                try? context.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently removes the session and its sets.")
        }
        .alert("Workout notes", isPresented: $editingNotes) {
            TextField("Notes", text: $workout.notes)
            Button("Save") { try? context.save() }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(workout.startedAt.formatted(date: .complete, time: .shortened))
                .font(.caption).foregroundStyle(Theme.textSecondary)
            HStack(spacing: 14) {
                detailStat(Format.volume(workout.totalVolume, unit: prefs.unit), "Volume", "scalemass")
                Divider().frame(height: 34)
                detailStat("\(workout.completedSets.count)", "Sets", "checkmark.circle")
                Divider().frame(height: 34)
                detailStat(Format.duration(workout.duration), "Time", "clock")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    private func detailStat(_ value: String, _ label: String, _ icon: String) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon).font(.caption).foregroundStyle(Theme.accent).accessibilityHidden(true)
            Text(value).font(.headline).foregroundStyle(Theme.textPrimary).minimumScaleFactor(0.6).lineLimit(1)
            Text(label).font(.caption2).foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    @ViewBuilder
    private var notesCard: some View {
        if !workout.notes.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                SectionLabel(text: "Notes")
                Text(workout.notes).font(.subheadline).foregroundStyle(Theme.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardSurface()
        }
    }

    private func exerciseSection(_ exercise: Exercise) -> some View {
        let sets = workout.sets(for: exercise)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: exercise.muscle.symbol).foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text(exercise.name).font(.headline).foregroundStyle(Theme.textPrimary)
            }
            ForEach(Array(sets.enumerated()), id: \.element.id) { idx, set in
                HStack {
                    Text(set.isWarmup ? "Warm-up" : "Set \(idx + 1)")
                        .font(.caption).foregroundStyle(set.isWarmup ? Theme.rest : Theme.textSecondary)
                        .frame(width: 70, alignment: .leading)
                    Text("\(Units.weightString(kg: set.weightKg, unit: prefs.unit)) × \(set.reps)")
                        .font(.subheadline.weight(.medium)).foregroundStyle(Theme.textPrimary)
                    Spacer()
                    if let rpe = set.rpe {
                        Text("RPE \(Units.trimmed(rpe))").font(.caption).foregroundStyle(Theme.volume)
                    }
                    if let e = set.estimatedOneRepMax {
                        Text("e1RM \(Units.weightString(kg: e, unit: prefs.unit, showUnit: false))")
                            .font(.caption2).foregroundStyle(Theme.textSecondary)
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }
}
