import SwiftUI
import UserNotifications

struct SettingsView: View {
    @AppStorage("loft.dailyAffirmation") private var dailyAffirmation = false
    @AppStorage("loft.reminderHour") private var reminderHour = 9
    @AppStorage("loft.defaultCategory") private var defaultCatRaw = BoardCategory.personal.rawValue
    @AppStorage("loft.showCompletedGoals") private var showCompleted = true

    private var defaultCategory: BoardCategory {
        BoardCategory(rawValue: defaultCatRaw) ?? .personal
    }

    var body: some View {
        Form {
            Section("Goals") {
                Toggle("Show completed goals", isOn: $showCompleted)
                Picker("Default category", selection: $defaultCatRaw) {
                    ForEach(BoardCategory.allCases, id: \.rawValue) { cat in
                        Label(cat.rawValue, systemImage: cat.icon).tag(cat.rawValue)
                    }
                }
            }

            Section("Daily Reminder") {
                Toggle("Daily affirmation reminder", isOn: $dailyAffirmation)
                    .accessibilityHint("Get a morning notification with one of your affirmations")
                    .onChange(of: dailyAffirmation) { _, new in
                        if new { scheduleReminder() } else { cancelReminder() }
                    }
                if dailyAffirmation {
                    Stepper("Remind at \(reminderHour):00",
                            value: $reminderHour, in: 5...22)
                        .onChange(of: reminderHour) { _, _ in scheduleReminder() }
                }
            }

            Section("Privacy") {
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.green)
                        .accessibilityHidden(true)
                    Text("All data stays on your device. No cloud sync.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("About") {
                LabeledContent("Version", value: "1.0")
                Link("Privacy Policy", destination: URL(string: "https://orbioom.com/privacy")!)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }

    private func scheduleReminder() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else {
                DispatchQueue.main.async { dailyAffirmation = false }
                return
            }
            let content = UNMutableNotificationContent()
            content.title = "Your Daily Affirmation"
            content.body = "Take a moment to review your vision boards and affirm your goals."
            content.sound = .default
            var comps = DateComponents()
            comps.hour = reminderHour
            comps.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            let req = UNNotificationRequest(identifier: "loft.daily", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(req)
        }
    }

    private func cancelReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["loft.daily"])
    }
}
