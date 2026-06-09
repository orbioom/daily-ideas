import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \SessionLog.date, order: .reverse) private var logs: [SessionLog]
    @AppStorage("limber.goalMinutes") private var goalMinutes = 10

    private var dailyMinutes: [MobilityEngine.DayMinutes] { MobilityEngine.dailyMinutes(logs, days: 14) }
    private var areaBalance: [MobilityEngine.AreaCount] { MobilityEngine.areaBalance(logs) }

    var body: some View {
        NavigationStack {
            ScrollView {
                if logs.isEmpty {
                    EmptyStateView(icon: "chart.xyaxis.line",
                                   title: "No data yet",
                                   message: "Finish a session and your trends will appear here.")
                        .glassCard()
                        .padding(20)
                } else {
                    VStack(spacing: 18) {
                        statsGrid
                        minutesChart
                        balanceCard
                        historyCard
                    }
                    .padding(20)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("Insights")
        }
    }

    private var statsGrid: some View {
        let cols = [GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: cols, spacing: 14) {
            statTile("Current streak", Format.streakText(MobilityEngine.currentStreak(logs)), "flame.fill", Brand.warn)
            statTile("Best streak", Format.streakText(MobilityEngine.longestStreak(logs)), "trophy.fill", Brand.magic)
            statTile("Total time", "\(MobilityEngine.totalMinutes(logs))m", "clock.fill", Brand.info)
            statTile("Sessions", "\(logs.count)", "checkmark.seal.fill", Brand.live)
        }
    }

    private func statTile(_ label: String, _ value: String, _ icon: String, _ tint: Color) -> some View {
        GlassCard(padding: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon).foregroundStyle(tint).accessibilityHidden(true)
                Text(value).font(Brand.mono(22, weight: .semibold)).foregroundStyle(Brand.text)
                Text(label).font(.caption).foregroundStyle(Brand.text3)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private var minutesChart: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "Minutes · last 14 days")
                Chart {
                    RuleMark(y: .value("Goal", Double(goalMinutes)))
                        .foregroundStyle(Brand.text3.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .annotation(position: .top, alignment: .leading) {
                            Text("Goal").font(.caption2).foregroundStyle(Brand.text3)
                        }
                    ForEach(dailyMinutes) { d in
                        BarMark(
                            x: .value("Day", d.day, unit: .day),
                            y: .value("Minutes", d.minutes)
                        )
                        .foregroundStyle(d.minutes >= Double(goalMinutes) ? Brand.live : Brand.info)
                        .cornerRadius(4)
                    }
                }
                .frame(height: 180)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 3)) { value in
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                    }
                }
                .accessibilityLabel("Daily stretching minutes for the last 14 days")
            }
        }
    }

    private var balanceCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "Area focus · last 30 sessions")
                if areaBalance.isEmpty {
                    Text("No areas recorded yet.").font(.subheadline).foregroundStyle(Brand.text3)
                } else {
                    Chart(areaBalance) { item in
                        BarMark(
                            x: .value("Count", item.count),
                            y: .value("Area", item.area.title)
                        )
                        .foregroundStyle(item.area.tint)
                        .cornerRadius(4)
                    }
                    .frame(height: CGFloat(areaBalance.count) * 30 + 20)
                    .chartXAxis { AxisMarks(position: .bottom) }
                    .accessibilityLabel("How often each body area was stretched")
                }
            }
        }
    }

    private var historyCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "History")
                ForEach(logs.prefix(12)) { log in
                    HStack {
                        Image(systemName: log.completed ? "checkmark.circle.fill" : "circle.dashed")
                            .foregroundStyle(log.completed ? Brand.live : Brand.text3)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(log.routineName).font(.subheadline).foregroundStyle(Brand.text)
                            Text(Format.relativeDay(log.date)).font(.caption).foregroundStyle(Brand.text3)
                        }
                        Spacer()
                        if log.feeling > 0 {
                            HStack(spacing: 1) {
                                ForEach(0..<log.feeling, id: \.self) { _ in
                                    Image(systemName: "star.fill").font(.caption2).foregroundStyle(Brand.warn)
                                }
                            }
                            .accessibilityLabel("\(log.feeling) star rating")
                        }
                        Text(MobilityEngine.secondsString(log.seconds))
                            .font(Brand.mono(13)).foregroundStyle(Brand.text2)
                    }
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }
}
