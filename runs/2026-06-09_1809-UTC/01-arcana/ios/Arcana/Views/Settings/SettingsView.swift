import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @AppStorage(PrefKey.haptics) private var haptics = true
    @AppStorage(PrefKey.allowReversed) private var allowReversed = true
    @AppStorage(PrefKey.reminderOn) private var reminderOn = false
    @AppStorage(PrefKey.reminderHour) private var reminderHour = 9
    @AppStorage(PrefKey.reminderMinute) private var reminderMinute = 0
    @AppStorage(PrefKey.deckBack) private var deckBackRaw = DeckBack.midnight.rawValue

    @State private var reminderTime = Date.now
    @State private var notifDenied = false
    @State private var showClearConfirm = false

    private var deckBack: Binding<DeckBack> {
        Binding(
            get: { DeckBack(rawValue: deckBackRaw) ?? .midnight },
            set: { deckBackRaw = $0.rawValue }
        )
    }

    var body: some View {
        Form {
            // MARK: Readings
            Section {
                Toggle(isOn: $allowReversed) {
                    Label("Allow reversed cards", systemImage: "arrow.uturn.down")
                }
                .tint(Brand.magic)
            } header: {
                Text("Readings")
            } footer: {
                Text("When on, draws and your daily card may appear reversed, with a distinct meaning.")
            }

            // MARK: Card back
            Section {
                Picker(selection: deckBack) {
                    ForEach(DeckBack.allCases) { back in
                        Text(back.title).tag(back)
                    }
                } label: {
                    Label("Card back style", systemImage: "rectangle.portrait.fill")
                }
                CardBack(deckBack: deckBack.wrappedValue, height: 120)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            } header: {
                Text("Appearance")
            }

            // MARK: Feedback
            Section {
                Toggle(isOn: $haptics) {
                    Label("Haptic feedback", systemImage: "hand.tap.fill")
                }
                .tint(Brand.magic)
                .onChange(of: haptics) { _, new in Haptics.enabled = new }
            } header: {
                Text("Feedback")
            }

            // MARK: Reminder
            Section {
                Toggle(isOn: $reminderOn) {
                    Label("Daily card reminder", systemImage: "bell.fill")
                }
                .tint(Brand.magic)
                .onChange(of: reminderOn) { _, isOn in
                    Task { await handleReminderToggle(isOn) }
                }

                if reminderOn {
                    DatePicker(selection: $reminderTime, displayedComponents: .hourAndMinute) {
                        Label("Time", systemImage: "clock")
                    }
                    .onChange(of: reminderTime) { _, _ in applyReminderTime() }
                }

                if notifDenied {
                    Label("Notifications are turned off for Arcana. Enable them in Settings to get reminders.",
                          systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(Brand.warn)
                }
            } header: {
                Text("Reminder")
            } footer: {
                Text("A gentle nudge to draw your card of the day.")
            }

            // MARK: Data
            Section {
                Button(role: .destructive) {
                    Haptics.warning()
                    showClearConfirm = true
                } label: {
                    Label("Clear journal", systemImage: "trash")
                }
            } header: {
                Text("Data")
            } footer: {
                Text("Permanently deletes every saved reading. The card library is unaffected.")
            }

            // MARK: About
            Section {
                LabeledContent("Version", value: "1.0")
                LabeledContent("Deck", value: "Rider–Waite · 78 cards")
            } header: {
                Text("About")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
        .confirmationDialog("Clear all readings?", isPresented: $showClearConfirm, titleVisibility: .visible) {
            Button("Clear journal", role: .destructive) {
                Haptics.warning()
                SeedData.clearAllReadings(context)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
        .onAppear { syncReminderTime() }
        .task { await refreshAuthState() }
    }

    private func syncReminderTime() {
        var comps = DateComponents()
        comps.hour = reminderHour
        comps.minute = reminderMinute
        reminderTime = Calendar.current.date(from: comps) ?? .now
    }

    private func applyReminderTime() {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        reminderHour = comps.hour ?? 9
        reminderMinute = comps.minute ?? 0
        if reminderOn {
            Notifications.scheduleDaily(hour: reminderHour, minute: reminderMinute)
        }
    }

    private func handleReminderToggle(_ isOn: Bool) async {
        if isOn {
            let state = await Notifications.authorizationState()
            switch state {
            case .notDetermined:
                let granted = await Notifications.requestAuthorization()
                if granted {
                    notifDenied = false
                    Notifications.scheduleDaily(hour: reminderHour, minute: reminderMinute)
                } else {
                    notifDenied = true
                    reminderOn = false
                }
            case .authorized:
                notifDenied = false
                Notifications.scheduleDaily(hour: reminderHour, minute: reminderMinute)
            case .denied:
                notifDenied = true
                reminderOn = false
            }
        } else {
            Notifications.cancelDaily()
        }
    }

    private func refreshAuthState() async {
        if reminderOn {
            let state = await Notifications.authorizationState()
            notifDenied = (state == .denied)
            if state == .denied { reminderOn = false }
        }
    }
}
