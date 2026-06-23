import SwiftUI
import SwiftData

/// Create or edit a maintenance task. `task == nil` means create.
struct TaskEditorView: View {
    let task: MaintenanceTask?
    var presetRoom: Room? = nil
    var presetAppliance: Appliance? = nil

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Room.name) private var rooms: [Room]
    @Query(sort: \Appliance.name) private var appliances: [Appliance]
    @Query private var settingsRows: [AppSettings]

    @State private var title = ""
    @State private var detail = ""
    @State private var recurrence: Recurrence = .quarterly
    @State private var nextDue: Date = .now
    @State private var minutes: Int = 15
    @State private var isActive = true
    @State private var roomID: UUID?
    @State private var applianceID: UUID?
    @State private var didLoad = false
    @State private var showValidation = false

    private var settings: AppSettings { settingsRows.first ?? AppSettings() }
    private var isEditing: Bool { task != nil }
    private var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmedTitle.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Title (e.g. Replace HVAC filter)", text: $title)
                        .accessibilityLabel("Task title")
                    if showValidation && trimmedTitle.isEmpty {
                        Text("A title is required.")
                            .font(.caption)
                            .foregroundStyle(Theme.overdue)
                    }
                    TextField("Details (optional)", text: $detail, axis: .vertical)
                        .lineLimit(2...5)
                        .accessibilityLabel("Task details")
                }

                Section("Schedule") {
                    Picker("Repeats", selection: $recurrence) {
                        ForEach(Recurrence.allCases) { rec in
                            Label(rec.label, systemImage: rec.systemImage).tag(rec)
                        }
                    }
                    DatePicker("Next due", selection: $nextDue, displayedComponents: .date)
                    Stepper(value: $minutes, in: 0...480, step: 5) {
                        HStack {
                            Text("Est. time")
                            Spacer()
                            Text(Formatters.minutes(minutes))
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                    .accessibilityValue(Formatters.minutes(minutes))
                    Toggle("Active", isOn: $isActive)
                }

                Section("Location") {
                    Picker("Room", selection: $roomID) {
                        Text("Unassigned").tag(UUID?.none)
                        ForEach(rooms) { room in
                            Text(room.name).tag(UUID?.some(room.id))
                        }
                    }
                    Picker("Equipment", selection: $applianceID) {
                        Text("None").tag(UUID?.none)
                        ForEach(appliances) { appliance in
                            Text(appliance.name).tag(UUID?.some(appliance.id))
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Task" : "New Task")
            .navigationBarTitleDisplayMode(.inline)
            .background(Theme.bg)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .font(.body.weight(.semibold))
                        .disabled(!canSave)
                }
            }
            .onAppear(perform: loadIfNeeded)
        }
    }

    private func loadIfNeeded() {
        guard !didLoad else { return }
        didLoad = true
        if let task {
            title = task.title
            detail = task.detail
            recurrence = task.recurrence
            nextDue = task.nextDue
            minutes = task.estimatedMinutes
            isActive = task.isActive
            roomID = task.room?.id
            applianceID = task.appliance?.id
        } else {
            roomID = presetRoom?.id
            applianceID = presetAppliance?.id
            if let presetAppliance { roomID = roomID ?? presetAppliance.room?.id }
        }
    }

    private func save() {
        guard canSave else { showValidation = true; return }
        let room = rooms.first { $0.id == roomID }
        let appliance = appliances.first { $0.id == applianceID }

        if let task {
            task.title = trimmedTitle
            task.detail = detail.trimmingCharacters(in: .whitespacesAndNewlines)
            task.recurrence = recurrence
            task.nextDue = nextDue
            task.estimatedMinutes = max(0, minutes)
            task.isActive = isActive
            task.room = room
            task.appliance = appliance
        } else {
            let newTask = MaintenanceTask(title: trimmedTitle,
                                          detail: detail.trimmingCharacters(in: .whitespacesAndNewlines),
                                          recurrence: recurrence,
                                          nextDue: nextDue,
                                          estimatedMinutes: max(0, minutes),
                                          isActive: isActive,
                                          room: room,
                                          appliance: appliance)
            context.insert(newTask)
        }
        try? context.save()
        Haptics.tap(enabled: settings.hapticsEnabled)
        dismiss()
    }
}

#Preview {
    TaskEditorView(task: nil)
        .previewModelContainer()
}
