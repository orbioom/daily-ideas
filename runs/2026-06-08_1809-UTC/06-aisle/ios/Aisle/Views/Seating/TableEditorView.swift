import SwiftUI
import SwiftData

struct TableEditorView: View {
    enum Mode { case create, edit(SeatingTable) }
    let mode: Mode

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var capacity = 8

    private var isEditing: Bool { if case .edit = mode { return true } else { return false } }
    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Table name (e.g. Table 1)", text: $name)
                    Stepper("Capacity: \(capacity)", value: $capacity, in: 1...30)
                }
                if case let .edit(t) = mode {
                    Section {
                        Button(role: .destructive) {
                            context.delete(t); try? context.save(); Haptics.warning(); dismiss()
                        } label: { Label("Delete table", systemImage: "trash") }
                    } footer: {
                        Text("Deleting a table unseats its guests but keeps them on your list.")
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Table" : "New Table")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!canSave) }
            }
            .onAppear {
                if case let .edit(t) = mode { name = t.name; capacity = t.capacity }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        switch mode {
        case .create:
            context.insert(SeatingTable(name: trimmed, capacity: capacity))
        case .edit(let t):
            t.name = trimmed; t.capacity = capacity
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
