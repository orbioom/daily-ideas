import SwiftUI
import SwiftData

/// Add or edit a single set. Can pick an existing lift or create a new one.
struct SetEntryEditView: View {
    let workout: Workout
    let set: SetEntry?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage("weightUnit") private var unitRaw = WeightUnit.kg.rawValue
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    @State private var mode = 0   // 0 = existing, 1 = new
    @State private var selectedExercise: Exercise?
    @State private var newName = ""
    @State private var newGroup: MuscleGroup = .other
    @State private var weightText = ""
    @State private var repsText = ""
    @State private var rpe: Double = 0
    @State private var isWarmup = false

    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .kg }
    private var isNew: Bool { set == nil }
    private var canSave: Bool {
        let hasExercise = mode == 0 ? selectedExercise != nil
            : !newName.trimmingCharacters(in: .whitespaces).isEmpty
        return hasExercise && (Int(repsText) ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Lift") {
                    if !exercises.isEmpty {
                        Picker("Source", selection: $mode) {
                            Text("Existing").tag(0); Text("New").tag(1)
                        }.pickerStyle(.segmented)
                    }
                    if mode == 0 && !exercises.isEmpty {
                        Picker("Exercise", selection: $selectedExercise) {
                            Text("Choose…").tag(Optional<Exercise>.none)
                            ForEach(exercises) { Text($0.name).tag(Optional($0)) }
                        }
                    } else {
                        TextField("New exercise name", text: $newName)
                        Picker("Group", selection: $newGroup) {
                            ForEach(MuscleGroup.allCases) { Text($0.label).tag($0) }
                        }
                    }
                }
                Section("Set") {
                    HStack {
                        Text("Weight (\(unit.short))")
                        Spacer()
                        TextField("0", text: $weightText).keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing).frame(width: 90).font(Brand.mono(16))
                    }
                    HStack {
                        Text("Reps")
                        Spacer()
                        TextField("0", text: $repsText).keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing).frame(width: 90).font(Brand.mono(16))
                    }
                    VStack(alignment: .leading) {
                        HStack {
                            Text("RPE")
                            Spacer()
                            Text(rpe == 0 ? "—" : rpeText(rpe)).foregroundStyle(Brand.text2).font(Brand.mono(15))
                        }
                        Slider(value: $rpe, in: 0...10, step: 0.5)
                    }
                    Toggle("Warm-up set", isOn: $isWarmup)
                }
                if let preview = ormPreview {
                    Section { Text(preview).font(.subheadline).foregroundStyle(Brand.text2) }
                }
            }
            .scrollContentBackground(.hidden).background(Brand.pageBackground)
            .navigationTitle(isNew ? "Add Set" : "Edit Set")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!canSave).fontWeight(.semibold)
                }
            }
            .onAppear(perform: load)
        }
    }

    private var ormPreview: String? {
        guard let reps = Int(repsText), reps > 0,
              let w = Double(weightText.replacingOccurrences(of: ",", with: ".")), w > 0,
              !isWarmup else { return nil }
        let kg = unit.toKg(w)
        let orm = StrengthMath.oneRepMax(weight: kg, reps: reps, formula: .epley)
        return "Estimated 1RM: \(Fmt.weight(orm, unit: unit))"
    }

    private func load() {
        if exercises.isEmpty { mode = 1 }
        guard let s = set else {
            selectedExercise = exercises.first
            return
        }
        selectedExercise = s.exercise
        weightText = s.weightKg > 0 ? Fmt.weightValue(s.weightKg, unit: unit) : ""
        repsText = s.reps > 0 ? String(s.reps) : ""
        rpe = s.rpe
        isWarmup = s.isWarmup
        mode = 0
    }

    private func save() {
        let exercise: Exercise
        if mode == 1 || exercises.isEmpty {
            let e = Exercise(name: newName.trimmingCharacters(in: .whitespaces), group: newGroup)
            context.insert(e)
            exercise = e
        } else if let sel = selectedExercise {
            exercise = sel
        } else { return }

        let reps = max(0, Int(repsText) ?? 0)
        let kg = unit.toKg(max(0, Double(weightText.replacingOccurrences(of: ",", with: ".")) ?? 0))
        let target = set ?? SetEntry(exercise: exercise)
        target.exercise = exercise
        target.weightKg = kg
        target.reps = reps
        target.rpe = rpe
        target.isWarmup = isWarmup
        if set == nil {
            target.order = (workout.sets.map(\.order).max() ?? -1) + 1
            target.workout = workout
            workout.sets.append(target)
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }

    private func rpeText(_ v: Double) -> String { v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v) }
}
