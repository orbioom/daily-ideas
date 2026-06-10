import SwiftUI
import SwiftData

struct ExerciseDraft: Identifiable {
    let id = UUID()
    var name: String
    var muscle: Muscle
    var targetSets: Int = 3
    var repLow: Int = 8
    var repHigh: Int = 12
    var restSeconds: Int = 120
    var startWeightKg: Double = 20
    var incrementKg: Double = 2.5
    var progression: ProgressionRule = .doubleProgression
    var supersetGroup: Int = 0

    init(name: String, muscle: Muscle) {
        self.name = name
        self.muscle = muscle
    }

    init(from ex: RoutineExercise) {
        name = ex.name
        muscle = ex.muscle
        targetSets = ex.targetSets
        repLow = ex.repLow
        repHigh = ex.repHigh
        restSeconds = ex.restSeconds
        startWeightKg = ex.startWeightKg
        incrementKg = ex.incrementKg
        progression = ex.progression
        supersetGroup = ex.supersetGroup
    }
}

/// Creates a new routine (pass nil) or edits an existing one. Edits a draft;
/// nothing touches SwiftData until Save passes validation.
struct RoutineEditorView: View {
    let routine: Routine?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Routine.orderIndex) private var allRoutines: [Routine]
    @AppStorage("weightUnit") private var unitRaw = WeightUnit.kg.rawValue

    @State private var name = ""
    @State private var note = ""
    @State private var exercises: [ExerciseDraft] = []
    @State private var showPicker = false
    @State private var validationError: String?
    @State private var loaded = false

    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .kg }

    var body: some View {
        NavigationStack {
            Form {
                Section("Routine") {
                    TextField("Name (e.g. Upper Body)", text: $name)
                    TextField("Notes", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section {
                    if exercises.isEmpty {
                        Text("No exercises yet — add the first one below.")
                            .font(.subheadline)
                            .foregroundStyle(Brand.text3)
                    }
                    ForEach($exercises) { $draft in
                        DisclosureGroup {
                            ExerciseDraftFields(draft: $draft, unit: unit)
                        } label: {
                            HStack {
                                Text(draft.name).font(.body.weight(.medium))
                                Spacer()
                                Text("\(draft.targetSets)×\(draft.repLow)–\(draft.repHigh)")
                                    .font(Brand.mono(13))
                                    .foregroundStyle(Brand.text3)
                            }
                        }
                    }
                    .onDelete { exercises.remove(atOffsets: $0) }
                    .onMove { exercises.move(fromOffsets: $0, toOffset: $1) }

                    Button {
                        showPicker = true
                    } label: {
                        Label("Add exercise", systemImage: "plus.circle.fill")
                    }
                } header: {
                    HStack {
                        Text("Exercises")
                        Spacer()
                        EditButton()
                            .font(.caption)
                    }
                } footer: {
                    Text("Swipe to delete, drag to reorder. Give two exercises the same superset group to alternate them.")
                }

                if let error = validationError {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(Brand.danger)
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle(routine == nil ? "New Routine" : "Edit Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .sheet(isPresented: $showPicker) {
                ExercisePickerView { name, muscle in
                    exercises.append(ExerciseDraft(name: name, muscle: muscle))
                }
            }
            .onAppear {
                guard !loaded else { return }
                loaded = true
                if let r = routine {
                    name = r.name
                    note = r.note
                    exercises = r.orderedExercises.map(ExerciseDraft.init(from:))
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            validationError = "Give the routine a name."
            return
        }
        guard !exercises.isEmpty else {
            validationError = "Add at least one exercise."
            return
        }
        if let bad = exercises.first(where: { $0.repLow > $0.repHigh }) {
            validationError = "\(bad.name): the low end of the rep range is above the high end."
            return
        }

        if let r = routine {
            r.name = trimmed
            r.note = note
            r.exercises.removeAll()
            r.exercises = builtExercises()
        } else {
            let r = Routine(name: trimmed, note: note,
                            orderIndex: (allRoutines.map(\.orderIndex).max() ?? -1) + 1)
            context.insert(r)
            r.exercises = builtExercises()
        }
        Haptics.success()
        dismiss()
    }

    private func builtExercises() -> [RoutineExercise] {
        exercises.enumerated().map { index, d in
            RoutineExercise(
                name: d.name, muscle: d.muscle, orderIndex: index,
                targetSets: d.targetSets, repLow: d.repLow, repHigh: d.repHigh,
                restSeconds: d.restSeconds, startWeightKg: d.startWeightKg,
                incrementKg: d.incrementKg, progression: d.progression,
                supersetGroup: d.supersetGroup
            )
        }
    }
}

private struct ExerciseDraftFields: View {
    @Binding var draft: ExerciseDraft
    let unit: WeightUnit

    var body: some View {
        Stepper("Sets: \(draft.targetSets)", value: $draft.targetSets, in: 1...10)
        Stepper("Reps from: \(draft.repLow)", value: $draft.repLow, in: 1...30)
        Stepper("Reps to: \(draft.repHigh)", value: $draft.repHigh, in: 1...30)
        Stepper("Rest: \(Duration.mmss(draft.restSeconds))",
                value: $draft.restSeconds, in: 15...360, step: 15)
        Stepper(value: $draft.startWeightKg, in: 0...500, step: Double(unit == .kg ? 2.5 : 2.2675)) {
            Text("Start weight: \(unit.format(kg: draft.startWeightKg))")
        }
        Stepper(value: $draft.incrementKg, in: 0...20, step: 0.5) {
            Text("Increment: \(unit.format(kg: draft.incrementKg))")
        }
        Picker("Progression", selection: $draft.progression) {
            ForEach(ProgressionRule.allCases) { rule in
                Text(rule.label).tag(rule)
            }
        }
        Stepper(
            draft.supersetGroup == 0 ? "Superset: none" : "Superset group: \(draft.supersetGroup)",
            value: $draft.supersetGroup, in: 0...4
        )
        Text(draft.progression.explanation)
            .font(.caption)
            .foregroundStyle(Brand.text3)
    }
}
