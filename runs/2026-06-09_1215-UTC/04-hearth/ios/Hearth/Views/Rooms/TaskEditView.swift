import SwiftUI
import SwiftData

/// Add or edit a cleaning task within a room. Frequency and estimated minutes
/// are clamped to the model's valid ranges.
struct TaskEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let room: Room
    let task: CleaningTask?
    let nextSortIndex: Int

    @State private var name: String
    @State private var frequencyDays: Int
    @State private var estMinutes: Int
    @State private var markDoneNow: Bool

    init(room: Room, task: CleaningTask?, nextSortIndex: Int) {
        self.room = room
        self.task = task
        self.nextSortIndex = nextSortIndex
        _name = State(initialValue: task?.name ?? "")
        _frequencyDays = State(initialValue: task?.frequencyDays ?? 7)
        _estMinutes = State(initialValue: task?.estMinutes ?? 10)
        _markDoneNow = State(initialValue: task?.lastDone != nil)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var canSave: Bool { !trimmedName.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Task name", text: $name)
                        .textInputAutocapitalization(.sentences)
                }

                Section("How often") {
                    Stepper(value: $frequencyDays, in: 1...365) {
                        LabeledContent("Every") {
                            Text("\(frequencyDays) \(frequencyDays == 1 ? "day" : "days")")
                                .foregroundStyle(Brand.text2)
                        }
                    }
                    Text(Format.cadence(days: frequencyDays))
                        .font(.footnote)
                        .foregroundStyle(Brand.text3)
                }

                Section("Estimated time") {
                    Stepper(value: $estMinutes, in: 0...600, step: 5) {
                        LabeledContent("Minutes") {
                            Text(Format.duration(minutes: estMinutes))
                                .foregroundStyle(Brand.text2)
                        }
                    }
                }

                Section {
                    Toggle("Mark as just done", isOn: $markDoneNow)
                } footer: {
                    Text(markDoneNow
                         ? "Resets the freshness clock from now."
                         : "Left off, this task counts as never done — it'll show as due right away.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle(task == nil ? "New Task" : "Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        let lastDone: Date? = markDoneNow ? .now : nil
        if let task {
            task.update(name: trimmedName, frequencyDays: frequencyDays, estMinutes: estMinutes)
            task.roomName = room.name
            // Only flip lastDone when the toggle state changed meaningfully.
            if markDoneNow && task.lastDone == nil { task.lastDone = .now }
            if !markDoneNow { task.lastDone = nil }
        } else {
            let new = CleaningTask(name: trimmedName,
                                   frequencyDays: frequencyDays,
                                   lastDone: lastDone,
                                   estMinutes: estMinutes,
                                   sortIndex: nextSortIndex,
                                   roomName: room.name)
            new.room = room
            context.insert(new)
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
