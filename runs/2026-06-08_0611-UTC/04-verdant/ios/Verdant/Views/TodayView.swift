import SwiftUI
import SwiftData

struct TodayView: View {
    @AppStorage("verdant.seasonal") private var seasonalAdjust = true
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Plant.order) private var plants: [Plant]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var now: Date { Date() }

    private var tasks: [CareTask] {
        CareEngine.todaysTasks(plants: plants, seasonalAdjust: seasonalAdjust, now: now)
    }

    private var overdueTasks: [CareTask] {
        tasks.filter { if case .overdue = $0.status { return true }; return false }
    }

    private var todayTasks: [CareTask] {
        tasks.filter { if case .dueToday = $0.status { return true }; return false }
    }

    private var soonTasks: [CareTask] {
        tasks.filter { if case .dueSoon = $0.status { return true }; return false }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                scrollContent
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    @ViewBuilder
    private var scrollContent: some View {
        if tasks.isEmpty {
            VStack {
                Spacer()
                EmptyStateView(
                    icon: "checkmark.circle.fill",
                    title: "All caught up",
                    message: "Your plants are happy. Check back soon."
                )
                Spacer()
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 16, pinnedViews: []) {
                    if !overdueTasks.isEmpty {
                        taskSection(
                            title: "Overdue",
                            icon: "exclamationmark.triangle.fill",
                            iconColor: Brand.danger,
                            tasks: overdueTasks
                        )
                    }

                    if !todayTasks.isEmpty {
                        taskSection(
                            title: "Today",
                            icon: "sun.max.fill",
                            iconColor: Brand.warn,
                            tasks: todayTasks
                        )
                    }

                    if !soonTasks.isEmpty {
                        taskSection(
                            title: "This Week",
                            icon: "calendar",
                            iconColor: Brand.info,
                            tasks: soonTasks
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
        }
    }

    private func taskSection(title: String, icon: String, iconColor: Color, tasks: [CareTask]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(iconColor)
                    .accessibilityHidden(true)
                Eyebrow(text: title)
            }

            GlassCard {
                VStack(spacing: 0) {
                    ForEach(Array(tasks.enumerated()), id: \.element.id) { idx, task in
                        CareTaskRow(task: task) {
                            completeTask(task)
                        }

                        if idx < tasks.count - 1 {
                            Divider()
                                .background(Brand.hairline)
                                .padding(.leading, 56)
                        }
                    }
                }
            }
        }
    }

    private func completeTask(_ task: CareTask) {
        let plant = task.plant
        let now = Date()

        switch task.type {
        case .water:
            plant.lastWatered = now
        case .fertilize:
            plant.lastFertilized = now
        default:
            break
        }

        let event = CareEvent(date: now, type: task.type, plant: plant)
        modelContext.insert(event)
        plant.careLog.append(event)

        Haptics.success()
    }
}
