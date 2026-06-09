import SwiftUI
import SwiftData

/// Upcoming: an agenda of future scheduled/due tasks grouped by day. Days beyond
/// ~30 out collapse into a "Later" group. A toolbar "+" adds a scheduled task.
struct UpcomingView: View {
    @Environment(\.modelContext) private var context
    @AppStorage(Prefs.firstWeekday) private var firstWeekday = 2
    @Query private var tasks: [TaskItem]

    @State private var editing: TaskItem?

    private var days: [CruxEngine.UpcomingDay] { CruxEngine.upcoming(tasks) }

    /// Split into near-term (next 30 days) days and a single "Later" bucket.
    private var nearTerm: [CruxEngine.UpcomingDay] {
        let cutoff = Calendar.current.date(byAdding: .day, value: 30, to: .now) ?? .now
        return days.filter { $0.date <= cutoff }
    }
    private var later: [TaskItem] {
        let cutoff = Calendar.current.date(byAdding: .day, value: 30, to: .now) ?? .now
        return days.filter { $0.date > cutoff }.flatMap { $0.tasks }
    }

    var body: some View {
        ScrollView {
            if days.isEmpty {
                EmptyStateView(icon: "calendar",
                               title: "No upcoming tasks",
                               message: "Schedule a task with a future date and it will appear here, grouped by day.")
                    .padding(.top, 24)
            } else {
                LazyVStack(alignment: .leading, spacing: 18, pinnedViews: []) {
                    ForEach(nearTerm) { day in
                        dayGroup(title: CruxDate.relativeDay(day.date),
                                 subtitle: CruxDate.medium(day.date),
                                 tasks: day.tasks)
                    }
                    if !later.isEmpty {
                        dayGroup(title: "Later", subtitle: "Beyond 30 days", tasks: later)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .background(Brand.pageBackground)
        .navigationTitle("Upcoming")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    addScheduled()
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add scheduled task")
            }
        }
        .sheet(item: $editing) { task in
            TaskEditorView(task: task, isNew: task.title.isEmpty)
        }
    }

    @ViewBuilder
    private func dayGroup(title: String, subtitle: String, tasks: [TaskItem]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                SectionTitle(text: title)
                Spacer()
                Text(subtitle)
                    .font(Brand.mono(12))
                    .foregroundStyle(Brand.text3)
            }
            .padding(.bottom, 2)
            VStack(spacing: 0) {
                ForEach(tasks) { task in
                    TaskRow(task: task, showProject: true, showDate: false,
                            onToggle: { toggle(task) },
                            onOpen: { editing = task })
                    if task.id != tasks.last?.id {
                        Divider().background(Brand.hairline)
                    }
                }
            }
            .glassCard(padding: 14)
        }
    }

    private func addScheduled() {
        // Default to tomorrow morning so it lands in Upcoming, then open editor.
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: .now)) ?? .now
        let scheduled = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow) ?? tomorrow
        let task = TaskItem(title: "", scheduledDate: scheduled)
        context.insert(task)
        editing = task
    }

    private func toggle(_ task: TaskItem) {
        withAnimation(Brand.ease()) {
            TaskActions.toggleDone(task, context: context, firstWeekday: firstWeekday)
        }
        Haptics.success()
    }
}
