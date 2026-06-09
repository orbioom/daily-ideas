import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \CompletionLog.date, order: .reverse) private var logs: [CompletionLog]
    @Query(sort: \Room.sortIndex) private var rooms: [Room]

    @AppStorage("hearth.soonWindowDays") private var soonWindowDays = 3

    @State private var weeks = 6

    private var summary: StatsEngine.Summary { StatsEngine.summary(logs) }
    private var weekly: [StatsEngine.WeekPoint] { StatsEngine.weeklySeries(logs, weeks: weeks) }
    private var byRoom: [StatsEngine.RoomPoint] { StatsEngine.byRoom(logs) }

    /// Active tasks across the home, most neglected first (lowest freshness).
    private var neglected: [CleaningTask] {
        rooms.flatMap { $0.activeTasks }
            .filter { HearthEngine.status(for: $0, soonWindowDays: soonWindowDays) != .ok }
            .sorted { HearthEngine.freshness(for: $0) < HearthEngine.freshness(for: $1) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if logs.isEmpty {
                    EmptyStateView(icon: "chart.bar.xaxis",
                                   title: "Nothing to show yet",
                                   message: "Complete a chore and your weekly rhythm, busiest rooms, and streaks will appear here.")
                        .glassCard()
                        .padding(20)
                } else {
                    VStack(spacing: 18) {
                        statsGrid
                        weeklyChart
                        if !byRoom.isEmpty { roomBreakdown }
                        if !neglected.isEmpty { neglectedList }
                    }
                    .padding(20)
                }
            }
            .background(Brand.pageBackground)
            .navigationTitle("Insights")
        }
    }

    // MARK: - Stats

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatTile(value: "\(summary.currentStreak)", label: "Day streak", tint: Brand.magic)
            StatTile(value: "\(summary.totalCompletions)", label: "Chores done")
            StatTile(value: Format.duration(minutes: summary.totalMinutes), label: "Time spent")
            StatTile(value: "\(summary.roomsTouched)", label: "Rooms touched")
        }
    }

    // MARK: - Weekly chart

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionTitle(text: "Chores per week")
                Spacer()
                Picker("Range", selection: $weeks) {
                    Text("6w").tag(6)
                    Text("12w").tag(12)
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
            }
            Chart(weekly) { point in
                BarMark(
                    x: .value("Week", point.weekStart, unit: .weekOfYear),
                    y: .value("Chores", point.count)
                )
                .foregroundStyle(Brand.magic.gradient)
                .cornerRadius(4)
            }
            .frame(height: 180)
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(); AxisValueLabel()
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear, count: weeks > 6 ? 2 : 1)) { _ in
                    AxisValueLabel(format: .dateTime.day().month(.narrow))
                }
            }
            .accessibilityLabel("Bar chart of chores completed per week")
        }
        .glassCard()
    }

    // MARK: - By room

    private var roomBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Where the effort goes")
            Chart(byRoom) { point in
                SectorMark(
                    angle: .value("Chores", point.count),
                    innerRadius: .ratio(0.6),
                    angularInset: 1.5
                )
                .cornerRadius(4)
                .foregroundStyle(by: .value("Room", point.room))
            }
            .frame(height: 200)
            .chartLegend(position: .bottom, spacing: 12)
            .accessibilityLabel("Donut chart of chores completed by room")

            ForEach(byRoom.prefix(6)) { item in
                HStack {
                    Text(item.room).font(.subheadline).foregroundStyle(Brand.text)
                    Spacer()
                    Text("\(item.count) · \(Format.duration(minutes: item.minutes))")
                        .font(Brand.mono(12))
                        .foregroundStyle(Brand.text2)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(item.room): \(item.count) chores, \(Format.duration(minutes: item.minutes))")
            }
        }
        .glassCard()
    }

    // MARK: - Most neglected

    private var neglectedList: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Most neglected")
            ForEach(Array(neglected.prefix(5).enumerated()), id: \.offset) { _, task in
                let fresh = HearthEngine.freshness(for: task)
                let status = HearthEngine.status(for: task, soonWindowDays: soonWindowDays)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(task.name).font(.subheadline).foregroundStyle(Brand.text)
                        Spacer()
                        Text(task.roomName).font(Brand.mono(12)).foregroundStyle(Brand.text3)
                    }
                    FreshnessBar(value: fresh, tint: status.color)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(task.name) in \(task.roomName)")
                .accessibilityValue("\(Format.percent(fresh)) fresh, \(status.label)")
            }
        }
        .glassCard()
    }
}
