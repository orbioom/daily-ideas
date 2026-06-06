import SwiftUI
import SwiftData
import UserNotifications

/// Preferences (each changing behavior), data tools (export, manage locations), and a
/// reset path. Notifications are optional and degrade gracefully if denied.
struct SettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Query private var items: [Item]
    @Query(sort: \Location.sortIndex) private var locations: [Location]

    @State private var exportFormat: InventoryExport.Format = .csv
    @State private var exportDocument: ExportText?
    @State private var notificationStatusText = ""
    @State private var showingResetConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    appearanceSection
                    behaviorSection
                    notificationsSection
                    dataSection
                    aboutSection
                    resetSection
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .onAppear(perform: refreshNotificationStatus)
            .sheet(item: $exportDocument) { doc in
                ShareSheet(text: doc.text, fileName: doc.fileName)
            }
            .confirmationDialog("Reset Larder?",
                                isPresented: $showingResetConfirm,
                                titleVisibility: .visible) {
                Button("Erase everything", role: .destructive) { performReset() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes all items, locations, categories, and your shopping list, and restores first-run defaults.")
            }
        }
    }

    // MARK: - Bindings helper

    private var settingsBindable: Bindable<SettingsStore> { Bindable(settings) }

    // MARK: - Sections

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: settingsBindable.appearance) {
                ForEach(SettingsStore.Appearance.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
        }
    }

    private var behaviorSection: some View {
        Section {
            Picker("Expiring-soon window", selection: settingsBindable.expirySoonWindowDays) {
                ForEach(SettingsStore.windowChoices, id: \.self) { days in
                    Text("\(days) days").tag(days)
                }
            }
            Picker("Default location", selection: defaultLocationBinding) {
                Text("None").tag("")
                ForEach(locations) { location in
                    Text(location.name).tag(location.id.uuidString)
                }
            }
            Toggle("Haptics", isOn: settingsBindable.hapticsEnabled)
        } header: {
            Text("Behavior")
        } footer: {
            Text("The window decides what counts as expiring soon. The default location is pre-selected for new items.")
        }
    }

    /// Coerces a stale stored location id back to "None" so the picker stays valid.
    private var defaultLocationBinding: Binding<String> {
        Binding(
            get: {
                let id = settings.defaultLocationID
                if id.isEmpty { return "" }
                return locations.contains { $0.id.uuidString == id } ? id : ""
            },
            set: { settings.defaultLocationID = $0 })
    }

    private var notificationsSection: some View {
        Section {
            Toggle("Expiry reminders", isOn: notificationsBinding)
            if !notificationStatusText.isEmpty {
                Label(notificationStatusText, systemImage: "info.circle")
                    .font(.footnote)
                    .foregroundStyle(Brand.text2)
            }
        } header: {
            Text("Notifications")
        } footer: {
            Text("Optional local reminders for items nearing their date. Larder works fully without them.")
        }
    }

    /// Turning reminders on requests permission and reschedules; denial flips the toggle
    /// back and shows a calm hint instead of failing.
    private var notificationsBinding: Binding<Bool> {
        Binding(
            get: { settings.notificationsEnabled },
            set: { newValue in
                if newValue {
                    NotificationManager.requestAuthorization { granted in
                        settings.notificationsEnabled = granted
                        refreshNotificationStatus()
                        if granted { rescheduleReminders() }
                    }
                } else {
                    settings.notificationsEnabled = false
                    NotificationManager.cancelAll()
                    refreshNotificationStatus()
                }
            })
    }

    private var dataSection: some View {
        Section {
            NavigationLink {
                LocationsManagerView()
            } label: {
                Label("Manage locations", systemImage: "tray.2")
            }
            Picker("Export format", selection: $exportFormat) {
                ForEach(InventoryExport.Format.allCases) { format in
                    Text(format.rawValue).tag(format)
                }
            }
            Button {
                exportInventory()
            } label: {
                Label("Export inventory", systemImage: "square.and.arrow.up")
            }
            .disabled(items.isEmpty)
        } header: {
            Text("Data")
        } footer: {
            Text(items.isEmpty ? "Add items to enable export." : "Export all \(items.count) items as \(exportFormat.rawValue).")
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("App", value: "Larder")
            LabeledContent("Items", value: "\(items.count)")
            LabeledContent("Locations", value: "\(locations.count)")
        }
    }

    private var resetSection: some View {
        Section {
            Button(role: .destructive) {
                showingResetConfirm = true
            } label: {
                Label("Reset Larder", systemImage: "arrow.counterclockwise")
            }
        } footer: {
            Text("Erases all data and restores the welcome screen and sample larder.")
        }
    }

    // MARK: - Actions

    private func refreshNotificationStatus() {
        NotificationManager.authorizationStatus { status in
            switch status {
            case .denied:
                notificationStatusText = "Notifications are off in iOS Settings. Reminders won't be delivered."
            case .notDetermined:
                notificationStatusText = settings.notificationsEnabled
                    ? "Turn on to allow reminders." : ""
            case .authorized, .provisional, .ephemeral:
                notificationStatusText = settings.notificationsEnabled
                    ? "Reminders are scheduled for items nearing their date." : ""
            @unknown default:
                notificationStatusText = ""
            }
        }
    }

    private func rescheduleReminders() {
        let reminders: [NotificationManager.Reminder] = items.compactMap { item in
            guard let expiry = item.expiryDate else { return nil }
            return NotificationManager.Reminder(id: item.id, name: item.name, expiry: expiry)
        }
        NotificationManager.reschedule(reminders: reminders,
                                       windowDays: settings.expirySoonWindowDays,
                                       enabled: settings.notificationsEnabled)
    }

    private func exportInventory() {
        let records: [InventoryExport.Record] = items
            .sorted { $0.name < $1.name }
            .map { item in
                InventoryExport.Record(
                    name: item.name,
                    category: item.category?.name ?? "",
                    location: item.location?.name ?? "",
                    quantity: item.quantity,
                    unit: item.unit.short,
                    purchaseDate: item.purchaseDate,
                    expiryDate: item.expiryDate,
                    lowStockThreshold: item.lowStockThreshold,
                    notes: item.notes)
            }
        let text = exportFormat == .csv
            ? InventoryExport.csv(from: records)
            : InventoryExport.json(from: records)
        exportDocument = ExportText(text: text,
                                    fileName: "larder-inventory.\(exportFormat.fileExtension)")
        Haptics.success(enabled: settings.hapticsEnabled)
    }

    /// Deletes all model data and resets prefs/flags so the next launch is a clean first run.
    private func performReset() {
        for item in items { context.delete(item) }
        let allLocations = (try? context.fetch(FetchDescriptor<Location>())) ?? []
        for location in allLocations { context.delete(location) }
        let allCategories = (try? context.fetch(FetchDescriptor<Category>())) ?? []
        for category in allCategories { context.delete(category) }
        let allEntries = (try? context.fetch(FetchDescriptor<ShoppingListEntry>())) ?? []
        for entry in allEntries { context.delete(entry) }
        try? context.save()
        NotificationManager.cancelAll()
        settings.resetToDefaults()
        Haptics.warning(enabled: settings.hapticsEnabled)
    }
}

/// Identifiable wrapper so the export sheet can be presented via `.sheet(item:)`.
private struct ExportText: Identifiable {
    let id = UUID()
    let text: String
    let fileName: String
}

#Preview {
    SettingsView()
        .environment(SettingsStore())
        .modelContainer(PreviewData.container)
}
