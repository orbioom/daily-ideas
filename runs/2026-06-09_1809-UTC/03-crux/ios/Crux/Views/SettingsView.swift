import SwiftUI
import SwiftData
import UserNotifications

/// Settings: persisted preferences (default list, start of week, confirm-delete,
/// haptics, reminders) plus maintenance actions (clear completed, reset all).
struct SettingsView: View {
    @Environment(\.modelContext) private var context

    @AppStorage(Prefs.haptics) private var haptics = true
    @AppStorage(Prefs.defaultList) private var defaultListRaw = DefaultList.today.rawValue
    @AppStorage(Prefs.firstWeekday) private var firstWeekday = 2
    @AppStorage(Prefs.confirmDelete) private var confirmDelete = true
    @AppStorage(Prefs.reminders) private var reminders = false
    @AppStorage(Prefs.onboarded) private var onboarded = true

    @Query private var tasks: [TaskItem]

    @State private var showClearConfirm = false
    @State private var showResetConfirm = false
    @State private var notificationsDenied = false

    private var completedCount: Int { tasks.filter { $0.isDone }.count }

    var body: some View {
        Form {
            quickAddSection
            calendarSection
            behaviorSection
            notificationsSection
            dataSection
            aboutSection
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle("Settings")
        .task { await refreshNotificationStatus() }
        .confirmationDialog("Clear all completed tasks?", isPresented: $showClearConfirm, titleVisibility: .visible) {
            Button("Clear \(completedCount) Completed", role: .destructive) { clearCompleted() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This permanently deletes everything in your Logbook.")
        }
        .confirmationDialog("Reset all data?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Erase Everything", role: .destructive) { resetAll() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This deletes every task, project, area, and tag, and replays onboarding.")
        }
    }

    // MARK: - Sections

    private var quickAddSection: some View {
        Section {
            Picker(selection: defaultListBinding) {
                ForEach(DefaultList.allCases) { list in
                    Text(list.label).tag(list)
                }
            } label: {
                Label("New tasks go to", systemImage: "tray.and.arrow.down")
            }
        } header: {
            Text("Quick Add")
        } footer: {
            Text("Where a task lands when added without a date.")
        }
    }

    private var calendarSection: some View {
        Section {
            Picker(selection: $firstWeekday) {
                Text("Sunday").tag(1)
                Text("Monday").tag(2)
            } label: {
                Label("Start week on", systemImage: "calendar")
            }
        } header: {
            Text("Calendar")
        } footer: {
            Text("Affects weekly recurrence and date grouping.")
        }
    }

    private var behaviorSection: some View {
        Section("Behavior") {
            Toggle(isOn: $confirmDelete) {
                Label("Confirm before deleting", systemImage: "exclamationmark.shield")
            }
            Toggle(isOn: $haptics) {
                Label("Haptic feedback", systemImage: "hand.tap")
            }
            .onChange(of: haptics) { _, new in Haptics.enabled = new }
        }
    }

    private var notificationsSection: some View {
        Section {
            Toggle(isOn: $reminders) {
                Label("Due-date reminders", systemImage: "bell.badge")
            }
            .onChange(of: reminders) { _, isOn in
                if isOn { Task { await requestNotifications() } }
            }
            if notificationsDenied && reminders {
                Label("Notifications are disabled in iOS Settings.", systemImage: "bell.slash")
                    .font(.footnote)
                    .foregroundStyle(Brand.warn)
            }
        } header: {
            Text("Reminders")
        } footer: {
            Text("Get a notification when a task with a due date and time arrives.")
        }
    }

    private var dataSection: some View {
        Section("Data") {
            Button(role: .destructive) {
                showClearConfirm = true
            } label: {
                HStack {
                    Label("Clear Completed", systemImage: "trash")
                    Spacer()
                    Text("\(completedCount)").foregroundStyle(Brand.text3)
                }
            }
            .disabled(completedCount == 0)

            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("Reset All Data", systemImage: "exclamationmark.arrow.circlepath")
            }
        }
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0").foregroundStyle(Brand.text3)
            }
            HStack {
                Text("Tasks stored")
                Spacer()
                Text("\(tasks.count)").foregroundStyle(Brand.text3)
            }
        } header: {
            Text("About")
        } footer: {
            Text("Crux keeps everything on your device. No account, no cloud, no subscription on the core.")
        }
    }

    // MARK: - Bindings

    private var defaultListBinding: Binding<DefaultList> {
        Binding(
            get: { DefaultList(rawValue: defaultListRaw) ?? .today },
            set: { defaultListRaw = $0.rawValue }
        )
    }

    // MARK: - Notifications

    private func refreshNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            notificationsDenied = settings.authorizationStatus == .denied
        }
    }

    private func requestNotifications() async {
        let center = UNUserNotificationCenter.current()
        let current = await center.notificationSettings()
        if current.authorizationStatus == .denied {
            await MainActor.run { notificationsDenied = true; reminders = false }
            return
        }
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        await MainActor.run {
            if !granted { reminders = false; notificationsDenied = true }
            else { notificationsDenied = false }
        }
    }

    // MARK: - Maintenance

    private func clearCompleted() {
        let done = tasks.filter { $0.isDone }
        for task in done { context.delete(task) }
        TaskActions.save(context)
        Haptics.warning()
    }

    private func resetAll() {
        do {
            try context.delete(model: Subtask.self)
            try context.delete(model: TaskItem.self)
            try context.delete(model: Project.self)
            try context.delete(model: Area.self)
            try context.delete(model: Tag.self)
            try context.save()
        } catch {
            // If a bulk delete fails, fall back to per-object deletion.
            for task in tasks { context.delete(task) }
            TaskActions.save(context)
        }
        Haptics.warning()
        onboarded = false
    }
}
