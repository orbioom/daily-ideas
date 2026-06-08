import SwiftUI
import SwiftData

struct TaskEditorView: View {
    enum Mode { case create, edit(ChecklistTask) }
    let mode: Mode

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var category: BudgetCategory = .other
    @State private var hasDueDate = true
    @State private var dueDate = Calendar.current.date(byAdding: .month, value: 1, to: .now) ?? .now
    @State private var notes = ""

    private var isEditing: Bool { if case .edit = mode { return true } else { return false } }
    private var canSave: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Task", text: $title)
                    Picker("Category", selection: $category) {
                        ForEach(BudgetCategory.allCases) { Label($0.title, systemImage: $0.icon).tag($0) }
                    }
                }
                Section {
                    Toggle("Has due date", isOn: $hasDueDate.animation())
                    if hasDueDate {
                        DatePicker("Due", selection: $dueDate, displayedComponents: .date)
                    }
                }
                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical).lineLimit(1...4)
                }
                if case let .edit(t) = mode {
                    Section {
                        Button(role: .destructive) {
                            context.delete(t); try? context.save(); Haptics.warning(); dismiss()
                        } label: { Label("Delete task", systemImage: "trash") }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Task" : "New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!canSave) }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        if case let .edit(t) = mode {
            title = t.title; category = t.category; notes = t.notes
            if let d = t.dueDate { hasDueDate = true; dueDate = d } else { hasDueDate = false }
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        switch mode {
        case .create:
            context.insert(ChecklistTask(title: trimmed, dueDate: hasDueDate ? dueDate : nil,
                                         category: category, notes: notes))
        case .edit(let t):
            t.title = trimmed; t.category = category
            t.dueDate = hasDueDate ? dueDate : nil; t.notes = notes
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
