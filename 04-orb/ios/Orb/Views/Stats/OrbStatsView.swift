import SwiftUI
import SwiftData
import Charts

struct OrbStatsView: View {
    @Query(sort: \OrbResult.date, order: .reverse) private var results: [OrbResult]
    @AppStorage("highestLevelReached") private var highestLevelReached = 1

    private var wonResults: [OrbResult] { results.filter { $0.won } }
    private var totalScore: Int { results.reduce(0) { $0 + $1.score } }
    private var levelsCompleted: Int { Set(wonResults.map { $0.level }).count }
    private var totalShots: Int { results.reduce(0) { $0 + $1.shotsUsed } }

    private var bestPerLevel: [(level: Int, score: Int)] {
        var best: [Int: Int] = [:]
        for r in wonResults {
            if (best[r.level] ?? 0) < r.score { best[r.level] = r.score }
        }
        return best.sorted { $0.key < $1.key }.map { (level: $0.key, score: $0.value) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                OrbTheme.background.ignoresSafeArea()

                if results.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Summary cards grid
                            LazyVGrid(
                                columns: [GridItem(.flexible()), GridItem(.flexible())],
                                spacing: 12
                            ) {
                                StatCard(
                                    title: "Levels Done",
                                    value: "\(levelsCompleted)",
                                    icon: "checkmark.circle.fill",
                                    color: .green
                                )
                                StatCard(
                                    title: "Highest Level",
                                    value: "\(highestLevelReached)",
                                    icon: "arrow.up.circle.fill",
                                    color: OrbTheme.accent
                                )
                                StatCard(
                                    title: "Total Score",
                                    value: "\(totalScore)",
                                    icon: "star.fill",
                                    color: OrbTheme.starGold
                                )
                                StatCard(
                                    title: "Total Shots",
                                    value: "\(totalShots)",
                                    icon: "circle.fill",
                                    color: Color(red: 0.7, green: 0.3, blue: 0.9)
                                )
                            }
                            .padding(.horizontal, 16)

                            // Score per level bar chart
                            if !bestPerLevel.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Best Score Per Level")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)

                                    Chart {
                                        ForEach(bestPerLevel, id: \.level) { entry in
                                            BarMark(
                                                x: .value("Level", entry.level),
                                                y: .value("Score", entry.score)
                                            )
                                            .foregroundStyle(
                                                LinearGradient(
                                                    colors: [
                                                        OrbTheme.accent,
                                                        Color(red: 0.7, green: 0.3, blue: 0.9)
                                                    ],
                                                    startPoint: .bottom,
                                                    endPoint: .top
                                                )
                                            )
                                            .cornerRadius(4)
                                        }
                                    }
                                    .chartXAxis {
                                        AxisMarks(values: .stride(by: 5)) { value in
                                            AxisValueLabel {
                                                if let v = value.as(Int.self) {
                                                    Text("\(v)")
                                                        .font(.caption2)
                                                        .foregroundColor(OrbTheme.textSecondary)
                                                }
                                            }
                                            AxisGridLine(stroke: StrokeStyle(dash: [2, 4]))
                                                .foregroundStyle(Color.white.opacity(0.1))
                                        }
                                    }
                                    .chartYAxis {
                                        AxisMarks { value in
                                            AxisValueLabel {
                                                if let v = value.as(Int.self) {
                                                    Text("\(v)")
                                                        .font(.caption2)
                                                        .foregroundColor(OrbTheme.textSecondary)
                                                }
                                            }
                                            AxisGridLine(stroke: StrokeStyle(dash: [2, 4]))
                                                .foregroundStyle(Color.white.opacity(0.1))
                                        }
                                    }
                                    .frame(height: 200)
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 8)
                                }
                                .padding(.vertical, 16)
                                .background(OrbTheme.surface)
                                .cornerRadius(16)
                                .padding(.horizontal, 16)
                            }

                            // Recent games list
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Recent Games")
                                    .font(.headline)
                                    .foregroundColor(.white)

                                ForEach(results.prefix(10)) { result in
                                    RecentGameRow(result: result)
                                }
                            }
                            .padding(16)
                            .background(OrbTheme.surface)
                            .cornerRadius(16)
                            .padding(.horizontal, 16)

                            Spacer(minLength: 20)
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 60))
                .foregroundColor(OrbTheme.textSecondary.opacity(0.4))
            Text("No games yet!")
                .font(.title3.bold())
                .foregroundColor(OrbTheme.textSecondary)
            Text("Play some levels to see your stats here.")
                .font(.body)
                .foregroundColor(OrbTheme.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
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
                    .font(.title3)
                Spacer()
            }
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(title)
                .font(.caption)
                .foregroundColor(OrbTheme.textSecondary)
        }
        .padding(14)
        .background(OrbTheme.surface)
        .cornerRadius(14)
    }
}

struct RecentGameRow: View {
    let result: OrbResult

    var body: some View {
        HStack {
            Image(systemName: result.won ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(result.won ? .green : Color(red: 0.9, green: 0.2, blue: 0.2))

            VStack(alignment: .leading, spacing: 2) {
                Text("Level \(result.level)")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Text(result.date, style: .relative)
                    .font(.caption)
                    .foregroundColor(OrbTheme.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(result.score) pts")
                    .font(.subheadline.bold())
                    .foregroundColor(OrbTheme.accent)
                Text("\(result.shotsUsed) shots")
                    .font(.caption)
                    .foregroundColor(OrbTheme.textSecondary)
            }
        }
        .padding(.vertical, 4)
    }
}
