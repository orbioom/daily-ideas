import SwiftUI
import SwiftData

/// Create or edit a custom exercise. Validates a non-empty, unique name.
struct ExerciseEditorView: View {
    var existing: Exercise?
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var allExercises: [Exercise]

    @State private var name = ""
    @State private var muscle: MuscleGroup = .chest
    @State private var equipment: Equipment = .barbell
    @State private var notes = ""

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var nameError: String? {
        if trimmedName.isEmpty { return nil }
        let clash = allExercises.contains {
            $0.id != existing?.id && $0.name.localizedCaseInsensitiveCompare(trimmedName) == .orderedSame
        }
        return clash ? "An exercise with this name already exists." : nil
    }

    private var canSave: Bool { !trimmedName.isEmpty && nameError == nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Landmine Press", text: $name)
                        .accessibilityLabel("Exercise name")
                    if let nameError {
                        Label(nameError, systemImage: "exclamationmark.triangle")
                            .font(.caption).foregroundStyle(Theme.coral)
                    }
                }
                Section("Muscle group") {
                    Picker("Muscle", selection: $muscle) {
                        ForEach(MuscleGroup.allCases) { Text($0.display).tag($0) }
                    }
                }
                Section("Equipment") {
                    Picker("Equipment", selection: $equipment) {
                        ForEach(Equipment.allCases) { Text($0.display).tag($0) }
                    }
                }
                Section("Notes") {
                    TextField("Cues, setup, reminders…", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle(existing == nil ? "New Exercise" : "Edit Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }.fontWeight(.semibold).disabled(!canSave)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let existing else { return }
        name = existing.name
        muscle = existing.muscle
        equipment = existing.equipment
        notes = existing.notes
    }

    private func save() {
        guard canSave else { return }
        if let existing {
            existing.name = trimmedName
            existing.muscle = muscle
            existing.equipment = equipment
            existing.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            let ex = Exercise(name: trimmedName, muscle: muscle, equipment: equipment,
                              notes: notes.trimmingCharacters(in: .whitespacesAndNewlines), isCustom: true)
            context.insert(ex)
        }
        try? context.save()
        dismiss()
    }
}

#Preview {
    ExerciseEditorView().modelContainer(PersistenceController.preview)
}
