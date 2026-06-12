import SwiftUI
import SwiftData
import Charts

struct HistoryView: View {
    @Query(sort: \DayLog.day, order: .reverse) private var logs: [DayLog]
    @AppStorage("unitsRaw") private var unitsRaw = Units.metric.rawValue
    private var units: Units { Units(rawValue: unitsRaw) ?? .metric }

    private var last7: [DayLog] {
        Array(logs.prefix(7)).sorted { $0.day < $1.day }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgPrimary.ignoresSafeArea()
                if logs.isEmpty {
                    EmptyStateView(symbol: "calendar.badge.clock",
                                   title: "No history yet",
                                   message: "Walk with Tread for a day and your activity will start filling in here.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            weekCard
                            ForEach(logs) { log in
                                DayRow(log: log, units: units)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("History")
        }
    }

    private var weekCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(text: "Last 7 days")
            Chart(last7) { log in
                BarMark(
                    x: .value("Day", Fmt.weekday(log.day)),
                    y: .value("Steps", log.steps)
                )
                .foregroundStyle(log.metGoal ? Theme.accent : Theme.track)
                .cornerRadius(6)
                if log.goal > 0 {
                    RuleMark(y: .value("Goal", log.goal))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .foregroundStyle(Theme.textSecondary.opacity(0.6))
                }
            }
            .chartYAxis { AxisMarks(position: .leading) }
            .frame(height: 180)
            .accessibilityLabel("Bar chart of steps over the last seven days")
        }
        .treadCard()
    }
}

struct DayRow: View {
    let log: DayLog
    let units: Units

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().stroke(Theme.track, lineWidth: 5)
                Circle()
                    .trim(from: 0, to: log.progress)
                    .stroke(log.metGoal ? Theme.accent : Theme.warm,
                            style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                if log.metGoal {
                    Image(systemName: "checkmark")
                        .font(.caption2.bold())
                        .foregroundStyle(Theme.accent)
                }
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 3) {
                Text(Fmt.dayTitle(log.day))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("\(Fmt.distance(log.distanceMeters, units: units)) \(units.shortDistance) · \(log.flights) flights")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Text(Fmt.steps(log.steps))
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
                .monospacedDigit()
        }
        .treadCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(Fmt.dayTitle(log.day)): \(Fmt.steps(log.steps)) steps, \(log.metGoal ? "goal met" : "goal not met")")
    }
}
