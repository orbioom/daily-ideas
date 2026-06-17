import SwiftUI
import SwiftData

/// Detail for a single task: status, cadence, estimates, history, and actions.
struct TaskDetailView: View {
    @Bindable var task: MaintenanceTask
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    @State private var showEditor = false
    @State private var showCompletion = false
    @State private var showDeleteConfirm = false

    private var dueText: String {
        guard let days = ScheduleEngine.daysUntilDue(for: task, hemisphere: settings.hemisphere) else {
            return "Not scheduled"
        }
        if days < 0 { return "Overdue by \(-days) day\(days == -1 ? "" : "s")" }
        if days == 0 { return "Due today" }
        if days == 1 { return "Due tomorrow" }
        return "Due in \(days) days"
    }

    private var sortedLogs: [CompletionLog] {
        task.logs.sorted { $0.date > $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                statusCard
                detailsCard
                historyCard
            }
            .padding(20)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Task")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showEditor = true }
            }
        }
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(title: "Mark done", systemImage: "checkmark.circle.fill") {
                Haptics.tap(settings.hapticsEnabled)
                showCompletion = true
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
            .background(.ultraThinMaterial)
        }
        .sheet(isPresented: $showEditor) {
            TaskEditorView(task: task)
        }
        .sheet(isPresented: $showCompletion) {
            CompletionSheet(task: task)
        }
        .confirmationDialog("Delete this task?",
                            isPresented: $showDeleteConfirm,
                            titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                context.delete(task)
                Haptics.warning(settings.hapticsEnabled)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the task and its completion history.")
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: SystemCatalog.symbol(for: task.systemName))
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 46, height: 46)
                .background(Circle().fill(Theme.accentSoft))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(Theme.serif(22, .bold))
                    .foregroundStyle(Theme.ink)
                Text(task.systemName)
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
        }
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            infoRow("Status", task.isActive ? dueText : "Paused",
                    symbol: task.isActive ? "calendar.badge.clock" : "pause.circle")
            infoRow("Cadence",
                    task.cadenceType.describe(interval: task.intervalCount, season: task.season),
                    symbol: "repeat")
            if let last = task.lastDone {
                infoRow("Last done", last.formatted(date: .abbreviated, time: .omitted),
                        symbol: "clock.arrow.circlepath")
            } else {
                infoRow("Last done", "Never", symbol: "clock.arrow.circlepath")
            }
            infoRow("Priority", task.priorityLabel, symbol: "flag")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            infoRow("Est. time", "\(task.estimatedMinutes) min", symbol: "timer")
            if let cost = task.estimatedCost, cost > 0 {
                infoRow("Est. cost", settings.formatMoney(cost), symbol: "dollarsign.circle")
            }
            if !task.notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Notes", systemImage: "note.text")
                        .font(Theme.rounded(13, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                    Text(task.notes)
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label("Delete task", systemImage: "trash")
                    .font(Theme.rounded(15, .medium))
            }
            .padding(.top, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
    }

    @ViewBuilder
    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("History", systemImage: "list.bullet.rectangle")
                .font(Theme.serif(18, .semibold))
                .foregroundStyle(Theme.ink)
            if sortedLogs.isEmpty {
                Text("No completions logged yet.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
            } else {
                ForEach(sortedLogs) { log in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(log.date.formatted(date: .abbreviated, time: .omitted))
                                .font(Theme.rounded(15, .medium))
                                .foregroundStyle(Theme.ink)
                            if let minutes = log.minutesSpent {
                                Text("\(minutes) min")
                                    .font(Theme.rounded(12))
                                    .foregroundStyle(Theme.inkSoft)
                            }
                        }
                        Spacer()
                        if let cost = log.costActual, cost > 0 {
                            Text(settings.formatMoney(cost))
                                .font(Theme.rounded(15, .semibold))
                                .foregroundStyle(Theme.accent)
                        }
                    }
                    if log.id != sortedLogs.last?.id {
                        Divider().background(Theme.hairline)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
    }

    private func infoRow(_ label: String, _ value: String, symbol: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 14))
                .foregroundStyle(Theme.accent)
                .frame(width: 22)
                .accessibilityHidden(true)
            Text(label)
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkSoft)
            Spacer()
            Text(value)
                .font(Theme.rounded(15, .medium))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}
