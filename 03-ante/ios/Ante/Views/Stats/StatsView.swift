import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query(sort: \GameRecord.date, order: .reverse) private var records: [GameRecord]
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            AnteTheme.feltGreenDark
                .ignoresSafeArea()

            if records.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        summaryGrid
                        streakSection
                        chartSection
                        recentGames
                    }
                    .padding(20)
                }
            }
        }
        .navigationTitle("Stats")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 56))
                .foregroundColor(AnteTheme.textMuted)
            Text("No games yet")
                .font(.title3)
                .foregroundColor(AnteTheme.textSecondary)
            Text("Play your first game to see stats here.")
                .font(.subheadline)
                .foregroundColor(AnteTheme.textMuted)
                .multilineTextAlignment(.center)
        }
    }

    private var wins: Int { records.filter { $0.playerWon }.count }
    private var losses: Int { records.count - wins }
    private var winRate: Double { records.isEmpty ? 0 : Double(wins) / Double(records.count) }
    private var avgScore: Double { records.isEmpty ? 0 : Double(records.map { $0.playerScore }.reduce(0, +)) / Double(records.count) }
    private var bestScore: Int { records.map { $0.playerScore }.max() ?? 0 }
    private var avgDuration: Int {
        guard !records.isEmpty else { return 0 }
        return records.map { $0.gameDurationSeconds }.reduce(0, +) / records.count
    }

    private var summaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(title: "Win Rate", value: String(format: "%.0f%%", winRate * 100),
                     icon: "percent", color: AnteTheme.gold)
            StatCard(title: "Games Played", value: "\(records.count)",
                     icon: "number.circle", color: .cyan)
            StatCard(title: "Wins / Losses", value: "\(wins)W \(losses)L",
                     icon: "trophy", color: .green)
            StatCard(title: "Best Score", value: "\(bestScore) pts",
                     icon: "star.fill", color: .orange)
            StatCard(title: "Avg Score", value: String(format: "%.0f pts", avgScore),
                     icon: "chart.line.uptrend.xyaxis", color: .purple)
            StatCard(title: "Avg Duration", value: formatDuration(avgDuration),
                     icon: "clock", color: .blue)
        }
    }

    private var currentStreak: Int {
        var streak = 0
        for record in records {
            if record.playerWon { streak += 1 } else { break }
        }
        return streak
    }

    private var longestStreak: Int {
        var best = 0
        var current = 0
        for record in records.reversed() {
            if record.playerWon { current += 1; best = max(best, current) }
            else { current = 0 }
        }
        return best
    }

    private var streakSection: some View {
        HStack(spacing: 12) {
            VStack(spacing: 6) {
                Text("\(currentStreak)")
                    .font(.system(size: 36, weight: .black))
                    .foregroundColor(currentStreak > 0 ? AnteTheme.gold : AnteTheme.textMuted)
                Text("Current Streak")
                    .font(.caption)
                    .foregroundColor(AnteTheme.textMuted)
                if currentStreak > 0 {
                    Label("\(currentStreak) wins in a row", systemImage: "flame.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(AnteTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(spacing: 6) {
                Text("\(longestStreak)")
                    .font(.system(size: 36, weight: .black))
                    .foregroundColor(AnteTheme.gold)
                Text("Best Streak")
                    .font(.caption)
                    .foregroundColor(AnteTheme.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(AnteTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private var monthlyData: [(String, Int, Int)] {
        let calendar = Calendar.current
        var result: [(String, Int, Int)] = []
        for offset in stride(from: -5, through: 0, by: 1) {
            guard let date = calendar.date(byAdding: .month, value: offset, to: Date()) else { continue }
            let comps = calendar.dateComponents([.year, .month], from: date)
            let monthRecords = records.filter { r in
                let rc = calendar.dateComponents([.year, .month], from: r.date)
                return rc.year == comps.year && rc.month == comps.month
            }
            let label = DateFormatter().apply { df in
                df.dateFormat = "MMM"
            }.string(from: date)
            result.append((label, monthRecords.filter { $0.playerWon }.count, monthRecords.count))
        }
        return result
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monthly Performance")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(AnteTheme.textSecondary)

            Chart {
                ForEach(monthlyData, id: \.0) { item in
                    BarMark(
                        x: .value("Month", item.0),
                        y: .value("Total", item.2)
                    )
                    .foregroundStyle(AnteTheme.surface)

                    BarMark(
                        x: .value("Month", item.0),
                        y: .value("Wins", item.1)
                    )
                    .foregroundStyle(AnteTheme.gold)
                }
            }
            .frame(height: 160)
            .chartXAxis {
                AxisMarks { _ in
                    AxisGridLine().foregroundStyle(Color.white.opacity(0.1))
                    AxisValueLabel().foregroundStyle(AnteTheme.textMuted)
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine().foregroundStyle(Color.white.opacity(0.1))
                    AxisValueLabel().foregroundStyle(AnteTheme.textMuted)
                }
            }

            HStack(spacing: 16) {
                legendItem(color: AnteTheme.gold, label: "Wins")
                legendItem(color: AnteTheme.surface, label: "Total Games")
            }
        }
        .padding(16)
        .background(AnteTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 16, height: 10)
            Text(label)
                .font(.caption2)
                .foregroundColor(AnteTheme.textMuted)
        }
    }

    private var recentGames: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Games")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(AnteTheme.textSecondary)

            ForEach(records.prefix(10)) { record in
                HStack(spacing: 12) {
                    Image(systemName: record.playerWon ? "crown.fill" : "xmark.circle")
                        .foregroundColor(record.playerWon ? AnteTheme.gold : .red.opacity(0.7))
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("vs \(record.opponentName)")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.white)
                        Text(record.date, style: .date)
                            .font(.caption2)
                            .foregroundColor(AnteTheme.textMuted)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(record.playerScore) – \(record.opponentScore)")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white)
                        Text("\(record.roundsPlayed) rounds")
                            .font(.caption2)
                            .foregroundColor(AnteTheme.textMuted)
                    }
                }
                .padding(12)
                .background(AnteTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundColor(.white)
            Text(title)
                .font(.caption)
                .foregroundColor(AnteTheme.textMuted)
        }
        .padding(14)
        .background(AnteTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

extension DateFormatter {
    func apply(_ configure: (DateFormatter) -> Void) -> DateFormatter {
        configure(self)
        return self
    }
}
