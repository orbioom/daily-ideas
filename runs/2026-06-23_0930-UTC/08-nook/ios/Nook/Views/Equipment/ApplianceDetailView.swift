import SwiftUI
import SwiftData

struct ApplianceDetailView: View {
    @Bindable var appliance: Appliance
    @Environment(\.modelContext) private var context
    @Query private var settingsRows: [AppSettings]

    @State private var showingEditor = false
    @State private var showingTaskEditor = false
    @State private var selectedTask: MaintenanceTask?

    private var settings: AppSettings { settingsRows.first ?? AppSettings() }
    private var warranty: WarrantyStatus { WarrantyEngine.status(for: appliance) }
    private var sortedTasks: [MaintenanceTask] { appliance.tasks.sorted { $0.nextDue < $1.nextDue } }

    private var warrantyTint: Color {
        switch warranty {
        case .active: return Theme.ok
        case .expiringSoon: return Theme.due
        case .expired: return Theme.overdue
        case .unknown: return Theme.textSecondary
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                header
                warrantyCard
                specsCard
                if !appliance.note.isEmpty { noteCard }
                tasksSection
            }
            .padding(Theme.Spacing.lg)
        }
        .navigationTitle(appliance.name)
        .navigationBarTitleDisplayMode(.inline)
        .background(Theme.bg.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showingTaskEditor = true } label: { Label("Add task for this", systemImage: "plus.circle") }
                    Button { showingEditor = true } label: { Label("Edit equipment", systemImage: "pencil") }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $showingEditor) { ApplianceEditorView(appliance: appliance) }
        .sheet(isPresented: $showingTaskEditor) { TaskEditorView(task: nil, presetAppliance: appliance) }
        .navigationDestination(item: $selectedTask) { TaskDetailView(task: $0) }
    }

    private var header: some View {
        VStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle().fill(Theme.accent.opacity(0.14)).frame(width: 64, height: 64)
                Image(systemName: appliance.kind.systemImage).font(.system(size: 26)).foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)
            Text(appliance.kind.label).font(.subheadline).foregroundStyle(Theme.textSecondary)
            if let room = appliance.room {
                Label(room.name, systemImage: room.kind.systemImage)
                    .font(.caption).foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    private var warrantyCard: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "shield.fill")
                .font(.title2)
                .foregroundStyle(warrantyTint)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Warranty").font(.caption).foregroundStyle(Theme.textSecondary)
                Text(warranty.label).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.textPrimary)
                if let expiry = appliance.warrantyExpiry {
                    Text("Expires \(Formatters.date(expiry))").font(.caption).foregroundStyle(Theme.textSecondary)
                }
            }
            Spacer()
        }
        .cardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Warranty: \(warranty.label)")
    }

    private var specsCard: some View {
        VStack(spacing: 0) {
            if !appliance.brand.isEmpty { specRow("Brand", appliance.brand); div }
            if !appliance.modelNumber.isEmpty { specRow("Model", appliance.modelNumber); div }
            if !appliance.serialNumber.isEmpty { specRow("Serial", appliance.serialNumber); div }
            if let pd = appliance.purchaseDate { specRow("Purchased", Formatters.date(pd)); div }
            specRow("Added", Formatters.date(appliance.createdAt))
        }
        .cardStyle(padding: Theme.Spacing.md)
    }

    private var div: some View {
        Divider().background(Theme.hairline).padding(.vertical, Theme.Spacing.xs)
    }

    private func specRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(Theme.textSecondary)
            Spacer()
            Text(value).foregroundStyle(Theme.textPrimary).multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
        .font(.subheadline)
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private var noteCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Notes").font(.headline).foregroundStyle(Theme.textPrimary)
            Text(appliance.note).font(.subheadline).foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "checklist").foregroundStyle(Theme.accent).accessibilityHidden(true)
                Text("Linked tasks").font(.headline).foregroundStyle(Theme.textPrimary)
                Spacer()
            }
            if sortedTasks.isEmpty {
                VStack(spacing: Theme.Spacing.sm) {
                    Text("No tasks linked to this equipment.")
                        .font(.subheadline).foregroundStyle(Theme.textSecondary)
                    Button("Add a task") { showingTaskEditor = true }
                        .font(.subheadline.weight(.semibold)).tint(Theme.accent)
                }
                .frame(maxWidth: .infinity)
                .cardStyle()
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
}

#Preview {
    NavigationStack { ApplianceDetailPreview() }
        .previewModelContainer()
}

private struct ApplianceDetailPreview: View {
    @Query private var appliances: [Appliance]
    var body: some View {
        if let a = appliances.first { ApplianceDetailView(appliance: a) } else { Text("No equipment") }
    }
}
