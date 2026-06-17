import SwiftUI
import SwiftData

/// Home (Due): health gauge + Overdue / Due soon / Later buckets with one-tap Done.
struct HomeScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \MaintenanceTask.title) private var allTasks: [MaintenanceTask]

    @State private var completing: MaintenanceTask?

    private var activeTasks: [MaintenanceTask] {
        allTasks.filter { $0.isActive }
    }

    private var health: Double {
        ScheduleEngine.homeHealth(tasks: activeTasks,
                                  hemisphere: settings.hemisphere,
                                  dueSoonDays: settings.clampedDueSoonDays)
    }

    private func tasks(in bucket: DueBucket) -> [MaintenanceTask] {
        activeTasks
            .filter {
                ScheduleEngine.bucket(for: $0,
                                      hemisphere: settings.hemisphere,
                                      dueSoonDays: settings.clampedDueSoonDays) == bucket
            }
            .sorted { lhs, rhs in
                let l = ScheduleEngine.daysUntilDue(for: lhs, hemisphere: settings.hemisphere) ?? Int.max
                let r = ScheduleEngine.daysUntilDue(for: rhs, hemisphere: settings.hemisphere) ?? Int.max
                return l < r
            }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Home")
            .sheet(item: $completing) { task in
                CompletionSheet(task: task)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if activeTasks.isEmpty {
            EmptyStateView(symbol: "house",
                           title: "No active tasks yet",
                           message: "Add tasks or the starter checklist in the Tasks tab to start tracking your home's upkeep.")
        } else {
            ScrollView {
                VStack(spacing: 18) {
                    gaugeCard
                    bucketSection(.overdue)
                    bucketSection(.dueToday)
                    bucketSection(.dueSoon)
                    laterSummary
                }
                .padding(20)
            }
        }
    }

    private var gaugeCard: some View {
        VStack(spacing: 14) {
            HealthGauge(score: health)
            HStack(spacing: 18) {
                legend(color: Theme.bad, label: "Overdue", count: tasks(in: .overdue).count)
                legend(color: Theme.warn, label: "Due soon",
                       count: tasks(in: .dueToday).count + tasks(in: .dueSoon).count)
                legend(color: Theme.good, label: "Later", count: tasks(in: .later).count)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.surface))
    }

    private func legend(color: Color, label: String, count: Int) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(Theme.rounded(20, .bold))
                .foregroundStyle(color)
                .monospacedDigit()
            Text(label)
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkSoft)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(count) \(label)")
    }

    @ViewBuilder
    private func bucketSection(_ bucket: DueBucket) -> some View {
        let items = tasks(in: bucket)
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Label(bucket.title, systemImage: bucket.symbol)
                    .font(Theme.serif(18, .semibold))
                    .foregroundStyle(Theme.ink)
                VStack(spacing: 0) {
                    ForEach(items) { task in
                        TaskRow(task: task,
                                hemisphere: settings.hemisphere,
                                dueSoonDays: settings.clampedDueSoonDays) {
                            Haptics.tap(settings.hapticsEnabled)
                            completing = task
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        if task.id != items.last?.id {
                            Divider().background(Theme.hairline)
                        }
                    }
                }
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
            }
        }
    }

    @ViewBuilder
    private var laterSummary: some View {
        let later = tasks(in: .later)
        if !later.isEmpty {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Theme.good)
                    .accessibilityHidden(true)
                Text("\(later.count) task\(later.count == 1 ? "" : "s") on track")
                    .font(Theme.rounded(15, .medium))
                    .foregroundStyle(Theme.inkSoft)
                Spacer()
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surfaceAlt))
        }
    }
}
