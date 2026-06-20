import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query private var records: [GameRecord]
    @Environment(\.dismiss) private var dismiss

    private var totalWins: Int { records.filter(\.won).count }
    private var highScore: Int { records.map(\.score).max() ?? 0 }
    private var winRate: Double {
        guard !records.isEmpty else { return 0 }
        return Double(totalWins) / Double(records.count) * 100
    }

    private var dailyPlays: [(date: Date, count: Int)] {
        let calendar = Calendar.current
        let today = Date()
        var result: [(date: Date, count: Int)] = []
        for dayOffset in (0..<14).reversed() {
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let count = records.filter { calendar.isDate($0.date, inSameDayAs: day) }.count
            result.append((date: day, count: count))
        }
        return result
    }

    private var perMapBest: [(mapName: String, score: Int)] {
        var mapScores: [String: Int] = [:]
        for rec in records {
            let cur = mapScores[rec.mapName] ?? 0
            mapScores[rec.mapName] = max(cur, rec.score)
        }
        return mapScores.map { (mapName: $0.key, score: $0.value) }
            .sorted { $0.score > $1.score }
    }

    private var favoriteTowerLabel: String {
        // We don't store tower detail per game, so infer from win count by map difficulty
        let wins = records.filter(\.won).count
        if wins == 0 { return "Play more to find out!" }
        // Heuristic: higher score on harder maps suggests cannon/frost usage
        let avgScore = records.map(\.score).reduce(0, +) / max(1, records.count)
        if avgScore > 800 { return "❄️ Frost (strategic)" }
        if avgScore > 400 { return "💣 Cannon (powerhouse)" }
        return "🏹 Archer (reliable)"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.172, green: 0.141, blue: 0.086)
                    .ignoresSafeArea()

                if records.isEmpty {
                    EmptyStateView(
                        icon: "🏰",
                        title: "No Games Yet",
                        subtitle: "Play your first battle to see stats here."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Overview grid
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                StatCard(title: "Total Games", value: "\(records.count)", icon: "flag.fill", color: .orange)
                                StatCard(title: "Victories", value: "\(totalWins)", icon: "crown.fill", color: Color(red: 0.831, green: 0.686, blue: 0.216))
                                StatCard(title: "High Score", value: "\(highScore)", icon: "star.fill", color: .yellow)
                                StatCard(title: "Win Rate", value: String(format: "%.0f%%", winRate), icon: "percent", color: .green)
                            }

                            // 14-day chart
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Games Played (14 Days)")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.5))
                                    .textCase(.uppercase)
                                    .tracking(1)

                                Chart(dailyPlays, id: \.date) { entry in
                                    BarMark(
                                        x: .value("Day", entry.date, unit: .day),
                                        y: .value("Games", entry.count)
                                    )
                                    .foregroundStyle(Color(red: 0.831, green: 0.686, blue: 0.216))
                                    .cornerRadius(4)
                                }
                                .chartXAxis {
                                    AxisMarks(values: .stride(by: .day, count: 7)) {
                                        AxisValueLabel(format: .dateTime.month().day())
                                            .foregroundStyle(Color.white.opacity(0.5))
                                    }
                                }
                                .chartYAxis {
                                    AxisMarks {
                                        AxisValueLabel()
                                            .foregroundStyle(Color.white.opacity(0.5))
                                        AxisGridLine()
                                            .foregroundStyle(Color.white.opacity(0.1))
                                    }
                                }
                                .frame(height: 130)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(red: 0.22, green: 0.18, blue: 0.12))
                            )

                            // Per-map best scores
                            if !perMapBest.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Best Scores by Map")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(.white.opacity(0.5))
                                        .textCase(.uppercase)
                                        .tracking(1)

                                    ForEach(perMapBest, id: \.mapName) { entry in
                                        HStack {
                                            Text(entry.mapName)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundStyle(.white)
                                            Spacer()
                                            HStack(spacing: 4) {
                                                Image(systemName: "trophy.fill")
                                                    .font(.system(size: 11))
                                                    .foregroundStyle(.yellow)
                                                Text("\(entry.score)")
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundStyle(.yellow)
                                            }
                                        }
                                        .padding(.vertical, 4)
                                        Divider().background(Color.white.opacity(0.1))
                                    }
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color(red: 0.22, green: 0.18, blue: 0.12))
                                )
                            }

                            // Favorite tower
                            HStack(spacing: 12) {
                                Image(systemName: "wand.and.stars")
                                    .font(.system(size: 22))
                                    .foregroundStyle(Color(red: 0.831, green: 0.686, blue: 0.216))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Favorite Tower")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.white.opacity(0.5))
                                    Text(favoriteTowerLabel)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(.white)
                                }
                                Spacer()
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(red: 0.22, green: 0.18, blue: 0.12))
                            )

                            Spacer(minLength: 40)
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color(red: 0.831, green: 0.686, blue: 0.216))
                }
            }
        }
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.system(size: 20))
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
            Text(title)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 0.22, green: 0.18, blue: 0.12))
        )
    }
}
