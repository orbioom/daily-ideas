import SwiftUI
import UserNotifications

struct MurmurSettingsView: View {
    @AppStorage("murmur.haptics")          private var haptics = true
    @AppStorage("murmur.autoTranscribe")   private var autoTranscribe = true
    @AppStorage("murmur.saveOnDevice")     private var saveOnDevice = true
    @AppStorage("murmur.dailyReminder")    private var dailyReminder = false
    @AppStorage("murmur.reminderHour")     private var reminderHour = 21
    @AppStorage("murmur.defaultMoodRaw")   private var defaultMoodRaw = Mood.neutral.rawValue
    @AppStorage("murmur.showWordCount")    private var showWordCount = true

    @State private var notifStatus: UNAuthorizationStatus = .notDetermined
    @State private var showDeleteAlert = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            Form {
                Section("Recording") {
                    Toggle("Haptic Feedback", isOn: $haptics)
                    Toggle("Auto-Transcribe", isOn: $autoTranscribe)
                    Toggle("Keep Audio on Device", isOn: $saveOnDevice)
                    Toggle("Show Word Count", isOn: $showWordCount)
                }

                Section("Default Mood") {
                    Picker("Default Mood", selection: $defaultMoodRaw) {
                        ForEach(Mood.allCases, id: \.rawValue) { mood in
                            Text(mood.emoji + " " + mood.label).tag(mood.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Reminders") {
                    Toggle(isOn: $dailyReminder) {
                        Label("Daily Journal Reminder", systemImage: "bell")
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

                Section("Privacy") {
                    LabeledContent("Storage") {
                        Text("On-device only").foregroundStyle(.secondary)
                    }
                    LabeledContent("Speech Recognition") {
                        Text("On-device").foregroundStyle(.secondary)
                    }
                    Button(role: .destructive) { showDeleteAlert = true } label: {
                        Label("Delete All Entries", systemImage: "trash")
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    Link("Privacy Policy", destination: URL(string: "https://orbioom.com/privacy")!)
                }
            }
            .navigationTitle("Settings")
            .onAppear { checkNotifStatus() }
            .confirmationDialog("Delete all entries? This cannot be undone.", isPresented: $showDeleteAlert, titleVisibility: .visible) {
                Button("Delete All", role: .destructive) { deleteAll() }
            }
        }
    }

    private func hourLabel(_ h: Int) -> String {
        let f = DateFormatter(); f.dateFormat = "h a"
        return f.string(from: Calendar.current.date(from: DateComponents(hour: h)) ?? Date())
    }

    private func checkNotifStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { s in
            DispatchQueue.main.async { notifStatus = s.authorizationStatus }
        }
    }

    private func requestAndSchedule() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                checkNotifStatus()
                if granted { scheduleReminder() } else { dailyReminder = false }
            }
        }
    }

    private func scheduleReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["murmur.daily"])
        let content = UNMutableNotificationContent()
        content.title = "Time to Murmur"
        content.body = "Take a moment to record your thoughts for today."
        content.sound = .default
        var comps = DateComponents(); comps.hour = reminderHour; comps.minute = 0
        center.add(UNNotificationRequest(
            identifier: "murmur.daily",
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        ))
    }

    private func cancelReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["murmur.daily"])
    }

    private func deleteAll() {
        // SwiftData delete all — use fetch + delete loop
        do {
            let entries = try modelContext.fetch(FetchDescriptor<VoiceEntry>())
            entries.forEach { AudioStore.delete($0.audioFilename); modelContext.delete($0) }
            let tags = try modelContext.fetch(FetchDescriptor<JournalTag>())
            tags.forEach { modelContext.delete($0) }
            try modelContext.save()
        } catch {}
    }
}
