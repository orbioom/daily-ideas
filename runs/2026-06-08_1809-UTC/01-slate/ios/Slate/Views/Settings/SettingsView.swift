import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @AppStorage("slate.dayStartHour") private var dayStartHour = 6
    @AppStorage("slate.dayEndHour") private var dayEndHour = 23
    @AppStorage("slate.defaultDuration") private var defaultDuration = 60
    @AppStorage("slate.haptics") private var haptics = true
    @AppStorage("slate.showCompleted") private var showCompleted = true

    @State private var showResetConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Timeline") {
                    Picker("Day starts", selection: $dayStartHour) {
                        ForEach(0...10, id: \.self) { h in
                            Text(ScheduleEngine.clockString(minuteOfDay: h * 60)).tag(h)
                        }
                    }
                    Picker("Day ends", selection: $dayEndHour) {
                        ForEach(15...23, id: \.self) { h in
                            Text(ScheduleEngine.clockString(minuteOfDay: h * 60)).tag(h)
                        }
                    }
                    if dayEndHour <= dayStartHour {
                        Label("End time should be after start time.", systemImage: "exclamationmark.triangle")
                            .font(.caption).foregroundStyle(Brand.warn)
                    }
                }

                Section("Defaults") {
                    Picker("New block length", selection: $defaultDuration) {
                        ForEach([15, 30, 45, 60, 90, 120], id: \.self) { m in
                            Text(ScheduleEngine.durationString(m)).tag(m)
                        }
                    }
                    Toggle("Show completed in Agenda", isOn: $showCompleted)
                }

                Section("Feel") {
                    Toggle("Haptics", isOn: $haptics)
                        .onChange(of: haptics) { _, new in Haptics.enabled = new }
                }

                Section {
                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: {
                        Label("Erase all blocks & routines", systemImage: "trash")
                    }
                } footer: {
                    Text("Everything in Slate stays on this device. Nothing is uploaded.")
                }

                Section {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Made by", value: "Orbioom")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .confirmationDialog("Erase everything?", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Erase all", role: .destructive, action: eraseAll)
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This permanently deletes every block and routine. This can't be undone.")
            }
        }
    }

    private func eraseAll() {
        try? context.delete(model: TimeBlock.self)
        try? context.delete(model: ChecklistItem.self)
        try? context.delete(model: BlockTemplate.self)
        try? context.save()
        Haptics.warning()
    }
}
