import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var prayers: [Prayer]

    @AppStorage("vesper.haptics") private var haptics = true
    @AppStorage("vesper.translation") private var translation = "WEB"
    @AppStorage("vesper.eveningExamen") private var eveningExamen = false
    @AppStorage("vesper.showArchived") private var showArchived = false
    @AppStorage("vesper.reminderOn") private var reminderOn = false
    @AppStorage("vesper.reminderHour") private var reminderHour = 7
    @AppStorage("vesper.reminderMinute") private var reminderMinute = 0

    @State private var reminderTime = Date.now
    @State private var notifDenied = false
    @State private var showClearConfirm = false

    private let translations = ["WEB", "KJV", "ASV", "Plain"]

    var body: some View {
        ZStack {
            Brand.pageBackground
            Form {
                readingSection
                reminderSection
                reflectionSection
                appSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
        .onAppear(perform: syncReminderTime)
    }

    // MARK: Reading

    private var readingSection: some View {
        Section {
            Picker(selection: $translation) {
                ForEach(translations, id: \.self) { Text(label(for: $0)).tag($0) }
            } label: {
                Label("Translation label", systemImage: "textformat")
            }
        } header: {
            Text("Reading")
        } footer: {
            Text("Devotions use the public-domain World English Bible. This label is shown alongside readings.")
        }
    }

    private func label(for code: String) -> String {
        switch code {
        case "WEB": return "World English Bible"
        case "KJV": return "King James style"
        case "ASV": return "American Standard"
        default:    return "Plain modern"
        }
    }

    // MARK: Reminder

    private var reminderSection: some View {
        Section {
            Toggle(isOn: $reminderOn) {
                Label("Daily reminder", systemImage: "bell")
            }
            .onChange(of: reminderOn) { _, on in
                if on { enableReminder() } else { NotificationManager.cancelDaily() }
            }

            if reminderOn {
                DatePicker(selection: $reminderTime, displayedComponents: .hourAndMinute) {
                    Label("Time", systemImage: "clock")
                }
                .onChange(of: reminderTime) { _, _ in persistAndReschedule() }
            }

            if notifDenied {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Brand.warn)
                        .accessibilityHidden(true)
                    Text("Notifications are turned off for Vesper. Enable them in the Settings app to get reminders.")
                        .font(.footnote)
                        .foregroundStyle(Brand.text2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
            }
        } header: {
            Text("Reminder")
        } footer: {
            Text("A single gentle nudge each day to read and pray.")
        }
    }

    // MARK: Reflection

    private var reflectionSection: some View {
        Section {
            Toggle(isOn: $eveningExamen) {
                Label("Evening examen prompt", systemImage: "moon.stars")
            }
        } header: {
            Text("Reflection")
        } footer: {
            Text("Adds an extra evening reflection prompt to the Today screen.")
        }
    }

    // MARK: App

    private var appSection: some View {
        Section("App") {
            Toggle(isOn: $showArchived) {
                Label("Show archived prayers", systemImage: "archivebox")
            }
            Toggle(isOn: $haptics) {
                Label("Haptic feedback", systemImage: "hand.tap")
            }
            .onChange(of: haptics) { _, new in Haptics.enabled = new }
        }
    }

    // MARK: Data

    private var dataSection: some View {
        Section {
            Button(role: .destructive) {
                showClearConfirm = true
            } label: {
                Label("Clear all prayers", systemImage: "trash")
            }
        } header: {
            Text("Data")
        } footer: {
            Text("Removes every prayer and its reflections. Your devotion library and reading history are not affected.")
        }
        .alert("Clear all prayers?", isPresented: $showClearConfirm) {
            Button("Clear", role: .destructive) { clearAllPrayers() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes all \(prayers.count) prayers and their reflections. This can't be undone.")
        }
    }

    // MARK: About

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Vesper")
                Spacer()
                Text("Version 1.0").foregroundStyle(Brand.text3)
            }
            .font(.subheadline)
            Text("A calm prayer journal and daily devotional. Private and on-device.")
                .font(.footnote)
                .foregroundStyle(Brand.text2)
        }
    }

    // MARK: Logic

    private func syncReminderTime() {
        var comps = DateComponents()
        comps.hour = reminderHour
        comps.minute = reminderMinute
        reminderTime = Calendar.current.date(from: comps) ?? .now
        Task {
            let status = await NotificationManager.authorizationStatus()
            await MainActor.run { notifDenied = (status == .denied) && reminderOn }
        }
    }

    private func enableReminder() {
        Task {
            let status = await NotificationManager.authorizationStatus()
            var granted = status == .authorized || status == .provisional
            if status == .notDetermined {
                granted = await NotificationManager.requestAuthorization()
            }
            await MainActor.run {
                if granted {
                    notifDenied = false
                    persistAndReschedule()
                    Haptics.success()
                } else {
                    notifDenied = true
                    reminderOn = false
                    Haptics.warning()
                }
            }
        }
    }

    private func persistAndReschedule() {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        reminderHour = comps.hour ?? 7
        reminderMinute = comps.minute ?? 0
        guard reminderOn else { return }
        NotificationManager.scheduleDaily(hour: reminderHour, minute: reminderMinute)
    }

    private func clearAllPrayers() {
        for prayer in prayers { context.delete(prayer) }
        try? context.save()
        Haptics.warning()
    }
}
