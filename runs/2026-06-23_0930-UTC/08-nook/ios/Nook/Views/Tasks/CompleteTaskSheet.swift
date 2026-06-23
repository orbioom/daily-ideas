import SwiftUI
import SwiftData

/// Sheet shown when marking a task done: capture the completion date, optional
/// cost, vendor and a note, then advance the schedule.
struct CompleteTaskSheet: View {
    let task: MaintenanceTask
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var settingsRows: [AppSettings]

    @State private var date: Date = .now
    @State private var costText: String = ""
    @State private var vendor: String = ""
    @State private var note: String = ""

    private var settings: AppSettings { settingsRows.first ?? AppSettings() }

    private var parsedCost: Double {
        let cleaned = costText.replacingOccurrences(of: ",", with: ".")
        return max(0, Double(cleaned) ?? 0)
    }

    private var nextDuePreview: Date? {
        ScheduleEngine.advancedDueDate(for: task, completedOn: date)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(task.title)
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    if !task.detail.isEmpty {
                        Text(task.detail)
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                    }
                } header: {
                    Text("Completing")
                }

                Section("When") {
                    DatePicker("Completed on", selection: $date, in: ...Date.now, displayedComponents: .date)
                        .accessibilityLabel("Completion date")
                }

                Section("Cost (optional)") {
                    HStack {
                        Text(settings.currencyCode)
                            .foregroundStyle(Theme.textSecondary)
                        TextField("0", text: $costText)
                            .keyboardType(.decimalPad)
                            .accessibilityLabel("Cost")
                    }
                    TextField("Vendor or store", text: $vendor)
                        .accessibilityLabel("Vendor")
                }

                Section("Note (optional)") {
                    TextField("e.g. swapped 16x25x1 filter", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                        .accessibilityLabel("Note")
                }

                if let next = nextDuePreview {
                    Section {
                        Label("Next due \(Formatters.date(next))", systemImage: "arrow.uturn.forward")
                            .font(.subheadline)
                            .foregroundStyle(Theme.ok)
                    } footer: {
                        Text("Marking this done rolls the task forward by its \(task.recurrence.label.lowercased()) cadence.")
                    }
                } else {
                    Section {
                        Label("This one-time task will be archived", systemImage: "archivebox")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .navigationTitle("Mark Done")
            .navigationBarTitleDisplayMode(.inline)
            .background(Theme.bg)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .font(.body.weight(.semibold))
                }
            }
        }
    }

    private func save() {
        TaskService.complete(task,
                             on: date,
                             cost: parsedCost,
                             note: note.trimmingCharacters(in: .whitespacesAndNewlines),
                             vendor: vendor.trimmingCharacters(in: .whitespacesAndNewlines),
                             context: context)
        Haptics.success(enabled: settings.hapticsEnabled)
        dismiss()
    }
}

#Preview {
    CompleteTaskSheetPreview()
}

private struct CompleteTaskSheetPreview: View {
    var body: some View {
        Color.clear
            .previewModelContainer()
    }
}
