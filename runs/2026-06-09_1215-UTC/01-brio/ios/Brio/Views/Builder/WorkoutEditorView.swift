import SwiftUI
import SwiftData

/// Creates or edits a custom workout. Works against a local draft so nothing is
/// persisted until the user taps Save; on save it either inserts a new Workout
/// or updates the existing one in place.
struct WorkoutEditorView: View {
    enum Mode {
        case create
        case edit(Workout)
    }

    let mode: Mode

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("brio.defaultRestSec") private var defaultRestSec = 15

    @State private var name = ""
    @State private var summary = ""
    @State private var category: WorkoutCategory = .fullBody
    @State private var difficulty: Difficulty = .moderate
    @State private var rounds = 3
    @State private var restEx = 15
    @State private var restRound = 60
    @State private var draftItems: [DraftItem] = []

    @State private var showLibrary = false
    @State private var loaded = false

    /// A mutable, in-memory representation of a workout item used while editing.
    struct DraftItem: Identifiable {
        let id = UUID()
        var exerciseName: String
        var kind: ExerciseKind
        var reps: Int
        var durationSec: Int
        var perSide: Bool
        var symbol: String
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !draftItems.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                detailsSection
                roundsSection
                movesSection
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle(isEditing ? "Edit workout" : "New workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showLibrary) {
                ExerciseLibraryPickerView { exercise in
                    addExercise(exercise)
                }
            }
            .onAppear(perform: loadIfNeeded)
        }
    }

    // MARK: - Sections

    private var detailsSection: some View {
        Section("Details") {
            TextField("Name", text: $name)
                .accessibilityLabel("Workout name")
            TextField("Short summary (optional)", text: $summary, axis: .vertical)
                .lineLimit(1...3)
            Picker("Category", selection: $category) {
                ForEach(WorkoutCategory.allCases) { Text($0.label).tag($0) }
            }
            Picker("Difficulty", selection: $difficulty) {
                ForEach(Difficulty.allCases) { Text($0.label).tag($0) }
            }
        }
    }

    private var roundsSection: some View {
        Section("Structure") {
            Stepper(value: $rounds, in: 1...20) {
                LabeledContent("Rounds", value: "\(rounds)")
            }
            .accessibilityValue("\(rounds) rounds")
            Stepper(value: $restEx, in: 0...300, step: 5) {
                LabeledContent("Rest between moves", value: "\(restEx)s")
            }
            .accessibilityValue("\(restEx) seconds")
            Stepper(value: $restRound, in: 0...600, step: 5) {
                LabeledContent("Rest between rounds", value: "\(restRound)s")
            }
            .accessibilityValue("\(restRound) seconds")
        }
    }

    private var movesSection: some View {
        Section {
            if draftItems.isEmpty {
                Text("No moves yet. Tap Add move to pick from the library.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
            } else {
                ForEach($draftItems) { $item in
                    DraftItemRow(item: $item)
                }
                .onMove { from, to in
                    draftItems.move(fromOffsets: from, toOffset: to)
                }
                .onDelete { offsets in
                    draftItems.remove(atOffsets: offsets)
                    Haptics.tap()
                }
            }

            Button {
                Haptics.tap()
                showLibrary = true
            } label: {
                Label("Add move", systemImage: "plus.circle")
            }
        } header: {
            HStack {
                Text("Moves")
                Spacer()
                if !draftItems.isEmpty {
                    EditButton()
                        .font(.caption)
                }
            }
        } footer: {
            if !draftItems.isEmpty {
                Text("Swipe to delete · drag to reorder · tap a move to set reps, time, or per-side.")
            }
        }
    }

    // MARK: - Actions

    private func loadIfNeeded() {
        guard !loaded else { return }
        loaded = true
        if case .create = mode {
            // Pre-fill the rest from the user's default preference.
            restEx = min(max(defaultRestSec, 0), 300)
        }
        if case let .edit(workout) = mode {
            name = workout.name
            summary = workout.summary
            category = workout.category
            difficulty = workout.difficulty
            rounds = workout.rounds
            restEx = workout.restBetweenExercisesSec
            restRound = workout.restBetweenRoundsSec
            draftItems = workout.orderedItems.map {
                DraftItem(exerciseName: $0.exerciseName, kind: $0.kind, reps: $0.reps,
                          durationSec: $0.durationSec, perSide: $0.perSide, symbol: $0.symbol)
            }
        }
    }

    private func addExercise(_ exercise: Exercise) {
        draftItems.append(DraftItem(exerciseName: exercise.name, kind: exercise.kind,
                                    reps: exercise.defaultReps, durationSec: exercise.defaultDurationSec,
                                    perSide: false, symbol: exercise.symbol))
        Haptics.selection()
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !draftItems.isEmpty else { return }

        let items = draftItems.enumerated().map { idx, d in
            let it = WorkoutItem(order: idx, exerciseName: d.exerciseName, kind: d.kind,
                                 reps: d.reps, durationSec: d.durationSec,
                                 perSide: d.perSide, symbol: d.symbol)
            return it
        }

        switch mode {
        case .create:
            let workout = Workout(name: trimmed, summary: summary, category: category,
                                  difficulty: difficulty, rounds: rounds,
                                  restBetweenExercisesSec: restEx,
                                  restBetweenRoundsSec: restRound,
                                  isBuiltIn: false, sortIndex: 1000, items: items)
            context.insert(workout)
        case let .edit(workout):
            // Replace items wholesale; cascade delete-rule cleans up the old ones.
            for old in workout.items { context.delete(old) }
            workout.items = []
            workout.name = trimmed
            workout.summary = summary
            workout.category = category
            workout.difficulty = difficulty
            workout.rounds = min(max(rounds, 1), 20)
            workout.restBetweenExercisesSec = min(max(restEx, 0), 300)
            workout.restBetweenRoundsSec = min(max(restRound, 0), 600)
            for it in items {
                it.workout = workout
                context.insert(it)
            }
            workout.items = items
        }

        do {
            try context.save()
            Haptics.success()
            dismiss()
        } catch {
            // Leave the editor open so the user can retry rather than losing work.
        }
    }
}

/// One editable row in the moves list. Tapping expands inline controls.
private struct DraftItemRow: View {
    @Binding var item: WorkoutEditorView.DraftItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: item.symbol)
                    .foregroundStyle(Brand.text2)
                    .frame(width: 26)
                    .accessibilityHidden(true)
                Text(item.exerciseName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Brand.text)
                Spacer()
            }

            Picker("Type", selection: $item.kind) {
                Text("Reps").tag(ExerciseKind.reps)
                Text("Timed").tag(ExerciseKind.timed)
            }
            .pickerStyle(.segmented)

            if item.kind == .reps {
                Stepper(value: $item.reps, in: 1...100) {
                    LabeledContent("Reps", value: "\(item.reps)")
                }
                .accessibilityValue("\(item.reps) reps")
            } else {
                Stepper(value: $item.durationSec, in: 5...600, step: 5) {
                    LabeledContent("Duration", value: "\(item.durationSec)s")
                }
                .accessibilityValue("\(item.durationSec) seconds")
            }

            Toggle("Per side (left & right)", isOn: $item.perSide)
                .font(.subheadline)
        }
        .padding(.vertical, 4)
    }
}
