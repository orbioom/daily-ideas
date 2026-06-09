import SwiftUI
import SwiftData
import UserNotifications

/// Settings tab. Persists the yearly goal, progress display unit, default book
/// format, haptics toggle, and a daily reading reminder (via UNUserNotification).
/// Includes a destructive "Clear library" with confirmation.
struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var books: [Book]
    @Query private var tags: [BookTag]

    @AppStorage("margin.goal") private var goal = 24
    @AppStorage("margin.haptics") private var haptics = true
    @AppStorage("margin.progressUnit") private var progressUnit = ProgressUnit.pages.rawValue
    @AppStorage("margin.defaultFormat") private var defaultFormat = BookFormat.paper.rawValue
    @AppStorage("margin.reminderOn") private var reminderOn = false
    @AppStorage("margin.reminderHour") private var reminderHour = 20
    @AppStorage("margin.reminderMinute") private var reminderMinute = 0

    @State private var reminderTime = Date.now
    @State private var confirmClear = false
    @State private var notifDenied = false

    var body: some View {
        Form {
            challengeSection
            displaySection
            reminderSection
            feedbackSection
            dataSection
            aboutSection
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle("Settings")
        .confirmationDialog("Clear your whole library?",
                            isPresented: $confirmClear,
                            titleVisibility: .visible) {
            Button("Delete everything", role: .destructive) { clearLibrary() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently removes all \(books.count) books, their sessions, and tags. This can't be undone.")
        }
        .onAppear(perform: syncReminderTime)
    }

    // MARK: Challenge

    private var challengeSection: some View {
        Section("Yearly challenge") {
            Stepper(value: $goal, in: 1...365) {
                HStack {
                    Text("Goal")
                    Spacer()
                    Text("\(goal) books").foregroundStyle(Brand.text2).font(Brand.mono(15))
                }
            }
            .accessibilityValue("\(goal) books")
        }
    }

    // MARK: Display

    private var displaySection: some View {
        Section("Display") {
            Picker("Progress shown as", selection: $progressUnit) {
                ForEach(ProgressUnit.allCases) { Text($0.label).tag($0.rawValue) }
            }
            Picker("Default format", selection: $defaultFormat) {
                ForEach(BookFormat.allCases) { Label($0.label, systemImage: $0.symbol).tag($0.rawValue) }
            }
        }
    }

    // MARK: Reminder

    private var reminderSection: some View {
        Section {
            Toggle("Daily reading reminder", isOn: $reminderOn)
                .onChange(of: reminderOn) { _, on in
                    if on { enableReminder() } else { ReminderManager.disable() }
                }
            if reminderOn {
                DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    .onChange(of: reminderTime) { _, _ in updateReminderTime() }
            }
            if notifDenied {
                Label("Notifications are off for Margin. Enable them in Settings to get reminders.",
                      systemImage: "exclamationmark.triangle")
                    .font(.footnote)
                    .foregroundStyle(Brand.warn)
            }
        } header: {
            Text("Reminders")
        } footer: {
            Text("A gentle nudge to read a few pages and keep your streak alive.")
        }
    }

    // MARK: Feedback

    private var feedbackSection: some View {
        Section("Feedback") {
            Toggle("Haptics", isOn: $haptics)
                .onChange(of: haptics) { _, new in Haptics.enabled = new }
        }
    }

    // MARK: Data

    private var dataSection: some View {
        Section {
            HStack {
                Text("Books")
                Spacer()
                Text("\(books.count)").foregroundStyle(Brand.text2).font(Brand.mono(15))
            }
            HStack {
                Text("Tags")
                Spacer()
                Text("\(tags.count)").foregroundStyle(Brand.text2).font(Brand.mono(15))
            }
            Button(role: .destructive) { confirmClear = true } label: {
                Label("Clear library", systemImage: "trash")
            }
            .disabled(books.isEmpty && tags.isEmpty)
        } header: {
            Text("Data")
        } footer: {
            Text("Your library is stored on-device with SwiftData and survives relaunches.")
        }
    }

    // MARK: About

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Margin")
                Spacer()
                Text("Version 1.0").foregroundStyle(Brand.text3).font(Brand.mono(13))
            }
            Text("Read more, on purpose.")
                .font(.footnote).foregroundStyle(Brand.text3)
        }
    }

    // MARK: Reminder helpers

    private func syncReminderTime() {
        var comps = DateComponents()
        comps.hour = reminderHour
        comps.minute = reminderMinute
        reminderTime = Calendar.current.date(from: comps) ?? .now
        if reminderOn {
            ReminderManager.checkAuthorization { status in
                notifDenied = (status == .denied)
            }
        }
    }

    private func enableReminder() {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        ReminderManager.enable(at: comps) { granted in
            if granted {
                notifDenied = false
                reminderHour = comps.hour ?? 20
                reminderMinute = comps.minute ?? 0
                Haptics.success()
            } else {
                notifDenied = true
                reminderOn = false
            }
        }
    }

    private func updateReminderTime() {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        reminderHour = comps.hour ?? 20
        reminderMinute = comps.minute ?? 0
        guard reminderOn else { return }
        ReminderManager.schedule(at: comps)
    }

    // MARK: Clear

    private func clearLibrary() {
        for book in books { context.delete(book) }
        for tag in tags { context.delete(tag) }
        try? context.save()
        Haptics.warning()
    }
}
