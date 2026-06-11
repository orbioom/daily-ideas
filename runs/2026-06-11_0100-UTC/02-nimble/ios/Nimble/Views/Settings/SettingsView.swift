import SwiftUI
import UserNotifications

struct SettingsView: View {
    @AppStorage("nimble.hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("nimble.soundEnabled") private var soundEnabled = false
    @AppStorage("nimble.dailyReminder") private var dailyReminder = false
    @AppStorage("nimble.reminderHour") private var reminderHour = 8

    var body: some View {
        Form {
            Section("Feedback") {
                Toggle("Haptic feedback", isOn: $hapticsEnabled)
                    .accessibilityHint("Vibrate on correct and incorrect answers")
                Toggle("Sound effects", isOn: $soundEnabled)
                    .accessibilityHint("Play sounds during games")
            }
            Section("Notifications") {
                Toggle("Daily training reminder", isOn: $dailyReminder)
                    .accessibilityHint("Get a nudge when you haven't trained yet today")
                    .onChange(of: dailyReminder) { _, new in
                        if new { scheduleReminder() } else { cancelReminder() }
                    }
                if dailyReminder {
                    Stepper("Reminder at \(reminderHour):00",
                            value: $reminderHour, in: 5...22)
                        .accessibilityValue("\(reminderHour):00")
                        .onChange(of: reminderHour) { _, _ in scheduleReminder() }
                }
            }
            Section("About") {
                LabeledContent("Version", value: "1.0")
                LabeledContent("Games", value: "\(GameType.allCases.count)")
                Link("Privacy Policy", destination: URL(string: "https://orbioom.com/privacy")!)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }

    private func scheduleReminder() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else {
                DispatchQueue.main.async { dailyReminder = false }
                return
            }
            let content = UNMutableNotificationContent()
            content.title = "Daily Brain Training"
            content.body = "Your 5 Nimble games are ready. Takes only 3 minutes!"
            content.sound = .default
            var comps = DateComponents()
            comps.hour = reminderHour
            comps.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            let req = UNNotificationRequest(identifier: "nimble.daily", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(req)
        }
    }

    private func cancelReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["nimble.daily"])
    }
}
