import SwiftUI
import SwiftData

/// Create or edit a future goal. Validates a non-empty title and a future target date.
struct GoalEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    let goal: FutureGoal?
    let palette: Palette

    @State private var title: String
    @State private var targetDate: Date
    @State private var hex: String
    @State private var note: String

    init(goal: FutureGoal?, palette: Palette) {
        self.goal = goal
        self.palette = palette
        _title = State(initialValue: goal?.title ?? "")
        _targetDate = State(initialValue: goal?.targetDate ?? Self.defaultTarget)
        _hex = State(initialValue: goal?.colorHex ?? palette.hexes.first ?? "E8A84B")
        _note = State(initialValue: goal?.note ?? "")
    }

    private static var defaultTarget: Date {
        Calendar(identifier: .gregorian).date(byAdding: .day, value: 100, to: Date()) ?? Date()
    }

    private var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var isValid: Bool { !trimmedTitle.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Future goal") {
                    TextField("Title", text: $title)
                    DatePicker("Target date", selection: $targetDate, displayedComponents: .date)
                }
                Section("Color") {
                    ColorPickerRow(hex: $hex, palette: palette)
                        .padding(.vertical, 2)
                }
                Section("Note (optional)") {
                    TextField("What this means to you", text: $note, axis: .vertical)
                        .lineLimit(1...4)
                }
                if goal != nil {
                    Section {
                        Button(role: .destructive) { deleteItem() } label: {
                            Label("Delete goal", systemImage: "trash")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(goal == nil ? "New Goal" : "Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!isValid)
                }
            }
        }
    }

    private func save() {
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        if let goal {
            goal.title = trimmedTitle
            goal.targetDate = targetDate
            goal.colorHex = hex
            goal.note = trimmedNote.isEmpty ? nil : trimmedNote
        } else {
            let new = FutureGoal(title: trimmedTitle,
                                 targetDate: targetDate,
                                 note: trimmedNote.isEmpty ? nil : trimmedNote,
                                 colorHex: hex)
            context.insert(new)
        }
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }

    private func deleteItem() {
        if let goal { context.delete(goal); try? context.save() }
        Haptics.light(settings.hapticsEnabled)
        dismiss()
    }
}
