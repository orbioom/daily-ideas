import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var allSettings: [NourishSettings]
    private var settings: NourishSettings? { allSettings.first }

    var body: some View {
        NavigationStack {
            Form {
                if let s = settings {
                    Section("Notifications") {
                        Toggle("Daily Reminders", isOn: Binding(get: { s.notificationsEnabled }, set: { s.notificationsEnabled = $0 }))
                        if s.notificationsEnabled {
                            DatePicker("Reminder Time",
                                selection: Binding(
                                    get: { Calendar.current.date(bySettingHour: s.reminderHour, minute: s.reminderMinute, second: 0, of: Date()) ?? Date() },
                                    set: { d in
                                        s.reminderHour = Calendar.current.component(.hour, from: d)
                                        s.reminderMinute = Calendar.current.component(.minute, from: d)
                                    }
                                ),
                                displayedComponents: .hourAndMinute
                            )
                        }
                    }
                    Section("Preferences") {
                        Toggle("Haptic Feedback", isOn: Binding(get: { s.hapticsEnabled }, set: { s.hapticsEnabled = $0 }))
                        Picker("Correlation Window", selection: Binding(get: { CorrelationWindow(rawValue: s.windowHoursForCorrelation) ?? .twentyFour }, set: { s.windowHoursForCorrelation = $0.rawValue })) {
                            ForEach(CorrelationWindow.allCases) { w in Text(w.displayName).tag(w) }
                        }
                    }
                    Section("Primary Goal") {
                        Picker("Goal", selection: Binding(get: { PrimaryGoal(rawValue: s.primaryGoal) ?? .elimination }, set: { s.primaryGoal = $0.rawValue })) {
                            ForEach(PrimaryGoal.allCases) { g in Text(g.displayName).tag(g) }
                        }
                    }
                }
                Section("About") {
                    HStack { Text("Version"); Spacer(); Text("1.0").foregroundStyle(.secondary) }
                    Link("Privacy Policy", destination: URL(string: "https://orbioom.com/privacy")!)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
