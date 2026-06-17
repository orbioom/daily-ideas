import SwiftUI
import SwiftData

/// Settings: hemisphere, due-soon window, currency, reminders, haptics, Pro, export.
struct SettingsScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @AppStorage("didSeed") private var didSeed = false
    @Query private var allTasks: [MaintenanceTask]

    @State private var paywallReason: PaywallReason?
    @State private var showRestoreNote = false
    @State private var reminderDenied = false

    private let currencyOptions = ["$", "£", "€", "¥", "₹", "C$", "A$"]

    var body: some View {
        NavigationStack {
            Form {
                proSection
                schedulingSection
                remindersSection
                appearanceSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .sheet(item: $paywallReason) { reason in
                PaywallView(reason: reason)
            }
            .alert("Reminders are off", isPresented: $reminderDenied) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Enable notifications for Upkeep in the Settings app to get due-date reminders.")
            }
        }
    }

    // MARK: Pro

    private var proSection: some View {
        Section {
            if isPro {
                HStack {
                    Label("Upkeep Pro", systemImage: "crown.fill")
                        .foregroundStyle(Theme.accent)
                    Spacer()
                    Text("Unlocked")
                        .font(Theme.rounded(14, .semibold))
                        .foregroundStyle(Theme.good)
                }
            } else {
                Button {
                    paywallReason = .costTracking
                } label: {
                    Label("Unlock Upkeep Pro · \(Pro.priceLabel)", systemImage: "crown.fill")
                }
                Button("Restore Purchase") {
                    Haptics.tap(settings.hapticsEnabled)
                    showRestoreNote = true
                }
                if showRestoreNote {
                    Text("No previous purchase found on this device.")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
        } header: {
            Text("Upkeep Pro")
        } footer: {
            Text("One-time purchase. Unlocks unlimited tasks, cost tracking, forecast, reminders, and export.")
        }
    }

    // MARK: Scheduling

    private var schedulingSection: some View {
        Section {
            Picker("Hemisphere", selection: Binding(
                get: { settings.hemisphere },
                set: { settings.hemisphere = $0 }
            )) {
                ForEach(Hemisphere.allCases) { h in
                    Text(h.label).tag(h)
                }
            }
            Stepper(value: Binding(
                get: { settings.clampedDueSoonDays },
                set: { settings.dueSoonDays = $0 }
            ), in: 1...60) {
                HStack {
                    Text("Due-soon window")
                    Spacer()
                    Text("\(settings.clampedDueSoonDays) days")
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            Picker("Currency", selection: Binding(
                get: { settings.currencySymbol },
                set: { settings.currencySymbol = $0 }
            )) {
                ForEach(currencyOptions, id: \.self) { symbol in
                    Text(symbol).tag(symbol)
                }
            }
        } header: {
            Text("Scheduling")
        } footer: {
            Text("Hemisphere maps seasonal tasks to the right months.")
        }
    }

    // MARK: Reminders

    private var remindersSection: some View {
        Section {
            if isPro {
                Toggle("Due-date reminders", isOn: Binding(
                    get: { settings.remindersEnabled },
                    set: { newValue in handleReminderToggle(newValue) }
                ))
            } else {
                Button {
                    paywallReason = .reminders
                } label: {
                    HStack {
                        Label("Due-date reminders", systemImage: "bell.badge")
                        Spacer()
                        Image(systemName: "lock.fill").foregroundStyle(Theme.inkFaint)
                    }
                }
            }
        } header: {
            Text("Reminders")
        } footer: {
            Text("Private, on-device local notifications at 9am on a task's due day. Up to \(NotificationManager.maxScheduled) at a time.")
        }
    }

    // MARK: Appearance

    private var appearanceSection: some View {
        Section("General") {
            Toggle("Haptics", isOn: Binding(
                get: { settings.hapticsEnabled },
                set: { settings.hapticsEnabled = $0 }
            ))
        }
    }

    // MARK: Data

    private var dataSection: some View {
        Section("Data") {
            if isPro {
                NavigationLink {
                    ExportView()
                } label: {
                    Label("Export (CSV)", systemImage: "square.and.arrow.up")
                }
            } else {
                Button {
                    paywallReason = .export
                } label: {
                    HStack {
                        Label("Export (CSV)", systemImage: "square.and.arrow.up")
                        Spacer()
                        Image(systemName: "lock.fill").foregroundStyle(Theme.inkFaint)
                    }
                }
            }
            Button {
                loadSample()
            } label: {
                Label("Load sample data", systemImage: "tray.and.arrow.down")
            }
        }
    }

    // MARK: About

    private var aboutSection: some View {
        Section {
            NavigationLink {
                AboutView()
            } label: {
                Label("About Upkeep", systemImage: "info.circle")
            }
        }
    }

    // MARK: Actions

    private func handleReminderToggle(_ newValue: Bool) {
        if newValue {
            NotificationManager.requestAuthorization { granted in
                if granted {
                    settings.remindersEnabled = true
                    NotificationManager.reschedule(tasks: allTasks, hemisphere: settings.hemisphere)
                } else {
                    settings.remindersEnabled = false
                    reminderDenied = true
                }
            }
        } else {
            settings.remindersEnabled = false
            NotificationManager.cancelAll()
        }
    }

    private func loadSample() {
        // Re-seed only if there's no data; otherwise just confirm with haptics.
        let count = (try? context.fetchCount(FetchDescriptor<MaintenanceTask>())) ?? 0
        if count == 0 {
            SeedData.seed(context: context)
            didSeed = true
        } else {
            _ = TaskFactory.addStarterChecklist(into: context)
        }
        Haptics.success(settings.hapticsEnabled)
    }
}
