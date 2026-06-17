import SwiftUI
import SwiftData

/// Upcoming timeline of due tasks, grouped by month. Tap to view / complete.
struct ScheduleScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \MaintenanceTask.title) private var allTasks: [MaintenanceTask]

    @State private var completing: MaintenanceTask?

    private struct ScheduledItem: Identifiable {
        let id: UUID
        let task: MaintenanceTask
        let due: Date
    }

    private struct MonthGroup: Identifiable {
        let id = UUID()
        let title: String
        let items: [ScheduledItem]
    }

    private var monthGroups: [MonthGroup] {
        let calendar = Calendar.current
        var items: [ScheduledItem] = []
        for task in allTasks where task.isActive {
            if let due = ScheduleEngine.nextDue(for: task, hemisphere: settings.hemisphere) {
                items.append(ScheduledItem(id: task.id, task: task, due: due))
            }
        }
        items.sort { $0.due < $1.due }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        var order: [String] = []
        var map: [String: [ScheduledItem]] = [:]
        for item in items {
            let key = formatter.string(from: item.due)
            if map[key] == nil {
                map[key] = []
                order.append(key)
            }
            map[key]?.append(item)
        }
        _ = calendar
        return order.map { MonthGroup(title: $0, items: map[$0] ?? []) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Schedule")
            .sheet(item: $completing) { task in
                CompletionSheet(task: task)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        let groups = monthGroups
        if groups.isEmpty {
            EmptyStateView(symbol: "calendar",
                           title: "Nothing scheduled",
                           message: "Active tasks with a cadence will appear here on a month-by-month timeline.")
        } else {
            List {
                ForEach(groups) { group in
                    Section {
                        ForEach(group.items) { item in
                            NavigationLink {
                                TaskDetailView(task: item.task)
                            } label: {
                                scheduleRow(item)
                            }
                            .swipeActions(edge: .trailing) {
                                Button {
                                    completing = item.task
                                } label: {
                                    Label("Done", systemImage: "checkmark")
                                }
                                .tint(Theme.accent)
                            }
                        }
                    } header: {
                        Text(group.title)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
    }

    private func scheduleRow(_ item: ScheduledItem) -> some View {
        let day = item.due.formatted(.dateTime.day())
        let weekday = item.due.formatted(.dateTime.weekday(.abbreviated))
        let bucket = ScheduleEngine.bucket(for: item.task,
                                           hemisphere: settings.hemisphere,
                                           dueSoonDays: settings.clampedDueSoonDays)
        let accent: Color = bucket == .overdue ? Theme.bad : (bucket == .later ? Theme.good : Theme.warn)

        return HStack(spacing: 14) {
            VStack(spacing: 0) {
                Text(day)
                    .font(Theme.rounded(20, .bold))
                    .foregroundStyle(accent)
                    .monospacedDigit()
                Text(weekday)
                    .font(Theme.rounded(11))
                    .foregroundStyle(Theme.inkSoft)
            }
            .frame(width: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.task.title)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)
                Text(item.task.systemName)
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            Image(systemName: SystemCatalog.symbol(for: item.task.systemName))
                .foregroundStyle(Theme.accent.opacity(0.7))
                .accessibilityHidden(true)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.task.title), due \(item.due.formatted(date: .abbreviated, time: .omitted))")
    }
}
