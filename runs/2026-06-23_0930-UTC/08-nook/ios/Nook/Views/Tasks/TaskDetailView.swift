import SwiftUI
import SwiftData

struct TaskDetailView: View {
    @Bindable var task: MaintenanceTask
    @Environment(\.modelContext) private var context
    @Query private var settingsRows: [AppSettings]

    @State private var showingEditor = false
    @State private var completing = false
    @State private var showSnoozeOptions = false

    private var settings: AppSettings { settingsRows.first ?? AppSettings() }
    private var status: DueStatus {
        ScheduleEngine.status(for: task, dueSoonWindow: settings.dueSoonWindowDays)
    }
    private var history: [ServiceRecord] {
        task.records.sorted { $0.completedDate > $1.completedDate }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                headerCard
                actionButtons
                if !task.detail.isEmpty { detailCard }
                metaCard
                historyCard
            }
            .padding(Theme.Spacing.lg)
        }
        .navigationTitle(task.title)
        .navigationBarTitleDisplayMode(.inline)
        .background(Theme.bg.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingEditor = true } label: { Text("Edit") }
            }
        }
        .sheet(isPresented: $showingEditor) { TaskEditorView(task: task) }
        .sheet(isPresented: $completing) { CompleteTaskSheet(task: task) }
        .confirmationDialog("Snooze until", isPresented: $showSnoozeOptions, titleVisibility: .visible) {
            Button("Tomorrow") { snooze(1) }
            Button("In 3 days") { snooze(3) }
            Button("In 1 week") { snooze(7) }
            Button("In 1 month") { snooze(30) }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var headerCard: some View {
        VStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle().fill(status.color.opacity(0.15)).frame(width: 64, height: 64)
                Image(systemName: task.appliance?.kind.systemImage ?? task.room?.kind.systemImage ?? "wrench.adjustable")
                    .font(.system(size: 26))
                    .foregroundStyle(status.color)
            }
            .accessibilityHidden(true)
            StatusBadge(status: status)
            Text(ScheduleEngine.relativeLabel(for: task.nextDue))
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
            Text("Next due \(Formatters.date(task.nextDue))")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    private var actionButtons: some View {
        HStack(spacing: Theme.Spacing.md) {
            Button { completing = true } label: {
                Label("Mark Done", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.sm)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accent)
            .accessibilityHint("Logs a completion and advances the next due date")

            Button { showSnoozeOptions = true } label: {
                Label("Snooze", systemImage: "clock.arrow.circlepath")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.sm)
            }
            .buttonStyle(.bordered)
            .tint(Theme.accent)
            .disabled(!task.isActive)
        }
    }

    private var detailCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Details").font(.headline).foregroundStyle(Theme.textPrimary)
            Text(task.detail).font(.subheadline).foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var metaCard: some View {
        VStack(spacing: 0) {
            metaRow("Repeats", value: task.recurrence.label, icon: task.recurrence.systemImage)
            divider
            metaRow("Estimated time", value: Formatters.minutes(task.estimatedMinutes), icon: "clock")
            if let room = task.room {
                divider
                metaRow("Room", value: room.name, icon: room.kind.systemImage)
            }
            if let appliance = task.appliance {
                divider
                metaRow("Equipment", value: appliance.name, icon: appliance.kind.systemImage)
            }
            if let last = task.lastCompleted {
                divider
                metaRow("Last done", value: Formatters.date(last), icon: "checkmark.circle")
            }
            if task.totalCost > 0 {
                divider
                metaRow("Total spent", value: Formatters.currency(task.totalCost, code: settings.currencyCode), icon: "dollarsign.circle")
            }
        }
        .cardStyle(padding: Theme.Spacing.md)
    }

    private var divider: some View {
        Divider().background(Theme.hairline).padding(.vertical, Theme.Spacing.xs)
    }

    private func metaRow(_ label: String, value: String, icon: String) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon).foregroundStyle(Theme.accent).frame(width: 22).accessibilityHidden(true)
            Text(label).foregroundStyle(Theme.textSecondary)
            Spacer()
            Text(value).foregroundStyle(Theme.textPrimary).multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Service history").font(.headline).foregroundStyle(Theme.textPrimary)
            if history.isEmpty {
                Text("No completions logged yet. Mark this task done to start its history.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            } else {
                ForEach(history) { rec in
                    HStack(alignment: .top, spacing: Theme.Spacing.md) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Theme.ok)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(Formatters.date(rec.completedDate))
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Theme.textPrimary)
                            if !rec.vendor.isEmpty {
                                Text(rec.vendor).font(.caption).foregroundStyle(Theme.textSecondary)
                            }
                            if !rec.note.isEmpty {
                                Text(rec.note).font(.caption).foregroundStyle(Theme.textSecondary)
                            }
                        }
                        Spacer()
                        if rec.cost > 0 {
                            Text(Formatters.currency(rec.cost, code: settings.currencyCode))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.textPrimary)
                        }
                    }
                    .padding(.vertical, 4)
                    .swipeActions {
                        Button(role: .destructive) {
                            TaskService.delete(rec, context: context)
                        } label: { Label("Delete", systemImage: "trash") }
                    }
                    .accessibilityElement(children: .combine)
                    if rec.id != history.last?.id {
                        Divider().background(Theme.hairline)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func snooze(_ days: Int) {
        TaskService.snooze(task, days: days, context: context)
        Haptics.tap(enabled: settings.hapticsEnabled)
    }
}

#Preview {
    NavigationStack {
        TaskDetailPreview()
    }
    .previewModelContainer()
}

private struct TaskDetailPreview: View {
    @Query private var tasks: [MaintenanceTask]
    var body: some View {
        if let t = tasks.first {
            TaskDetailView(task: t)
        } else {
            Text("No task")
        }
    }
}
