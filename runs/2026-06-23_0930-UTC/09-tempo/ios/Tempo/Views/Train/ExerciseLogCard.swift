import SwiftUI
import SwiftData

/// A card grouping all sets logged for one exercise within the active workout.
struct ExerciseLogCard: View {
    @Bindable var workout: Workout
    let exercise: Exercise
    let prefs: AppSettings
    let onSetCompleted: (SetEntry) -> Void
    let onPlate: (SetEntry) -> Void
    let restTimer: RestTimerModel

    @Environment(\.modelContext) private var context

    private var sets: [SetEntry] { workout.sets(for: exercise) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            columnTitles
            ForEach(Array(sets.enumerated()), id: \.element.id) { index, set in
                SetRowView(
                    set: set,
                    workingIndex: workingIndex(for: set),
                    prefs: prefs,
                    onToggleComplete: { toggleComplete(set) },
                    onPlate: { onPlate(set) },
                    canPlate: exercise.equipment.usesPlates
                )
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) { deleteSet(set) } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            HStack {
                Button { addSet() } label: {
                    Label("Add Set", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                }
                .tint(Theme.accent)
                Spacer()
            }
            .padding(.top, 2)
        }
        .cardSurface()
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: exercise.muscle.symbol)
                .font(.headline)
                .foregroundStyle(Theme.accent)
                .frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Text("\(exercise.muscle.display) · \(exercise.equipment.display)")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Menu {
                Button(role: .destructive) { removeExercise() } label: {
                    Label("Remove Exercise", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.headline)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 36, height: 28)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Exercise options")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(exercise.name), \(exercise.muscle.display)")
    }

    private var columnTitles: some View {
        HStack(spacing: 8) {
            Text("SET").frame(width: 38, alignment: .leading)
            Text(prefs.unit.display.uppercased()).frame(maxWidth: .infinity, alignment: .leading)
            Text("REPS").frame(maxWidth: .infinity, alignment: .leading)
            if prefs.trackRPE {
                Text("RPE").frame(width: 46, alignment: .leading)
            }
            Spacer().frame(width: 32)
        }
        .font(.caption2.weight(.bold))
        .foregroundStyle(Theme.textSecondary)
        .accessibilityHidden(true)
    }

    private func workingIndex(for set: SetEntry) -> Int? {
        guard !set.isWarmup else { return nil }
        let working = sets.filter { !$0.isWarmup }
        return working.firstIndex(where: { $0.id == set.id }).map { $0 + 1 }
    }

    // MARK: - Actions

    private func addSet() {
        let nextOrder = (workout.sets.map { $0.order }.max() ?? -1) + 1
        let template = sets.last(where: { !$0.isWarmup }) ?? sets.last
        let set = SetEntry(order: nextOrder,
                           weightKg: template?.weightKg ?? 0,
                           reps: template?.reps ?? 8,
                           isCompleted: false,
                           workout: workout, exercise: exercise)
        context.insert(set)
        workout.sets.append(set)
        try? context.save()
        Haptics.selection(enabled: prefs.hapticsEnabled)
    }

    private func toggleComplete(_ set: SetEntry) {
        set.isCompleted.toggle()
        set.loggedAt = .now
        try? context.save()
        if set.isCompleted {
            onSetCompleted(set)
        }
    }

    private func deleteSet(_ set: SetEntry) {
        context.delete(set)
        try? context.save()
        Haptics.impact(.rigid, enabled: prefs.hapticsEnabled)
    }

    private func removeExercise() {
        for s in sets { context.delete(s) }
        try? context.save()
        Haptics.impact(.rigid, enabled: prefs.hapticsEnabled)
    }
}
