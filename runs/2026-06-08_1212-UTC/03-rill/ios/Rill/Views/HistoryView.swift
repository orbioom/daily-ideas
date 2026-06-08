import SwiftUI
import SwiftData
import Charts

struct HistoryView: View {
    @Query(sort: \DrinkLog.date, order: .reverse) private var allLogs: [DrinkLog]
    @AppStorage("volumeUnit") private var unitRaw = VolumeUnit.ml.rawValue
    @AppStorage("useSmartGoal") private var useSmartGoal = true
    @AppStorage("manualGoalML") private var manualGoalML = 2500.0

    @State private var range = 14

    private let engine = HydrationEngine()
    private var unit: VolumeUnit { VolumeUnit(rawValue: unitRaw) ?? .ml }
    private var goal: Double { GoalSettings.goalML }

    private var totals: [HydrationEngine.DayTotal] {
        engine.dailyTotals(allLogs, days: range, goalML: goal)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if allLogs.isEmpty {
                    EmptyStateView(
                        icon: "calendar",
                        title: "No history yet",
                        message: "Log a few drinks and your daily totals and goal streak will show up here."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            rangePicker
                            chartCard
                            summaryCard
                            dayList
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("History")
        }
    }

    private var rangePicker: some View {
        Picker("Range", selection: $range) {
            Text("7 days").tag(7)
            Text("14 days").tag(14)
            Text("30 days").tag(30)
        }
        .pickerStyle(.segmented)
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Daily intake").font(.headline).foregroundStyle(Brand.text)
            Chart {
                ForEach(totals) { t in
                    BarMark(
                        x: .value("Day", t.day, unit: .day),
                        y: .value("Amount", Units.display(t.effectiveML, as: unit))
                    )
                    .foregroundStyle(t.met ? Brand.live : Color.accentColor)
                    .cornerRadius(4)
                }
                if goal > 0 {
                    RuleMark(y: .value("Goal", Units.display(goal, as: unit)))
                        .foregroundStyle(Brand.text3)
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .annotation(position: .top, alignment: .leading) {
                            Text("goal").font(.caption2).foregroundStyle(Brand.text3)
                        }
                }
            }
            .frame(height: 200)
        }
        .glassCard()
    }

    private var summaryCard: some View {
        let avg = engine.averageDaily(allLogs, days: range)
        let streak = engine.goalStreak(allLogs, goalML: goal)
        let metCount = totals.filter { $0.met }.count
        return HStack(spacing: 12) {
            summaryStat(Units.string(avg, as: unit), "daily avg", "drop.fill")
            summaryStat("\(streak)", streak == 1 ? "day streak" : "day streak", "flame.fill")
            summaryStat("\(metCount)/\(range)", "goal days", "checkmark.seal.fill")
        }
    }

    private func summaryStat(_ value: String, _ label: String, _ symbol: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol).font(.title3).foregroundStyle(Color.accentColor)
            Text(value).font(.system(.headline, design: .rounded)).foregroundStyle(Brand.text)
                .minimumScaleFactor(0.6).lineLimit(1)
            Text(label).font(.caption2).foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity)
        .glassCard(padding: 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }

    private var dayList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("By day").font(.headline).foregroundStyle(Brand.text)
            ForEach(totals.reversed()) { t in
                HStack {
                    Text(Format.relativeDay(t.day, relativeTo: .now, calendar: .current))
                        .font(.subheadline).foregroundStyle(Brand.text2)
                    Spacer()
                    Text(Units.string(t.effectiveML, as: unit))
                        .font(Brand.mono(13, weight: .medium)).foregroundStyle(Brand.text)
                    if t.met {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption).foregroundStyle(Brand.live)
                    } else {
                        Image(systemName: "circle").font(.caption).foregroundStyle(Brand.text3)
                    }
                }
            }
        }
        .glassCard()
    }
}
