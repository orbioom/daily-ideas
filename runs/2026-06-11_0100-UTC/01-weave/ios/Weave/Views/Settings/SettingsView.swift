import SwiftUI
import UserNotifications

struct SettingsView: View {
    @AppStorage("weave.hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("weave.showHints") private var showHints = true
    @AppStorage("weave.colorBlindMode") private var colorBlindMode = false
    @AppStorage("weave.dailyReminder") private var dailyReminder = false

    var body: some View {
        Form {
            Section("Gameplay") {
                Toggle("Haptic feedback", isOn: $hapticsEnabled)
                    .accessibilityHint("Vibrate on correct and wrong guesses")
                Toggle("Show 'one away' hints", isOn: $showHints)
                    .accessibilityHint("Alert when your guess is one word off from a correct group")
            }
            Section("Accessibility") {
                Toggle("Color-blind mode", isOn: $colorBlindMode)
                    .accessibilityHint("Adds distinct patterns to difficulty tiles")
            }
            Section("Notifications") {
                Toggle("Daily puzzle reminder", isOn: $dailyReminder)
                    .accessibilityHint("Get a nudge each day to play the new puzzle")
                    .onChange(of: dailyReminder) { _, newValue in
                        if newValue { scheduleDailyReminder() }
                        else { cancelDailyReminder() }
                    }
            }
            Section("About") {
                LabeledContent("Version", value: "1.0")
                LabeledContent("Puzzles available", value: "\(PuzzleBank.all.count)")
                Link("Privacy Policy", destination: URL(string: "https://orbioom.com/privacy")!)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }

    private func scheduleDailyReminder() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else {
                DispatchQueue.main.async { dailyReminder = false }
                return
            }
            let content = UNMutableNotificationContent()
            content.title = "New Weave Puzzle"
            content.body = "A fresh set of 16 words is ready. Can you find all 4 groups?"
            content.sound = .default
            var comps = DateComponents()
            comps.hour = 8
            comps.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            let req = UNNotificationRequest(identifier: "weave.daily", content: content, trigger: trigger)
            center.add(req)
        }
    }

    private func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["weave.daily"])
    }
}
