import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var settingsRows: [AppSettings]
    @Query private var tasks: [MaintenanceTask]
    @Query private var rooms: [Room]
    @Query private var appliances: [Appliance]
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    @State private var showResetConfirm = false
    @State private var showSeedConfirm = false
    @State private var showInsights = false

    private let currencyOptions = ["USD", "EUR", "GBP", "CAD", "AUD", "JPY", "INR"]

    private var settings: AppSettings {
        if let first = settingsRows.first { return first }
        let created = AppSettings()
        context.insert(created)
        try? context.save()
        return created
    }

    var body: some View {
        NavigationStack {
            Form {
                preferencesSection
                schedulingSection
                dataSection
                Section("Your home") {
                    NavigationLink {
                        InsightsView()
                    } label: {
                        Label("Insights & spending", systemImage: "chart.bar.xaxis")
                    }
                    statRow("Tasks", "\(tasks.count)")
                    statRow("Rooms", "\(rooms.count)")
                    statRow("Equipment", "\(appliances.count)")
                }
                aboutSection
            }
            .navigationTitle("Settings")
            .background(Theme.bg)
            .scrollContentBackground(.hidden)
        }
    }

    private var preferencesSection: some View {
        Section("Preferences") {
            Toggle(isOn: bindingHaptics) {
                Label("Haptic feedback", systemImage: "iphone.radiowaves.left.and.right")
            }
            Toggle(isOn: bindingGroupByRoom) {
                Label("Group tasks by room", systemImage: "square.split.bottomrightquarter")
            }
            Toggle(isOn: bindingWeekStart) {
                Label("Week starts Monday", systemImage: "calendar")
            }
        }
    }

    private var schedulingSection: some View {
        Section {
            Picker(selection: bindingDueWindow) {
                ForEach([7, 14, 21, 30], id: \.self) { Text("\($0) days").tag($0) }
            } label: {
                Label("\"Due soon\" window", systemImage: "clock")
            }
            Picker(selection: bindingCurrency) {
                ForEach(currencyOptions, id: \.self) { Text($0).tag($0) }
            } label: {
                Label("Currency", systemImage: "dollarsign.circle")
            }
        } header: {
            Text("Scheduling")
        } footer: {
            Text("Tasks due within the window appear under \"Due soon\" on the dashboard.")
        }
    }

    private var dataSection: some View {
        Section {
            Button {
                showSeedConfirm = true
            } label: {
                Label("Restore starter checklist", systemImage: "arrow.clockwise")
            }
            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("Erase all data", systemImage: "trash")
            }
        } header: {
            Text("Data")
        } footer: {
            Text("Restoring re-adds the starter checklist only if no data exists. Erasing removes every task, room and equipment record.")
        }
        .confirmationDialog("Restore the starter checklist?", isPresented: $showSeedConfirm, titleVisibility: .visible) {
            Button("Restore") {
                SeedData.seedIfNeeded(context: context)
                Haptics.success(enabled: settings.hapticsEnabled)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This only adds data if your home is currently empty.")
        }
        .confirmationDialog("Erase all data?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Erase everything", role: .destructive) { eraseAll() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes all tasks, rooms, equipment and history. This cannot be undone.")
        }
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Label("Version", systemImage: "info.circle")
                Spacer()
                Text("1.0").foregroundStyle(Theme.textSecondary)
            }
            Button {
                hasOnboarded = false
            } label: {
                Label("Show welcome tour again", systemImage: "sparkles")
            }
        } header: {
            Text("About")
        } footer: {
            Text("Nook keeps your home maintenance on track — entirely on your device. No account, no cloud.")
        }
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(Theme.textPrimary)
            Spacer()
            Text(value).foregroundStyle(Theme.textSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private func eraseAll() {
        for t in tasks { context.delete(t) }
        for r in rooms { context.delete(r) }
        for a in appliances { context.delete(a) }
        try? context.save()
        Haptics.warning(enabled: settings.hapticsEnabled)
    }

    // MARK: - Bindings to the persisted settings row

    private var bindingHaptics: Binding<Bool> {
        Binding(get: { settings.hapticsEnabled },
                set: { settings.hapticsEnabled = $0; try? context.save() })
    }
    private var bindingGroupByRoom: Binding<Bool> {
        Binding(get: { settings.groupTasksByRoom },
                set: { settings.groupTasksByRoom = $0; try? context.save() })
    }
    private var bindingWeekStart: Binding<Bool> {
        Binding(get: { settings.weekStartsMonday },
                set: { settings.weekStartsMonday = $0; try? context.save() })
    }
    private var bindingDueWindow: Binding<Int> {
        Binding(get: { settings.dueSoonWindowDays },
                set: { settings.dueSoonWindowDays = max(1, $0); try? context.save() })
    }
    private var bindingCurrency: Binding<String> {
        Binding(get: { settings.currencyCode },
                set: { settings.currencyCode = $0; try? context.save() })
    }
}

#Preview {
    SettingsView()
        .previewModelContainer()
}
