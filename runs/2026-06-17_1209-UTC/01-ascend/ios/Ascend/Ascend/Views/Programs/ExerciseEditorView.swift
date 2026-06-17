import SwiftUI

/// Editor sheet for one exercise inside the custom builder.
struct ExerciseEditorView: View {
    let initial: ProgramBuilderView.DraftExercise?
    let onSave: (ProgramBuilderView.DraftExercise) -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    @State private var name: String
    @State private var group: MuscleGroup
    @State private var sets: Int
    @State private var reps: Int
    @State private var startText: String
    @State private var incrementText: String
    @State private var isAccessory: Bool

    private var unit: WeightUnit { settings.unit }

    init(initial: ProgramBuilderView.DraftExercise?,
         onSave: @escaping (ProgramBuilderView.DraftExercise) -> Void) {
        self.initial = initial
        self.onSave = onSave
        _name = State(initialValue: initial?.name ?? "")
        _group = State(initialValue: initial?.group ?? .chest)
        _sets = State(initialValue: initial?.sets ?? 3)
        _reps = State(initialValue: initial?.reps ?? 5)
        _isAccessory = State(initialValue: initial?.isAccessory ?? false)
        // Display values respect the user's unit; default storage stays kg.
        let u = WeightUnit(rawValue: UserDefaults.standard.string(forKey: "weightUnitRaw") ?? "kg") ?? .kg
        let start = initial?.startKg ?? 20
        let inc = initial?.incrementKg ?? 2.5
        _startText = State(initialValue: Units.formatNumber(start, unit: u))
        _incrementText = State(initialValue: Units.formatNumber(inc, unit: u))
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        Form {
            Section("Exercise") {
                TextField("Name", text: $name)
                    .textInputAutocapitalization(.words)
                Picker("Muscle group", selection: $group) {
                    ForEach(MuscleGroup.allCases) { g in
                        Label(g.label, systemImage: g.symbol).tag(g)
                    }
                }
                Toggle("Accessory lift", isOn: $isAccessory)
            }

            Section("Prescription") {
                Stepper("Sets: \(sets)", value: $sets, in: 1...10)
                Stepper("Reps: \(reps)", value: $reps, in: 1...30)
            }

            Section("Weights (\(unit.label))") {
                LabeledContent("Starting") {
                    TextField("0", text: $startText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                LabeledContent("Increment") {
                    TextField("0", text: $incrementText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .navigationTitle(initial == nil ? "Add Exercise" : "Edit Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") { commit() }.disabled(!canSave).fontWeight(.semibold)
            }
        }
    }

    private func commit() {
        let startKg = Units.fromDisplay(parse(startText), unit: unit)
        let incKg = Units.fromDisplay(parse(incrementText), unit: unit)
        let result = ProgramBuilderView.DraftExercise(
            name: name.trimmingCharacters(in: .whitespaces),
            group: group,
            sets: max(sets, 1),
            reps: max(reps, 1),
            startKg: max(startKg, 0),
            incrementKg: max(incKg, 0),
            isAccessory: isAccessory
        )
        // Preserve identity on edit so the builder replaces in place.
        if let initial {
            onSave(ProgramBuilderView.DraftExercise(
                id: initial.id,
                name: result.name, group: result.group, sets: result.sets,
                reps: result.reps, startKg: result.startKg,
                incrementKg: result.incrementKg, isAccessory: result.isAccessory))
        } else {
            onSave(result)
        }
        Haptics.tap(settings.hapticsEnabled)
        dismiss()
    }

    private func parse(_ text: String) -> Double {
        Double(text.replacingOccurrences(of: ",", with: ".")) ?? 0
    }
}
