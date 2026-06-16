import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \GameRecord.date, order: .reverse) private var records: [GameRecord]
    @State private var showPaywall = false

    private var stats: StatsEngine { StatsEngine(records: records) }

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    EmptyStateView(
                        icon: "chart.bar.xaxis",
                        title: "No stats yet",
                        message: "Play a few games and your scores, streaks and category averages will appear here."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            summaryGrid
                            trendCard
                            if isPro {
                                distributionCard
                                categoryCard
                            } else {
                                proTeaser
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Stats")
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var summaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatPill(label: "Games played", value: "\(stats.gamesPlayed)")
            StatPill(label: "Best score", value: "\(stats.bestScore)", tint: Theme.gold)
            StatPill(label: "Average score", value: String(format: "%.0f", stats.averageScore))
            StatPill(label: "Yahtzees", value: "\(stats.totalYahtzees)", tint: Theme.accentDeep)
            StatPill(label: "Win rate vs CPU",
                     value: stats.cpuGames.isEmpty ? "—" : "\(Int((stats.cpuWinRate * 100).rounded()))%")
            StatPill(label: "CPU wins", value: "\(stats.cpuWins)")
        }
    }

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent scores")
                .font(Theme.rounded(18, .bold))
                .foregroundStyle(Theme.ink)
            let points = stats.recentScores(limit: 20)
            Chart {
                ForEach(Array(points.enumerated()), id: \.offset) { idx, point in
                    LineMark(x: .value("Game", idx + 1), y: .value("Score", point.score))
                        .foregroundStyle(Theme.accent)
                        .interpolationMethod(.catmullRom)
                    PointMark(x: .value("Game", idx + 1), y: .value("Score", point.score))
                        .foregroundStyle(Theme.accent)
                }
                if stats.averageScore > 0 {
                    RuleMark(y: .value("Average", stats.averageScore))
                        .foregroundStyle(Theme.inkSoft.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .annotation(position: .top, alignment: .leading) {
                            Text("avg \(Int(stats.averageScore.rounded()))")
                                .font(Theme.rounded(11, .medium))
                                .foregroundStyle(Theme.inkSoft)
                        }
                }
            }
            .frame(height: 180)
            .chartYScale(domain: 0...(max(stats.bestScore, 100) + 20))
            .accessibilityLabel("Line chart of your recent game scores")
            .accessibilityValue("Best \(stats.bestScore), average \(Int(stats.averageScore.rounded()))")
        }
        .padding(16)
        .card()
    }

    private var distributionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Score distribution")
                .font(Theme.rounded(18, .bold))
                .foregroundStyle(Theme.ink)
            let buckets = stats.scoreDistribution()
            Chart(buckets, id: \.lowerBound) { bucket in
                BarMark(
                    x: .value("Range", bucket.label),
                    y: .value("Games", bucket.count)
                )
                .foregroundStyle(Theme.heroGradient)
                .cornerRadius(4)
            }
            .frame(height: 170)
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let label = value.as(String.self) {
                            Text(label).font(.system(size: 9))
                        }
                    }
                }
            }
            .accessibilityLabel("Bar chart showing how many games fell in each score range")
        }
        .padding(16)
        .card()
    }

    private var categoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Average by category")
                .font(Theme.rounded(18, .bold))
                .foregroundStyle(Theme.ink)
            let data = stats.averageByCategory().filter { $0.count > 0 }
            Chart(data, id: \.category.id) { item in
                BarMark(
                    x: .value("Average", item.average),
                    y: .value("Category", item.category.shortTitle)
                )
                .foregroundStyle(Theme.accent)
                .cornerRadius(4)
                .annotation(position: .trailing) {
                    Text(String(format: "%.0f", item.average))
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            .frame(height: CGFloat(max(1, data.count)) * 26 + 20)
            .chartXAxis(.hidden)
            .accessibilityLabel("Bar chart of your average points per scoring category")
        }
        .padding(16)
        .card()
    }

    private var proTeaser: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 38))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("Unlock full statistics")
                .font(Theme.rounded(19, .bold))
                .foregroundStyle(Theme.ink)
            Text("Pip Pro adds your score distribution and per-category averages so you can sharpen every roll.")
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                showPaywall = true
            } label: {
                Text("Unlock Pro · \(Pro.price)")
                    .font(Theme.rounded(16, .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22).padding(.vertical, 12)
                    .background(Theme.accent, in: Capsule())
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .card()
    }
}
