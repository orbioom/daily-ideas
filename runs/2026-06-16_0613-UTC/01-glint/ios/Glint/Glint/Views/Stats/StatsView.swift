import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @EnvironmentObject private var pro: ProStore
    @Query(sort: \GameRecord.date, order: .forward) private var records: [GameRecord]
    @Query private var levelProgress: [LevelProgress]

    @State private var showPaywall = false

    // Free users see the most recent 14 days; Pro sees all.
    private var windowedRecords: [GameRecord] {
        guard !pro.isPro else { return records }
        let cutoff = Date().addingTimeInterval(-14 * 86_400)
        return records.filter { $0.date >= cutoff }
    }

    private var totalGames: Int { records.count }
    private var totalStars: Int { levelProgress.reduce(0) { $0 + $1.stars } }
    private var levelsCleared: Int { levelProgress.filter { $0.completed }.count }
    private var bestCombo: Int { records.map { $0.bestCombo }.max() ?? 0 }
    private var bestScore: Int { records.map { $0.score }.max() ?? 0 }

    var body: some View {
        NavigationStack {
            ZStack {
                ScreenBackground()
                if records.isEmpty {
                    EmptyStateView(
                        icon: "chart.bar.xaxis",
                        title: "No games yet",
                        message: "Play a level, a Daily, or some Zen and your stats will appear here."
                    )
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            summaryGrid
                            scoresChart
                            modeChart
                            comboChart
                            if !pro.isPro { proNote }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Stats")
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var summaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            summaryTile("Games played", "\(totalGames)", "gamecontroller.fill", Theme.accent)
            summaryTile("Best score", "\(bestScore)", "star.fill", Theme.gold)
            summaryTile("Levels cleared", "\(levelsCleared)", "checkmark.seal.fill", Theme.good)
            summaryTile("Stars earned", "\(totalStars)", "sparkles", Theme.warn)
            summaryTile("Best combo", "×\(bestCombo)", "flame.fill", Theme.bad)
            summaryTile("Gems cleared", "\(records.reduce(0) { $0 + $1.gemsCleared })", "diamond.fill", Theme.accent)
        }
    }

    private func summaryTile(_ label: String, _ value: String, _ icon: String, _ tint: Color) -> some View {
        GlintCard(padding: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: icon).foregroundStyle(tint).font(.system(size: 18))
                Text(value).font(Theme.rounded(22, .bold)).foregroundStyle(Theme.ink)
                Text(label).font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }

    private var scoresChart: some View {
        GlintCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Scores over time")
                    .font(Theme.rounded(17, .bold))
                    .foregroundStyle(Theme.ink)
                Chart(windowedRecords) { rec in
                    LineMark(
                        x: .value("Date", rec.date),
                        y: .value("Score", rec.score)
                    )
                    .foregroundStyle(Theme.accent)
                    .interpolationMethod(.catmullRom)
                    PointMark(
                        x: .value("Date", rec.date),
                        y: .value("Score", rec.score)
                    )
                    .foregroundStyle(Theme.accent.opacity(0.6))
                    .symbolSize(20)
                }
                .frame(height: 200)
                .chartYAxis { AxisMarks(position: .leading) }
                .accessibilityLabel("Line chart of scores over time")
                .accessibilityValue("\(windowedRecords.count) games, best \(bestScore) points")
            }
        }
    }

    private var modeChart: some View {
        let counts = Dictionary(grouping: records, by: { $0.mode })
            .map { (mode: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
        return GlintCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Games by mode")
                    .font(Theme.rounded(17, .bold))
                    .foregroundStyle(Theme.ink)
                Chart(counts, id: \.mode) { item in
                    BarMark(
                        x: .value("Mode", item.mode.title),
                        y: .value("Games", item.count)
                    )
                    .foregroundStyle(by: .value("Mode", item.mode.title))
                    .cornerRadius(6)
                }
                .frame(height: 180)
                .chartLegend(.hidden)
                .accessibilityLabel("Bar chart of games per mode")
                .accessibilityValue(counts.map { "\($0.mode.title) \($0.count)" }.joined(separator: ", "))
            }
        }
    }

    private var comboChart: some View {
        let recent = Array(windowedRecords.suffix(12))
        return GlintCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Best combos (recent)")
                    .font(Theme.rounded(17, .bold))
                    .foregroundStyle(Theme.ink)
                Chart(Array(recent.enumerated()), id: \.offset) { idx, rec in
                    BarMark(
                        x: .value("Game", idx + 1),
                        y: .value("Combo", rec.bestCombo)
                    )
                    .foregroundStyle(Theme.warn)
                    .cornerRadius(4)
                }
                .frame(height: 160)
                .accessibilityLabel("Bar chart of best combo per recent game")
                .accessibilityValue("Highest combo ×\(bestCombo)")
            }
        }
    }

    private var proNote: some View {
        Button { showPaywall = true } label: {
            GlintCard {
                HStack(spacing: 12) {
                    Image(systemName: "crown.fill").foregroundStyle(Theme.gold)
                    Text("Showing last 14 days. Unlock full history with Glint Pro.")
                        .font(Theme.rounded(14, .medium))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(Theme.inkSoft)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
