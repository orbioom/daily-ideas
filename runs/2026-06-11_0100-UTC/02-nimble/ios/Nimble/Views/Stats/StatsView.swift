import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query(sort: \DailyResult.date, order: .reverse) private var results: [DailyResult]
    @Query(sort: \GameSession.date, order: .reverse) private var sessions: [GameSession]

    var body: some View {
        List {
            if results.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No Training Yet",
                        systemImage: "chart.bar",
                        description: Text("Complete your first training session to see stats here.")
                    )
                }
            } else {
                overviewSection
                last30DaysChart
                gameBreakdownSection
            }
        }
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: Overview

    private var overviewSection: some View {
        Section("Overview") {
            let completedDays = results.filter { $0.gamesPlayed >= GameType.allCases.count }.count
            let best = results.map(\.totalScore).max() ?? 0
            let avg = results.isEmpty ? 0 : results.map(\.totalScore).reduce(0, +) / results.count

            HStack(spacing: 0) {
                statCell(title: "Days Complete", value: "\(completedDays)")
                Divider()
                statCell(title: "Best Score", value: "\(best)")
                Divider()
                statCell(title: "Avg Score", value: "\(avg)")
            }
            .frame(height: 70)
        }
    }

    private func statCell(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .black, design: .rounded))
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }

    // MARK: Chart

    @ViewBuilder
    private var last30DaysChart: some View {
        let slice = Array(results.prefix(30).reversed())
        if slice.count >= 2 {
            Section("Last 30 Days") {
                Chart(slice) { r in
                    BarMark(
                        x: .value("Date", r.date, unit: .day),
                        y: .value("Score", r.totalScore)
                    )
                    .foregroundStyle(Color.cyan.gradient)
                }
                .frame(height: 160)
                .chartXAxis { AxisMarks(values: .stride(by: .week)) }
                .chartYAxis { AxisMarks(position: .leading) }
                .accessibilityLabel("Bar chart of scores over the last 30 days")
            }
        }
    }

    // MARK: Per-game breakdown

    private var gameBreakdownSection: some View {
        Section("Per Game (last 30 sessions)") {
            ForEach(GameType.allCases, id: \.self) { type in
                let gameSessions = sessions.filter { $0.gameTypeRaw == type.rawValue }.prefix(30)
                let avg = gameSessions.isEmpty ? 0 : gameSessions.map(\.score).reduce(0, +) / gameSessions.count
                let best = gameSessions.map(\.score).max() ?? 0
                HStack {
                    Image(systemName: type.icon)
                        .foregroundStyle(NimbleTheme.gameColor(for: type))
                        .frame(width: 28)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(type.rawValue)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                        Text("Avg: \(avg) · Best: \(best)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(gameSessions.count) sessions")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(type.rawValue). Average \(avg), best \(best), \(gameSessions.count) sessions played.")
            }
        }
    }
}
