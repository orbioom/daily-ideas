import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @EnvironmentObject private var pro: ProStore
    @Query(sort: \GameResult.date, order: .reverse) private var results: [GameResult]

    @State private var showExportSheet = false
    @State private var showPaywall = false
    @State private var exportText = ""

    var body: some View {
        NavigationStack {
            Group {
                if results.isEmpty {
                    ScrollView {
                        EmptyStateView(
                            icon: "chart.bar.xaxis",
                            title: "No stats yet",
                            message: "Play a few games and your win rate, scores and combos will appear here."
                        )
                        .padding(.top, 60)
                    }
                } else {
                    content
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Stats")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if pro.isPro { prepareExport() } else { showPaywall = true }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .accessibilityLabel("Export stats")
                    }
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showExportSheet) {
                ExportSheet(text: exportText)
            }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 18) {
                summaryGrid
                winRateChart
                scoreTrendChart
                layoutBreakdown
            }
            .padding(20)
        }
    }

    private var summaryGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatPill(label: "Played", value: "\(StatsCalculator.totalPlayed(results))")
                StatPill(label: "Won", value: "\(StatsCalculator.totalWins(results))", tint: Theme.good)
                StatPill(label: "Win rate", value: "\(Int((StatsCalculator.winRate(results) * 100).rounded()))%")
            }
            HStack(spacing: 12) {
                StatPill(label: "Best score", value: Format.score(StatsCalculator.bestScore(results)))
                StatPill(label: "Best combo", value: "x\(StatsCalculator.longestCombo(results))", tint: Theme.gold)
                StatPill(label: "Time", value: timeLabel)
            }
        }
    }

    private var timeLabel: String {
        let mins = Int((StatsCalculator.totalTime(results) / 60).rounded())
        if mins >= 60 { return String(format: "%dh %dm", mins / 60, mins % 60) }
        return "\(mins)m"
    }

    private var winRateChart: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Win rate by board")
                    .font(Theme.rounded(17, .semibold))
                    .foregroundStyle(Theme.ink)
                let stats = StatsCalculator.byLayout(results).filter { $0.played > 0 }
                if stats.isEmpty {
                    Text("No games recorded yet.")
                        .font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
                } else {
                    Chart(stats) { s in
                        BarMark(
                            x: .value("Board", s.layout.title),
                            y: .value("Win rate", s.winRate)
                        )
                        .foregroundStyle(Theme.accent.gradient)
                        .cornerRadius(6)
                        .annotation(position: .top) {
                            Text("\(Int((s.winRate * 100).rounded()))%")
                                .font(Theme.rounded(11, .semibold))
                                .foregroundStyle(Theme.inkSoft)
                        }
                    }
                    .chartYScale(domain: 0...1)
                    .chartYAxis {
                        AxisMarks(values: [0, 0.5, 1.0]) { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let d = value.as(Double.self) {
                                    Text("\(Int(d * 100))%").font(Theme.rounded(10))
                                }
                            }
                        }
                    }
                    .frame(height: 180)
                    .accessibilityLabel("Win rate by board")
                    .accessibilityValue(stats.map { "\($0.layout.title) \(Int(($0.winRate*100).rounded())) percent" }.joined(separator: ", "))
                }
            }
        }
    }

    private var scoreTrendChart: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Scores over time")
                    .font(Theme.rounded(17, .semibold))
                    .foregroundStyle(Theme.ink)
                let trend = StatsCalculator.scoreTrend(results, limit: 20)
                if trend.count < 2 {
                    Text("Play a few more games to see your trend.")
                        .font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
                } else {
                    Chart(trend) { p in
                        LineMark(
                            x: .value("Date", p.date),
                            y: .value("Score", p.score)
                        )
                        .interpolationMethod(.monotone)
                        .foregroundStyle(Theme.accent)
                        PointMark(
                            x: .value("Date", p.date),
                            y: .value("Score", p.score)
                        )
                        .foregroundStyle(p.won ? Theme.good : Theme.inkFaint)
                        .symbolSize(40)
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.month().day())
                        }
                    }
                    .frame(height: 190)
                    .accessibilityLabel("Score trend over the last \(trend.count) games")
                }
            }
        }
    }

    private var layoutBreakdown: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Games played")
                    .font(Theme.rounded(17, .semibold))
                    .foregroundStyle(Theme.ink)
                let stats = StatsCalculator.byLayout(results)
                Chart(stats) { s in
                    BarMark(
                        x: .value("Played", s.played),
                        y: .value("Board", s.layout.title)
                    )
                    .foregroundStyle(by: .value("Board", s.layout.title))
                    .cornerRadius(6)
                    .annotation(position: .trailing) {
                        Text("\(s.played)")
                            .font(Theme.rounded(11, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                .chartForegroundStyleScale([
                    BoardLayout.threePeaks.title: Theme.accent,
                    BoardLayout.pyramid.title: Theme.gold,
                    BoardLayout.diamond.title: Theme.accentDeep
                ])
                .chartLegend(.hidden)
                .frame(height: 150)
                .accessibilityLabel("Games played by board")
                .accessibilityValue(stats.map { "\($0.layout.title) \($0.played) games" }.joined(separator: ", "))
            }
        }
    }

    private func prepareExport() {
        var lines = ["date,layout,won,score,duration_sec,cards_cleared,longest_combo,deal_number,is_daily"]
        let iso = ISO8601DateFormatter()
        for r in results.sorted(by: { $0.date < $1.date }) {
            lines.append([
                iso.string(from: r.date),
                r.layout.rawValue,
                r.won ? "1" : "0",
                "\(r.score)",
                "\(Int(r.durationSec))",
                "\(r.cardsCleared)",
                "\(r.longestCombo)",
                "\(r.dealNumber)",
                r.isDaily ? "1" : "0"
            ].joined(separator: ","))
        }
        exportText = lines.joined(separator: "\n")
        showExportSheet = true
    }
}
