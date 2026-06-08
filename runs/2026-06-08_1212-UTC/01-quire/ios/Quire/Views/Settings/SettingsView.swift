import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var entries: [JournalEntry]

    @AppStorage("appearance") private var appearanceRaw = AppearanceMode.system.rawValue
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("sortNewestFirst") private var newestFirst = true
    @AppStorage("weekStartsMonday") private var weekStartsMonday = false
    @AppStorage("reminderEnabled") private var reminderEnabled = false
    @AppStorage("reminderTime") private var reminderTime = 1260.0  // minutes from midnight (21:00)

    @State private var showEraseConfirm = false

    private var reminderBinding: Binding<Date> {
        Binding(
            get: {
                let cal = Calendar.current
                let start = cal.startOfDay(for: .now)
                return cal.date(byAdding: .minute, value: Int(reminderTime), to: start) ?? start
            },
            set: { newValue in
                let cal = Calendar.current
                let comps = cal.dateComponents([.hour, .minute], from: newValue)
                reminderTime = Double((comps.hour ?? 21) * 60 + (comps.minute ?? 0))
            }
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section("Appearance") {
                        Picker("Theme", selection: $appearanceRaw) {
                            ForEach(AppearanceMode.allCases) { mode in
                                Text(mode.label).tag(mode.rawValue)
                            }
                        }
                    }

                    Section("Journal") {
                        Toggle("Newest entries first", isOn: $newestFirst)
                        Toggle("Week starts on Monday", isOn: $weekStartsMonday)
                    }

                    Section {
                        Toggle("Daily reminder", isOn: $reminderEnabled)
                        if reminderEnabled {
                            DatePicker("Time", selection: reminderBinding, displayedComponents: .hourAndMinute)
                        }
                    } header: {
                        Text("Reminder")
                    } footer: {
                        Text("A gentle nudge to write. Stored locally; enable notifications in iOS Settings to be alerted.")
                    }

                    Section("Feedback") {
                        Toggle("Haptics", isOn: $hapticsEnabled)
                    }

                    Section {
                        LabeledContent("Entries", value: "\(entries.count)")
                        Button(role: .destructive) {
                            showEraseConfirm = true
                        } label: {
                            Text("Erase all entries")
                        }
                        .disabled(entries.isEmpty)
                    } header: {
                        Text("Data")
                    } footer: {
                        Text("Quire stores everything on this device only. There is no account and nothing is uploaded.")
                    }

                    Section {
                        LabeledContent("Version", value: "1.0")
                    } header: {
                        Text("About")
                    } footer: {
                        Text("Quire — a calm place to think. Conjured, not just coded.")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Erase all entries? This can't be undone.",
                                isPresented: $showEraseConfirm, titleVisibility: .visible) {
                Button("Erase Everything", role: .destructive) { eraseAll() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func eraseAll() {
        for entry in entries { context.delete(entry) }
        try? context.save()
        Haptics.warning()
    }
}
