import SwiftUI
import SwiftData

/// Create or edit a routine: name, color, and an ordered list of exercises with
/// target sets/reps. Supports add, reorder, delete.
struct RoutineEditorView: View {
    var existing: Routine?
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var detail = ""
    @State private var colorHex = "#EA7320"
    @State private var draftItems: [DraftItem] = []
    @State private var showPicker = false

    private let palette = ["#EA7320", "#7C5CC6", "#289A60", "#2E79D5", "#E25850", "#D89F1C"]

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmedName.isEmpty && !draftItems.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Push Day", text: $name)
                    TextField("Subtitle (optional)", text: $detail)
                }
                Section("Color") {
                    HStack(spacing: 12) {
                        ForEach(palette, id: \.self) { hex in
                            Circle().fill(Color(hex: hex)).frame(width: 30, height: 30)
                                .overlay(Circle().strokeBorder(Theme.textPrimary,
                                                               lineWidth: colorHex == hex ? 3 : 0))
                                .onTapGesture { colorHex = hex }
                                .accessibilityLabel("Color option")
                                .accessibilityAddTraits(colorHex == hex ? .isSelected : [])
                        }
                    }
                }
                Section("Exercises") {
                    if draftItems.isEmpty {
                        Text("Add at least one exercise.")
                            .font(.subheadline).foregroundStyle(Theme.textSecondary)
                    }
                    ForEach($draftItems) { $item in
                        DraftItemRow(item: $item)
                    }
                    .onDelete { draftItems.remove(atOffsets: $0) }
                    .onMove { draftItems.move(fromOffsets: $0, toOffset: $1) }
                    Button { showPicker = true } label: {
                        Label("Add Exercise", systemImage: "plus")
                    }
                }
            }
            .navigationTitle(existing == nil ? "New Routine" : "Edit Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }.fontWeight(.semibold).disabled(!canSave)
                }
                ToolbarItem(placement: .topBarLeading) {
                    if !draftItems.isEmpty { EditButton() }
                }
            }
            .sheet(isPresented: $showPicker) {
                ExercisePickerSheet { ex in
                    draftItems.append(DraftItem(exercise: ex, sets: 3, reps: 8))
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let existing else { return }
        name = existing.name
        detail = existing.detail
        colorHex = existing.colorHex
        draftItems = existing.orderedItems.compactMap { item in
            guard let ex = item.exercise else { return nil }
            return DraftItem(exercise: ex, sets: item.targetSets, reps: item.targetReps)
        }
    }

    private func save() {
        guard canSave else { return }
        let routine: Routine
        if let existing {
            routine = existing
            routine.name = trimmedName
            routine.detail = detail.trimmingCharacters(in: .whitespacesAndNewlines)
            routine.colorHex = colorHex
            for old in routine.items { context.delete(old) }
            routine.items.removeAll()
        } else {
            routine = Routine(name: trimmedName,
                              detail: detail.trimmingCharacters(in: .whitespacesAndNewlines),
                              colorHex: colorHex)
            context.insert(routine)
        }
        for (idx, draft) in draftItems.enumerated() {
            let item = RoutineItem(order: idx, targetSets: draft.sets, targetReps: draft.reps,
                                   routine: routine, exercise: draft.exercise)
            context.insert(item)
            routine.items.append(item)
        }
        try? context.save()
        dismiss()
    }
}

struct DraftItem: Identifiable {
    let id = UUID()
    let exercise: Exercise
    var sets: Int
    var reps: Int
}

struct DraftItemRow: View {
    @Binding var item: DraftItem
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.exercise.name).font(.body.weight(.medium)).foregroundStyle(Theme.textPrimary)
            HStack(spacing: 16) {
                Stepper("Sets: \(item.sets)", value: $item.sets, in: 1...12)
                    .font(.caption)
            }
            HStack(spacing: 16) {
                Stepper("Reps: \(item.reps)", value: $item.reps, in: 1...50)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.exercise.name), \(item.sets) sets of \(item.reps) reps")
    }
}
