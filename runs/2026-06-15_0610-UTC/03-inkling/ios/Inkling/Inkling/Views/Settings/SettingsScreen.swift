import SwiftUI
import SwiftData

/// Settings: persisted prefs that change behaviour, appearance, reminders, Pro, CSV export, data
/// actions, and About.
struct SettingsScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @AppStorage("didSeed") private var didSeed = false
    @Query private var trackers: [Tracker]

    @State private var paywallReason: PaywallReason?
    @State private var showAbout = false
    @State private var showResetConfirm = false
    @State private var statusMessage: String?
    @State private var exportURL: URL?
    @State private var showShare = false
    @State private var reminderDate = Date()

    var body: some View {
        NavigationStack {
            Form {
                proSection
                trackingSection
                appearanceSection
                remindersSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
            .sheet(isPresented: $showAbout) { AboutView() }
            .sheet(isPresented: $showShare) {
                if let exportURL { ShareSheet(items: [exportURL]) }
            }
            .confirmationDialog("Reset your data?",
                                isPresented: $showResetConfirm,
                                titleVisibility: .visible) {
                Button("Reload fresh sample data", role: .destructive) { reloadSample() }
                Button("Erase everything", role: .destructive) { eraseAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Reloading replaces your data with a fresh demo set. Erasing removes all trackers and entries.")
            }
            .onAppear(perform: syncReminderDate)
        }
    }

    // MARK: Pro

    private var proSection: some View {
        Section {
            if isPro {
                HStack {
                    Label("Inkling Pro", systemImage: "crown.fill").foregroundStyle(Theme.accent)
                    Spacer()
                    Text("Unlocked").font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.good)
                }
                Button {
                    exportCSV()
                } label: {
                    Label("Export history to CSV", systemImage: "square.and.arrow.up")
                }
            } else {
                Button { paywallReason = .general } label: {
                    HStack {
                        Label("Unlock Inkling Pro", systemImage: "crown")
                        Spacer()
                        Text(Pro.priceLabel).font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.inkSoft)
                    }
                }
                Text("Lag analysis, CSV export, custom symbols & themes, experiments. Correlations and history stay free.")
                    .font(Theme.rounded(12)).foregroundStyle(Theme.inkFaint)
            }
        } header: {
            Text("Inkling Pro")
        }
    }

    // MARK: Tracking prefs

    private var trackingSection: some View {
        Section {
            Toggle(isOn: $settings.useScale10) {
                Label("Use 0–10 severity scale", systemImage: "slider.horizontal.3")
            }
            Picker(selection: Binding(
                get: { settings.defaultRange },
                set: { settings.defaultRange = $0 })) {
                ForEach(TimeRange.allCases) { Text($0.label).tag($0) }
            } label: {
                Label("Default time range", systemImage: "calendar")
            }
            Toggle(isOn: $settings.hapticsEnabled) {
                Label("Haptics", systemImage: "hand.tap")
            }
        } header: {
            Text("Tracking")
        } footer: {
            Text("The severity scale controls the slider range on the Today screen and how severities display. The default range is used by Insights and Trends.")
        }
    }

    // MARK: Appearance

    private var appearanceSection: some View {
        Section {
            Picker(selection: Binding(
                get: { settings.appearance },
                set: { settings.appearance = $0 })) {
                ForEach(Appearance.allCases) { a in
                    Label(a.label, systemImage: a.symbol).tag(a)
                }
            } label: {
                Label("Appearance", systemImage: "circle.lefthalf.filled")
            }
            .pickerStyle(.menu)
        } header: {
            Text("Appearance")
        }
    }

    // MARK: Reminders

    private var remindersSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { settings.reminderEnabled },
                set: { toggleReminder($0) })) {
                Label("Daily reminder", systemImage: "bell")
            }
            if settings.reminderEnabled {
                DatePicker(selection: $reminderDate, displayedComponents: .hourAndMinute) {
                    Label("Reminder time", systemImage: "clock")
                }
                .onChange(of: reminderDate) { _, newValue in updateReminderTime(newValue) }
            }
        } header: {
            Text("Reminders")
        } footer: {
            Text("A gentle once-a-day nudge to log. Notifications stay on this device.")
        }
    }

    // MARK: Data

    private var dataSection: some View {
        Section {
            Button {
                showResetConfirm = true
            } label: {
                Label("Reset data", systemImage: "arrow.counterclockwise")
            }
            if let statusMessage {
                Label(statusMessage, systemImage: "checkmark.circle.fill")
                    .font(Theme.rounded(13)).foregroundStyle(Theme.good)
            }
        } header: {
            Text("Your Data")
        } footer: {
            Text("Everything lives on this device. Nothing is uploaded — and your full history is always free.")
        }
    }

    private var aboutSection: some View {
        Section {
            Button { showAbout = true } label: {
                Label("About Inkling", systemImage: "info.circle")
            }
            HStack {
                Text("Version"); Spacer()
                Text("1.0").foregroundStyle(Theme.inkSoft)
            }
        }
    }

    // MARK: Actions

    private func exportCSV() {
        guard isPro else { paywallReason = .export; return }
        if let url = CSVExport.writeTempFile(trackers: trackers) {
            exportURL = url
            showShare = true
            Haptics.success(settings.hapticsEnabled)
        } else {
            statusMessage = "Couldn't build the export file."
        }
    }

    private func syncReminderDate() {
        var comps = DateComponents()
        comps.hour = settings.reminderMinutes / 60
        comps.minute = settings.reminderMinutes % 60
        reminderDate = Calendar.current.date(from: comps) ?? Date()
    }

    private func toggleReminder(_ on: Bool) {
        settings.reminderEnabled = on
        if on {
            Task {
                let ok = await Reminders.enable(minutesFromMidnight: settings.reminderMinutes)
                await MainActor.run {
                    if !ok {
                        settings.reminderEnabled = false
                        statusMessage = "Enable notifications in iOS Settings to use reminders."
                    } else {
                        statusMessage = "Daily reminder set."
                    }
                }
            }
        } else {
            Reminders.disable()
            statusMessage = "Reminder turned off."
        }
    }

    private func updateReminderTime(_ date: Date) {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        let minutes = (comps.hour ?? 20) * 60 + (comps.minute ?? 0)
        settings.reminderMinutes = minutes
        if settings.reminderEnabled {
            Reminders.schedule(minutesFromMidnight: minutes)
        }
    }

    private func reloadSample() {
        SeedData.reseedHistory(context: context)
        statusMessage = "Fresh sample data loaded."
        Haptics.success(settings.hapticsEnabled)
    }

    private func eraseAll() {
        SeedData.eraseAll(context: context)
        didSeed = false
        statusMessage = "All data erased."
        Haptics.warning(settings.hapticsEnabled)
    }
}
