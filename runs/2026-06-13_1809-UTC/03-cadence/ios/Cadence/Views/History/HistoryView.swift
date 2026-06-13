import SwiftUI
import SwiftData
import Charts

struct HistoryView: View {
    @Query private var meds: [Medication]
    @Query(sort: \DoseLog.takenAt, order: .reverse) private var logs: [DoseLog]

    @State private var now = Date()

    private var streak: Int { ScheduleEngine.currentStreak(meds: meds, logs: logs, now: now) }
    private var adh7: Double? { ScheduleEngine.adherence(lastDays: 7, meds: meds, logs: logs, now: now) }
    private var adh30: Double? { ScheduleEngine.adherence(lastDays: 30, meds: meds, logs: logs, now: now) }

    private struct DayBar: Identifiable { let id = UUID(); let label: String; let pct: Double; let has: Bool }

    private var dailyBars: [DayBar] {
        let cal = Calendar.current
        return (0..<14).reversed().compactMap { offset -> DayBar? in
            guard let day = cal.date(byAdding: .day, value: -offset, to: now) else { return nil }
            let a = ScheduleEngine.dayAdherence(on: day, meds: meds, logs: logs, now: now)
            let pct = a.map { $0.total > 0 ? Double($0.taken) / Double($0.total) : 0 } ?? 0
            return DayBar(label: day.formatted(.dateTime.day()), pct: pct, has: a != nil)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if logs.isEmpty {
                    EmptyStateView(icon: "calendar",
                                   title: "No history yet",
                                   message: "Once you start logging doses on the Today tab, your adherence and streaks show up here.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            statsRow
                            chartCard
                            logsCard
                        }
                        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 28)
                    }
                }
            }
            .navigationTitle("History")
            .onAppear { now = Date() }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            StatTile(value: "\(streak)", label: streak == 1 ? "day streak" : "day streak", accent: Theme.accent)
            StatTile(value: adh7.map { "\(Int($0 * 100))%" } ?? "—", label: "7-day", accent: Theme.good)
            StatTile(value: adh30.map { "\(Int($0 * 100))%" } ?? "—", label: "30-day", accent: Theme.ink)
        }
    }

    private var chartCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Last 14 days").font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                Chart(dailyBars) { bar in
                    BarMark(x: .value("Day", bar.label), y: .value("Adherence", bar.pct))
                        .foregroundStyle(bar.pct >= 0.999 ? Theme.good : (bar.has ? Theme.accent : Theme.surfaceAlt))
                        .cornerRadius(3)
                }
                .chartYScale(domain: 0...1)
                .chartYAxis { AxisMarks(format: .percent.precision(.fractionLength(0)), values: [0, 0.5, 1]) }
                .frame(height: 150)
                .accessibilityLabel("Daily adherence for the last 14 days")
            }
        }
    }

    private var logsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent doses").font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                ForEach(logs.prefix(40)) { log in
                    HStack(spacing: 12) {
                        Image(systemName: log.status == .taken ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(log.status == .taken ? Theme.good : Theme.inkFaint)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(log.medName).font(Theme.rounded(15, .semibold)).foregroundStyle(Theme.ink)
                            Text("\(Fmt.relativeDay(log.takenAt)) · \(TimeFmt.clock(date: log.takenAt))" + (log.wasAsNeeded ? " · as needed" : ""))
                                .font(Theme.rounded(12, .medium)).foregroundStyle(Theme.inkSoft)
                        }
                        Spacer()
                        Text(log.status == .taken ? "Taken" : "Skipped")
                            .font(Theme.rounded(12, .bold))
                            .foregroundStyle(log.status == .taken ? Theme.good : Theme.inkSoft)
                    }
                    .padding(.vertical, 5)
                    if log.id != logs.prefix(40).last?.id { Divider().background(Theme.hairline) }
                }
            }
        }
    }
}
