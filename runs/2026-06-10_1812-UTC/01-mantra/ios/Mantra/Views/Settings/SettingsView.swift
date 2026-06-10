import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("dailySetSize") private var dailySetSize = 5
    @AppStorage("appearance") private var appearance = "system"
    @AppStorage("reminderOn") private var reminderOn = false
    @AppStorage("reminderHour") private var reminderHour = 8
    @AppStorage("reminderMinute") private var reminderMinute = 0

    @State private var permissionDenied = false
    @Query(sort: \PracticeLog.date) private var logs: [PracticeLog]

    private var reminderTime: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(from: DateComponents(hour: reminderHour, minute: reminderMinute)) ?? .now
            },
            set: { newValue in
                let c = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                reminderHour = c.hour ?? 8
                reminderMinute = c.minute ?? 0
                if reminderOn { Reminders.schedule(hour: reminderHour, minute: reminderMinute) }
            }
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section("Daily practice") {
                        Stepper(value: $dailySetSize, in: 3...10) {
                            HStack {
                                Text("Affirmations per day")
                                Spacer()
                                Text("\(dailySetSize)").foregroundStyle(Brand.text3).font(Brand.mono(15))
                            }
                        }
                    }

                    Section {
                        Toggle("Daily reminder", isOn: $reminderOn)
                            .onChange(of: reminderOn) { _, on in
                                if on { enableReminder() } else { Reminders.cancel() }
                            }
                        if reminderOn {
                            DatePicker("Remind me at", selection: reminderTime, displayedComponents: .hourAndMinute)
                        }
                    } header: {
                        Text("Reminder")
                    } footer: {
                        if permissionDenied {
                            Text("Notifications are turned off for Mantra. Enable them in the Settings app to get reminders.")
                                .foregroundStyle(Brand.danger)
                        }
                    }

                    Section("Appearance") {
                        Picker("Theme", selection: $appearance) {
                            Text("System").tag("system")
                            Text("Light").tag("light")
                            Text("Dark").tag("dark")
                        }
                    }

                    Section("Feedback") {
                        Toggle("Haptics", isOn: $hapticsEnabled)
                            .onChange(of: hapticsEnabled) { _, v in Haptics.enabled = v }
                    }

                    Section {
                        HStack {
                            Text("Times affirmed")
                            Spacer()
                            Text("\(logs.count)").foregroundStyle(Brand.text3).font(Brand.mono(15))
                        }
                    } header: { Text("About") } footer: {
                        Text("Mantra keeps everything on your device. Nothing you write or practice leaves your phone.")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
        }
    }

    private func enableReminder() {
        Task {
            let granted = await Reminders.requestAuthorization()
            await MainActor.run {
                if granted {
                    permissionDenied = false
                    Reminders.schedule(hour: reminderHour, minute: reminderMinute)
                } else {
                    permissionDenied = true
                    reminderOn = false
                }
            }
        }
    }
}
