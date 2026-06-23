import SwiftUI
import SwiftData

struct DueDashboardView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \MaintenanceTask.nextDue) private var tasks: [MaintenanceTask]
    @Query private var settingsRows: [AppSettings]

    @State private var summary = DashboardSummary()
    @State private var isLoading = true
    @State private var selectedTask: MaintenanceTask?
    @State private var completing: MaintenanceTask?

    private var settings: AppSettings { settingsRows.first ?? AppSettings() }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingState
                } else if tasks.isEmpty {
                    emptyState
                } else {
                    content
                }
            }
            .navigationTitle("Due")
            .background(Theme.bg.ignoresSafeArea())
            .navigationDestination(item: $selectedTask) { task in
                TaskDetailView(task: task)
            }
            .sheet(item: $completing) { task in
                CompleteTaskSheet(task: task)
            }
        }
        .task(id: tasks.count) { await recompute() }
        .onChange(of: tasks.map(\.nextDue)) { _, _ in Task { await recompute() } }
    }

    private var loadingState: some View {
        VStack(spacing: Theme.Spacing.md) {
            ProgressView()
            Text("Checking what's due…")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        ScrollView {
            EmptyStateView(systemImage: "checkmark.seal",
                           title: "No tasks yet",
                           message: "Add maintenance tasks from the Tasks tab, or reset the starter checklist in Settings.",
                           actionTitle: nil,
                           action: nil)
            .padding(.top, Theme.Spacing.xxl)
        }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                headerCard
                if summary.isAllClear {
                    allClearCard
                }
                bucket("Overdue", summary.overdue, tint: Theme.overdue, icon: "exclamationmark.triangle.fill")
                bucket("Due today", summary.dueToday, tint: Theme.due, icon: "clock.fill")
                bucket("Due soon", summary.dueSoon, tint: Theme.due, icon: "clock")
                bucket("Upcoming", Array(summary.upcoming.prefix(8)), tint: Theme.ok, icon: "calendar")
            }
            .padding(Theme.Spacing.lg)
        }
    }

    private var headerCard: some View {
        HStack(spacing: Theme.Spacing.lg) {
            HealthGauge(score: summary.health)
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                summaryLine(count: summary.overdue.count, label: "overdue", tint: Theme.overdue)
                summaryLine(count: summary.dueToday.count + summary.dueSoon.count, label: "coming up", tint: Theme.due)
                Divider().background(Theme.hairline)
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.ok)
                        .accessibilityHidden(true)
                    Text("\(summary.completedThisMonth) done this month")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            Spacer(minLength: 0)
        }
        .cardStyle()
    }

    private func summaryLine(count: Int, label: String, tint: Color) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Text("\(count)")
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(tint)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(count) \(label)")
    }

    private var allClearCard: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title2)
                .foregroundStyle(Theme.ok)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("All caught up")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Nothing is due in the next \(settings.dueSoonWindowDays) days. Nice work.")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .cardStyle()
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func bucket(_ title: String, _ items: [MaintenanceTask], tint: Color, icon: String) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: icon)
                        .foregroundStyle(tint)
                        .accessibilityHidden(true)
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(items.count)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(tint)
                        .padding(.horizontal, 7).padding(.vertical, 2)
                        .background(tint.opacity(0.14))
                        .clipShape(Capsule())
                    Spacer()
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(title), \(items.count) tasks")

                VStack(spacing: 0) {
                    ForEach(items) { task in
                        VStack(spacing: 0) {
                            Button { selectedTask = task } label: {
                                TaskRow(task: task, dueSoonWindow: settings.dueSoonWindowDays, showStatus: false)
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .leading) {
                                Button { completing = task } label: {
                                    Label("Done", systemImage: "checkmark")
                                }
                                .tint(Theme.ok)
                            }
                            if task.id != items.last?.id {
                                Divider().background(Theme.hairline).padding(.leading, 50)
                            }
                        }
                    }
                }
                .cardStyle(padding: Theme.Spacing.md)
            }
        }
    }

    @MainActor
    private func recompute() async {
        isLoading = true
        // Yield once so the loading state can render; SwiftData models stay on
        // the main actor (they are not Sendable) so the aggregation runs here.
        await Task.yield()
        summary = DashboardBuilder.build(from: tasks, dueSoonWindow: settings.dueSoonWindowDays)
        isLoading = false
    }
}

#Preview {
    DueDashboardView()
        .previewModelContainer()
}
