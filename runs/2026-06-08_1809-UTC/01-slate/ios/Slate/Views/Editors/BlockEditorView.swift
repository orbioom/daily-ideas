import SwiftUI
import SwiftData

struct BlockEditorView: View {
    enum Mode {
        case create
        case edit(TimeBlock)
    }

    let mode: Mode
    let defaultDay: Date

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("slate.defaultDuration") private var defaultDuration = 60

    @State private var title = ""
    @State private var notes = ""
    @State private var start = Date()
    @State private var durationMinutes = 60
    @State private var category: BlockCategory = .work
    @State private var checklistTitles: [String] = []
    @State private var newChecklistItem = ""

    private var isEditing: Bool { if case .edit = mode { return true } else { return false } }

    private var canSave: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("What is this block?", text: $title)
                        .font(.headline)
                    Picker("Category", selection: $category) {
                        ForEach(BlockCategory.allCases) { c in
                            Label(c.title, systemImage: c.icon).tag(c)
                        }
                    }
                }

                Section("Time") {
                    DatePicker("Starts", selection: $start)
                    Picker("Duration", selection: $durationMinutes) {
                        ForEach(durationOptions, id: \.self) { m in
                            Text(ScheduleEngine.durationString(m)).tag(m)
                        }
                    }
                    LabeledContent("Ends",
                                   value: ScheduleEngine.clockString(
                                    minuteOfDay: minuteOfDay(start) + durationMinutes))
                }

                Section("Checklist") {
                    ForEach(Array(checklistTitles.enumerated()), id: \.offset) { idx, item in
                        HStack {
                            Image(systemName: "circle")
                                .foregroundStyle(Brand.text3)
                            Text(item)
                        }
                    }
                    .onDelete { checklistTitles.remove(atOffsets: $0) }

                    HStack {
                        TextField("Add a step", text: $newChecklistItem)
                            .onSubmit(addChecklistItem)
                        Button(action: addChecklistItem) {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(newChecklistItem.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                if case let .edit(block) = mode {
                    Section {
                        Button(role: .destructive) {
                            context.delete(block)
                            try? context.save()
                            Haptics.warning()
                            dismiss()
                        } label: {
                            Label("Delete block", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Block" : "New Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!canSave)
                }
            }
            .onAppear(perform: load)
        }
    }

    private var durationOptions: [Int] {
        [15, 30, 45, 60, 90, 120, 150, 180, 240]
    }

    private func minuteOfDay(_ d: Date) -> Int {
        let c = Calendar.current.dateComponents([.hour, .minute], from: d)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    private func addChecklistItem() {
        let t = newChecklistItem.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        checklistTitles.append(t)
        newChecklistItem = ""
        Haptics.tap()
    }

    private func load() {
        switch mode {
        case .create:
            let cal = Calendar.current
            // default to the next round hour on the chosen day
            let hour = min(max(cal.component(.hour, from: .now) + 1, 7), 21)
            start = cal.date(bySettingHour: hour, minute: 0, second: 0, of: defaultDay) ?? defaultDay
            durationMinutes = defaultDuration
        case .edit(let block):
            title = block.title
            notes = block.notes
            start = block.start
            durationMinutes = block.durationMinutes
            category = block.category
            checklistTitles = block.checklist.sorted { $0.order < $1.order }.map(\.title)
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        switch mode {
        case .create:
            let block = TimeBlock(title: trimmed, start: start,
                                  durationMinutes: durationMinutes,
                                  category: category, notes: notes)
            context.insert(block)
            for (i, t) in checklistTitles.enumerated() {
                let item = ChecklistItem(title: t, order: i)
                item.block = block
                context.insert(item)
            }
        case .edit(let block):
            block.title = trimmed
            block.notes = notes
            block.start = start
            block.durationMinutes = durationMinutes
            block.category = category
            // rebuild checklist to match the edited titles
            for old in block.checklist { context.delete(old) }
            for (i, t) in checklistTitles.enumerated() {
                let item = ChecklistItem(title: t, order: i)
                item.block = block
                context.insert(item)
            }
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
