import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var rooms: [Room]
    @Query private var logs: [CompletionLog]

    @AppStorage("hearth.onboarded") private var onboarded = true
    @AppStorage("hearth.haptics") private var haptics = true
    @AppStorage("hearth.soonWindowDays") private var soonWindowDays = 3
    @AppStorage("hearth.showEstimatedTime") private var showEstimatedTime = true
    @AppStorage("hearth.includeSoonInToday") private var includeSoonInToday = false

    @State private var showResetConfirm = false

    private var totalTasks: Int { rooms.reduce(0) { $0 + $1.tasks.count } }

    var body: some View {
        Form {
            Section("Today") {
                Stepper(value: $soonWindowDays, in: 1...7) {
                    LabeledContent("\"Soon\" window") {
                        Text("\(soonWindowDays) \(soonWindowDays == 1 ? "day" : "days")")
                            .foregroundStyle(Brand.text2)
                    }
                }
                Toggle("Show \"due soon\" on Today", isOn: $includeSoonInToday)
                Toggle("Show estimated time", isOn: $showEstimatedTime)
            } footer: {
                Text("Tasks due within the soon window are flagged ahead of time. Optionally surface them on the Today screen.")
            }

            Section("Feedback") {
                Toggle("Haptics", isOn: $haptics)
            }

            Section("Your home") {
                LabeledContent("Rooms", value: "\(rooms.count)")
                LabeledContent("Tasks", value: "\(totalTasks)")
                LabeledContent("Completions logged", value: "\(logs.count)")
            }

            Section {
                Button {
                    Haptics.tap()
                    onboarded = false
                } label: {
                    Label("Replay intro", systemImage: "sparkles")
                }
            } footer: {
                Text("Shows the welcome screens again. Your rooms and history are kept.")
            }

            Section {
                Button(role: .destructive) {
                    showResetConfirm = true
                } label: {
                    Label("Delete all data", systemImage: "trash")
                }
            } footer: {
                Text("Removes every room, task, and logged completion. This can't be undone. Everything stays on this device.")
            }

            Section {
                LabeledContent("Hearth", value: "1.0")
            } footer: {
                Text("Conjured, not just coded. A calm home-cleaning rotation, stored entirely on-device.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle("Settings")
        .confirmationDialog("Delete all data?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Delete everything", role: .destructive) { deleteAll() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently removes all rooms, tasks, and history.")
        }
    }

    private func deleteAll() {
        for room in rooms { context.delete(room) }
        for log in logs { context.delete(log) }
        try? context.save()
        Haptics.warning()
    }
}
