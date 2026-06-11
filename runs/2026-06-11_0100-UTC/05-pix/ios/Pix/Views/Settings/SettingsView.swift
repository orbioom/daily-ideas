import SwiftUI
import UserNotifications

struct PixSettingsView: View {
    @AppStorage("pix.haptics")            private var haptics = true
    @AppStorage("pix.showTimer")          private var showTimer = true
    @AppStorage("pix.showCompletedLines") private var showCompletedLines = true
    @AppStorage("pix.dailyReminder")      private var dailyReminder = false
    @AppStorage("pix.reminderHour")       private var reminderHour = 9
    @AppStorage("pix.largeClues")         private var largeClues = false

    @State private var notifStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        NavigationStack {
            Form {
                Section("Gameplay") {
                    Toggle("Haptics", isOn: $haptics)
                    Toggle("Show Timer", isOn: $showTimer)
                    Toggle("Highlight Completed Lines", isOn: $showCompletedLines)
                    Toggle("Large Clue Numbers", isOn: $largeClues)
                }

                Section("Notifications") {
                    Toggle(isOn: $dailyReminder) {
                        Label("Daily Reminder", systemImage: "bell")
                    }
                    .onChange(of: dailyReminder) { _, on in
                        if on { requestAndSchedule() } else { cancelReminder() }
                    }

                    if dailyReminder {
                        Stepper(value: $reminderHour, in: 0...23) {
                            Label("Time: \(hourLabel(reminderHour))", systemImage: "clock")
                        }
                        .onChange(of: reminderHour) { _, _ in scheduleReminder() }
                    }

                    if notifStatus == .denied {
                        Label("Notifications are disabled in Settings", systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Puzzles", value: "\(PixPuzzleBank.all.count)")
                    Link("Privacy Policy", destination: URL(string: "https://orbioom.com/privacy")!)
                }
            }
            .navigationTitle("Settings")
            .onAppear { checkNotifStatus() }
        }
    }

    private func hourLabel(_ h: Int) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "h a"
        let cal = Calendar.current
        let date = cal.date(from: DateComponents(hour: h, minute: 0)) ?? Date()
        return fmt.string(from: date)
    }

    private func checkNotifStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { s in
            DispatchQueue.main.async { notifStatus = s.authorizationStatus }
        }
    }

    private func requestAndSchedule() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                checkNotifStatus()
                if granted { scheduleReminder() } else { dailyReminder = false }
            }
        }
    }

    private func scheduleReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["pix.daily"])
        let content = UNMutableNotificationContent()
        content.title = "New Pix Puzzle"
        content.body = "Today's pixel art puzzle is waiting for you."
        content.sound = .default
        var comps = DateComponents()
        comps.hour = reminderHour
        comps.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        center.add(UNNotificationRequest(identifier: "pix.daily", content: content, trigger: trigger))
    }

    private func cancelReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["pix.daily"])
    }
}
