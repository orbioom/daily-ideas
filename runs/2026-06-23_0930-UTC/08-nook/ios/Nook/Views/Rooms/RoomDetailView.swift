import SwiftUI
import SwiftData

struct RoomDetailView: View {
    @Bindable var room: Room
    @Environment(\.modelContext) private var context
    @Query private var settingsRows: [AppSettings]

    @State private var showingEditor = false
    @State private var showingTaskEditor = false
    @State private var selectedTask: MaintenanceTask?
    @State private var selectedAppliance: Appliance?

    private var settings: AppSettings { settingsRows.first ?? AppSettings() }
    private var sortedTasks: [MaintenanceTask] {
        room.tasks.sorted { $0.nextDue < $1.nextDue }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                header
                if !room.note.isEmpty {
                    Text(room.note)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .cardStyle()
                }
                tasksSection
                equipmentSection
            }
            .padding(Theme.Spacing.lg)
        }
        .navigationTitle(room.name)
        .navigationBarTitleDisplayMode(.inline)
        .background(Theme.bg.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showingTaskEditor = true } label: { Label("Add task here", systemImage: "plus.circle") }
                    Button { showingEditor = true } label: { Label("Edit room", systemImage: "pencil") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $showingEditor) { RoomEditorView(room: room) }
        .sheet(isPresented: $showingTaskEditor) { TaskEditorView(task: nil, presetRoom: room) }
        .navigationDestination(item: $selectedTask) { TaskDetailView(task: $0) }
        .navigationDestination(item: $selectedAppliance) { ApplianceDetailView(appliance: $0) }
    }

    private var header: some View {
        VStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle().fill(Theme.accent.opacity(0.14)).frame(width: 64, height: 64)
                Image(systemName: room.kind.systemImage).font(.system(size: 26)).foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)
            Text(room.kind.label).font(.subheadline).foregroundStyle(Theme.textSecondary)
            HStack(spacing: Theme.Spacing.xl) {
                countPill("\(room.tasks.count)", "tasks")
                countPill("\(room.appliances.count)", "equipment")
            }
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    private func countPill(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.title3.weight(.bold)).foregroundStyle(Theme.textPrimary)
            Text(label).font(.caption).foregroundStyle(Theme.textSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader("Tasks", systemImage: "checklist")
            if sortedTasks.isEmpty {
                emptyCard("No tasks in this room yet.", actionTitle: "Add a task") { showingTaskEditor = true }
            } else {
                VStack(spacing: 0) {
                    ForEach(sortedTasks) { task in
                        Button { selectedTask = task } label: {
                            TaskRow(task: task, dueSoonWindow: settings.dueSoonWindowDays)
                        }
                        .buttonStyle(.plain)
                        if task.id != sortedTasks.last?.id {
                            Divider().background(Theme.hairline).padding(.leading, 50)
                        }
                    }
                }
                .cardStyle(padding: Theme.Spacing.md)
            }
        }
    }

    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionHeader("Equipment", systemImage: "wrench.and.screwdriver")
            if room.appliances.isEmpty {
                emptyCard("No equipment recorded in this room.")
            } else {
                VStack(spacing: 0) {
                    let items = room.appliances.sorted { $0.name < $1.name }
                    ForEach(items) { appliance in
                        Button { selectedAppliance = appliance } label: {
                            ApplianceRow(appliance: appliance)
                        }
                        .buttonStyle(.plain)
                        if appliance.id != items.last?.id {
                            Divider().background(Theme.hairline).padding(.leading, 50)
                        }
                    }
                }
                .cardStyle(padding: Theme.Spacing.md)
            }
        }
    }

    private func sectionHeader(_ title: String, systemImage: String) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: systemImage).foregroundStyle(Theme.accent).accessibilityHidden(true)
            Text(title).font(.headline).foregroundStyle(Theme.textPrimary)
            Spacer()
        }
    }

    private func emptyCard(_ message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text(message).font(.subheadline).foregroundStyle(Theme.textSecondary)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.subheadline.weight(.semibold))
                    .tint(Theme.accent)
            }
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }
}

#Preview {
    NavigationStack { RoomDetailPreview() }
        .previewModelContainer()
}

private struct RoomDetailPreview: View {
    @Query private var rooms: [Room]
    var body: some View {
        if let r = rooms.first { RoomDetailView(room: r) } else { Text("No room") }
    }
}
