import SwiftUI
import SwiftData

struct TemplateEditorView: View {
    enum Mode { case create, edit(BlockTemplate) }
    let mode: Mode

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var startTime = Date()
    @State private var durationMinutes = 60
    @State private var category: BlockCategory = .work
    @State private var notes = ""

    private var isEditing: Bool { if case .edit = mode { return true } else { return false } }
    private var canSave: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Routine name", text: $title).font(.headline)
                    Picker("Category", selection: $category) {
                        ForEach(BlockCategory.allCases) { c in
                            Label(c.title, systemImage: c.icon).tag(c)
                        }
                    }
                }
                Section("Default time") {
                    DatePicker("Starts at", selection: $startTime, displayedComponents: .hourAndMinute)
                    Picker("Duration", selection: $durationMinutes) {
                        ForEach([15, 30, 45, 60, 90, 120, 150, 180], id: \.self) { m in
                            Text(ScheduleEngine.durationString(m)).tag(m)
                        }
                    }
                }
                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical).lineLimit(2...5)
                }
                if case let .edit(t) = mode {
                    Section {
                        Button(role: .destructive) {
                            context.delete(t); try? context.save(); Haptics.warning(); dismiss()
                        } label: { Label("Delete routine", systemImage: "trash") }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Routine" : "New Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!canSave) }
            }
            .onAppear(perform: load)
        }
    }

    private func minuteOfDay(_ d: Date) -> Int {
        let c = Calendar.current.dateComponents([.hour, .minute], from: d)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    private func load() {
        switch mode {
        case .create:
            startTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: .now) ?? .now
        case .edit(let t):
            title = t.title
            durationMinutes = t.durationMinutes
            category = t.category
            notes = t.notes
            startTime = Calendar.current.date(bySettingHour: t.defaultStartMinute / 60,
                                              minute: t.defaultStartMinute % 60,
                                              second: 0, of: .now) ?? .now
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let minute = minuteOfDay(startTime)
        switch mode {
        case .create:
            let t = BlockTemplate(title: trimmed, defaultStartMinute: minute,
                                  durationMinutes: durationMinutes, category: category, notes: notes)
            context.insert(t)
        case .edit(let t):
            t.title = trimmed
            t.defaultStartMinute = minute
            t.durationMinutes = durationMinutes
            t.category = category
            t.notes = notes
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
