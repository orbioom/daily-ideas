import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var settings: [CrescentSettings]
    @Environment(\.modelContext) private var context

    private var s: CrescentSettings? { settings.first }

    var body: some View {
        NavigationStack {
            ZStack {
                CrescentTheme.navy.ignoresSafeArea()
                Form {
                    Section("Notifications") {
                        Toggle("Moon Phase Reminders", isOn: Binding(
                            get: { s?.reminderEnabled ?? false },
                            set: { s?.reminderEnabled = $0 }
                        ))
                        .foregroundColor(CrescentTheme.pearl)
                        if s?.reminderEnabled == true {
                            HStack {
                                Text("Reminder Time")
                                    .foregroundColor(CrescentTheme.pearl)
                                Spacer()
                                DatePicker("", selection: Binding(
                                    get: {
                                        let h = s?.reminderHour ?? 20
                                        let m = s?.reminderMinute ?? 0
                                        return Calendar.current.date(bySettingHour: h, minute: m, second: 0, of: Date()) ?? Date()
                                    },
                                    set: { d in
                                        s?.reminderHour   = Calendar.current.component(.hour,   from: d)
                                        s?.reminderMinute = Calendar.current.component(.minute, from: d)
                                    }
                                ), displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .colorScheme(.dark)
                            }
                        }
                    }
                    .listRowBackground(CrescentTheme.cardBg)

                    Section("Experience") {
                        Toggle("Haptic Feedback", isOn: Binding(
                            get: { s?.hapticsEnabled ?? true },
                            set: { s?.hapticsEnabled = $0 }
                        ))
                        .foregroundColor(CrescentTheme.pearl)
                    }
                    .listRowBackground(CrescentTheme.cardBg)

                    Section("About") {
                        HStack {
                            Text("Version").foregroundColor(CrescentTheme.pearl)
                            Spacer()
                            Text("1.0").foregroundColor(CrescentTheme.silver)
                        }
                        HStack {
                            Text("Moon Algorithm").foregroundColor(CrescentTheme.pearl)
                            Spacer()
                            Text("Synodic Cycle").foregroundColor(CrescentTheme.silver)
                        }
                    }
                    .listRowBackground(CrescentTheme.cardBg)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
