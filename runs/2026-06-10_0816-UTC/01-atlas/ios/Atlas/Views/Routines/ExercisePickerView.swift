import SwiftUI

/// Searchable library picker with a custom-exercise escape hatch.
struct ExercisePickerView: View {
    let onPick: (String, Muscle) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var search = ""
    @State private var customName = ""
    @State private var customMuscle: Muscle = .chest

    var body: some View {
        NavigationStack {
            List {
                Section("Custom exercise") {
                    TextField("Name your own", text: $customName)
                    Picker("Muscle group", selection: $customMuscle) {
                        ForEach(Muscle.allCases) { m in
                            Text(m.label).tag(m)
                        }
                    }
                    Button("Add custom exercise") {
                        let trimmed = customName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        onPick(trimmed, customMuscle)
                        Haptics.tap()
                        dismiss()
                    }
                    .disabled(customName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                ForEach(filteredGroups, id: \.muscle) { group in
                    Section(group.muscle.label) {
                        ForEach(group.exercises) { ex in
                            Button {
                                onPick(ex.name, ex.muscle)
                                Haptics.tap()
                                dismiss()
                            } label: {
                                HStack {
                                    Text(ex.name).foregroundStyle(Brand.text)
                                    Spacer()
                                    Image(systemName: "plus.circle")
                                        .foregroundStyle(Brand.text3)
                                        .accessibilityHidden(true)
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $search, prompt: "Search exercises")
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .overlay {
                if filteredGroups.isEmpty && !search.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "No matches",
                        message: "Nothing in the library matches “\(search)”. Add it as a custom exercise above."
                    )
                }
            }
        }
    }

    private var filteredGroups: [(muscle: Muscle, exercises: [CatalogExercise])] {
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        if q.isEmpty { return ExerciseCatalog.grouped() }
        return ExerciseCatalog.grouped().compactMap { group in
            let hits = group.exercises.filter { $0.name.lowercased().contains(q) }
            return hits.isEmpty ? nil : (group.muscle, hits)
        }
    }
}
