import SwiftUI
import SwiftData

/// Custom program builder (Pro). Compose days and exercises, then save.
struct ProgramBuilderView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @Query private var allPrograms: [Program]

    @State private var name = "My Program"
    @State private var days: [DraftDay] = [DraftDay(name: "Day 1")]
    @State private var editingExercise: ExerciseTarget?

    struct DraftDay: Identifiable {
        let id = UUID()
        var name: String
        var exercises: [DraftExercise] = []
    }

    struct DraftExercise: Identifiable {
        var id = UUID()
        var name: String
        var group: MuscleGroup
        var sets: Int
        var reps: Int
        var startKg: Double
        var incrementKg: Double
        var isAccessory: Bool
    }

    /// Identifies which day a new/edited exercise belongs to.
    struct ExerciseTarget: Identifiable {
        let id = UUID()
        let dayID: UUID
        var existing: DraftExercise?
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        days.contains { !$0.exercises.isEmpty }
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    nameCard
                    ForEach($days) { $day in
                        dayCard($day)
                    }
                    Button {
                        days.append(DraftDay(name: "Day \(days.count + 1)"))
                        Haptics.tap(settings.hapticsEnabled)
                    } label: {
                        Label("Add day", systemImage: "plus.circle")
                            .font(Theme.rounded(15, .semibold))
                            .foregroundStyle(Theme.accent)
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("New Program")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") { save() }.disabled(!canSave).fontWeight(.semibold)
            }
        }
        .sheet(item: $editingExercise) { target in
            NavigationStack {
                ExerciseEditorView(initial: target.existing) { result in
                    apply(result, to: target)
                }
            }
        }
    }

    private var nameCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                Text("Program name")
                    .font(Theme.rounded(13, .semibold))
                    .foregroundStyle(Theme.inkSoft)
                TextField("Program name", text: $name)
                    .font(Theme.rounded(18, .bold))
                    .foregroundStyle(Theme.ink)
                    .textInputAutocapitalization(.words)
            }
        }
    }

    private func dayCard(_ day: Binding<DraftDay>) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    TextField("Day name", text: day.name)
                        .font(Theme.rounded(17, .bold))
                        .foregroundStyle(Theme.ink)
                    if days.count > 1 {
                        Button {
                            removeDay(day.wrappedValue.id)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(Theme.bad)
                        }
                        .accessibilityLabel("Delete day")
                    }
                }
                if day.wrappedValue.exercises.isEmpty {
                    Text("No exercises yet.")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkFaint)
                } else {
                    ForEach(day.wrappedValue.exercises) { ex in
                        Button {
                            editingExercise = ExerciseTarget(dayID: day.wrappedValue.id, existing: ex)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(ex.name)
                                        .font(Theme.rounded(15, .semibold))
                                        .foregroundStyle(Theme.ink)
                                    Text("\(ex.sets) × \(ex.reps) · start \(settings.weight(ex.startKg))")
                                        .font(Theme.rounded(12))
                                        .foregroundStyle(Theme.inkSoft)
                                }
                                Spacer()
                                MuscleBadge(group: ex.group)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                Button {
                    editingExercise = ExerciseTarget(dayID: day.wrappedValue.id, existing: nil)
                } label: {
                    Label("Add exercise", systemImage: "plus.circle")
                        .font(Theme.rounded(14, .semibold))
                        .foregroundStyle(Theme.accent)
                }
            }
        }
    }

    // MARK: Mutations

    private func removeDay(_ id: UUID) {
        days.removeAll { $0.id == id }
    }

    private func apply(_ result: DraftExercise, to target: ExerciseTarget) {
        guard let dayIndex = days.firstIndex(where: { $0.id == target.dayID }) else { return }
        if let existing = target.existing,
           let exIndex = days[dayIndex].exercises.firstIndex(where: { $0.id == existing.id }) {
            days[dayIndex].exercises[exIndex] = result
        } else {
            days[dayIndex].exercises.append(result)
        }
    }

    private func save() {
        guard canSave else { return }
        for p in allPrograms where p.isActive { p.isActive = false }
        let program = Program(name: name.trimmingCharacters(in: .whitespaces),
                              type: .custom,
                              notes: "Custom program",
                              isActive: true)
        for (di, day) in days.enumerated() where !day.exercises.isEmpty {
            let pd = ProgramDay(name: day.name.isEmpty ? "Day \(di + 1)" : day.name, order: di)
            for (ei, ex) in day.exercises.enumerated() {
                let pe = ProgramExercise(name: ex.name,
                                         muscleGroup: ex.group,
                                         sets: ex.sets,
                                         reps: ex.reps,
                                         startingWeightKg: ex.startKg,
                                         incrementKg: ex.incrementKg,
                                         isAccessory: ex.isAccessory,
                                         order: ei)
                pe.day = pd
                pd.exercises.append(pe)
            }
            pd.program = program
            program.days.append(pd)
        }
        context.insert(program)
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }
}
