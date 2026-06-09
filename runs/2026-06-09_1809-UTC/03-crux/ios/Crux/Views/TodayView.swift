import SwiftUI
import SwiftData
import Charts

/// Today: a quick-add field, an optional momentum chart, an overdue section, and
/// the day's scheduled tasks. Tapping a circle completes (recurring advances).
struct TodayView: View {
    @Environment(\.modelContext) private var context
    @AppStorage(Prefs.firstWeekday) private var firstWeekday = 2
    @AppStorage(Prefs.defaultList) private var defaultListRaw = DefaultList.today.rawValue
    @Query private var tasks: [TaskItem]

    @State private var quickText = ""
    @State private var editing: TaskItem?

    private var overdue: [TaskItem] { CruxEngine.overdue(tasks) }
    private var today: [TaskItem] {
        // Exclude overdue from the "today" section so they don't double-show.
        let overdueIDs = Set(overdue.map { $0.id })
        return CruxEngine.today(tasks).filter { !overdueIDs.contains($0.id) }
    }
    private var completionData: [CruxEngine.CompletionPoint] {
        CruxEngine.completionsPerDay(tasks, days: 14)
    }
    private var completedToday: Int {
        tasks.filter { $0.isDone && ($0.completedAt.map { Calendar.current.isDateInToday($0) } ?? false) }.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                quickAdd

                if !hasAny {
                    EmptyStateView(icon: "checkmark.circle",
                                   title: "Nothing for today",
                                   message: "You're all clear. Add a task above or check Upcoming to plan ahead.")
                        .padding(.top, 12)
                } else {
                    momentumCard

                    if !overdue.isEmpty {
                        section(title: "Overdue", tint: Brand.danger, tasks: overdue, showDate: true)
                    }
                    if !today.isEmpty {
                        section(title: "Today", tint: Brand.magic, tasks: today, showDate: false)
                    } else if overdue.isEmpty {
                        EmptyStateView(icon: "sun.max",
                                       title: "Nothing scheduled",
                                       message: "Nothing is scheduled for today.")
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Brand.pageBackground)
        .navigationTitle("Today")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Text(CruxDate.medium(.now))
                    .font(Brand.mono(13))
                    .foregroundStyle(Brand.text3)
            }
        }
        .sheet(item: $editing) { task in
            TaskEditorView(task: task)
        }
    }

    private var hasAny: Bool { !overdue.isEmpty || !today.isEmpty }

    // MARK: - Quick add

    private var quickAdd: some View {
        HStack(spacing: 10) {
            Image(systemName: "plus.circle.fill")
                .font(.title3)
                .foregroundStyle(Brand.magic)
                .accessibilityHidden(true)
            TextField("Add a task for today", text: $quickText)
                .submitLabel(.done)
                .onSubmit(addQuick)
            if !quickText.trimmingCharacters(in: .whitespaces).isEmpty {
                Button("Add", action: addQuick)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Brand.magic)
            }
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
    }

    private func addQuick() {
        let trimmed = quickText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        // Honor the user's default-list preference: Today schedules for today,
        // Anytime adds an undated backlog task.
        let preference = DefaultList(rawValue: defaultListRaw) ?? .today
        let scheduled = preference == .today ? Calendar.current.startOfDay(for: .now) : nil
        let task = TaskItem(title: trimmed, scheduledDate: scheduled)
        TaskActions.add(task, context: context)
        quickText = ""
        Haptics.success()
    }

    // MARK: - Momentum chart (Charts framework)

    private var momentumCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Eyebrow(text: "Momentum")
                Spacer()
                Text("\(completedToday) done today")
                    .font(Brand.mono(12, weight: .medium))
                    .foregroundStyle(Brand.text2)
            }
            Chart(completionData) { point in
                BarMark(
                    x: .value("Day", point.date, unit: .day),
                    y: .value("Completed", point.count)
                )
                .foregroundStyle(Brand.magic.gradient)
                .cornerRadius(3)
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 3))
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 4)) { value in
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                }
            }
            .frame(height: 120)
            .accessibilityLabel("Tasks completed per day over the last 14 days")
        }
        .glassCard()
    }

    // MARK: - Sections

    @ViewBuilder
    private func section(title: String, tint: Color, tasks: [TaskItem], showDate: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                StatusDot(color: tint)
                SectionTitle(text: title)
                Spacer()
                Text("\(tasks.count)")
                    .font(Brand.mono(13, weight: .medium))
                    .foregroundStyle(Brand.text3)
            }
            .padding(.bottom, 2)
            VStack(spacing: 0) {
                ForEach(tasks) { task in
                    TaskRow(task: task, showProject: true, showDate: showDate,
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

    private func toggle(_ task: TaskItem) {
        withAnimation(Brand.ease()) {
            TaskActions.toggleDone(task, context: context, firstWeekday: firstWeekday)
        }
        Haptics.success()
    }
}
