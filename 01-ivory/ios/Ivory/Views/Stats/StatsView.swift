import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query(sort: \GameRecord.date, order: .reverse) private var records: [GameRecord]

    private var wins: Int { records.filter { $0.playerWon }.count }
    private var losses: Int { records.filter { !$0.playerWon && !$0.isDraw }.count }
    private var draws: Int { records.filter { $0.isDraw }.count }
    private var total: Int { records.count }
    private var winRate: Double { total > 0 ? Double(wins) / Double(total) : 0 }

    var body: some View {
        NavigationStack {
            ZStack {
                IvoryTheme.background.ignoresSafeArea()
                Group {
                    if records.isEmpty {
                        EmptyStateView(
                            icon: "chart.bar",
                            title: "No stats yet",
                            message: "Play games to see your stats here."
                        )
                    } else {
                        ScrollView {
                            VStack(spacing: 20) {
                                summaryCards
                                winRateChart
                                recentChart
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Stats")
        }
    }

    private var summaryCards: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
            spacing: 12
        ) {
            StatCard(label: "Wins", value: "\(wins)", color: .green)
            StatCard(label: "Losses", value: "\(losses)", color: .red)
            StatCard(label: "Draws", value: "\(draws)", color: IvoryTheme.accent)
        }
    }

    private var winRateChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Win Rate: \(Int(winRate * 100))%")
                .font(.headline)
                .foregroundStyle(IvoryTheme.primaryText)
            Chart {
                SectorMark(angle: .value("Wins", max(wins, 0)), innerRadius: .ratio(0.55))
                    .foregroundStyle(.green)
                    .annotation(position: .overlay) {
                        if wins > 0 {
                            Text("W").font(.caption2).foregroundStyle(.white)
                        }
                    }
                SectorMark(angle: .value("Losses", max(losses, 0)), innerRadius: .ratio(0.55))
                    .foregroundStyle(.red)
                    .annotation(position: .overlay) {
                        if losses > 0 {
                            Text("L").font(.caption2).foregroundStyle(.white)
                        }
                    }
                SectorMark(angle: .value("Draws", max(draws, 0)), innerRadius: .ratio(0.55))
                    .foregroundStyle(IvoryTheme.accent)
                    .annotation(position: .overlay) {
                        if draws > 0 {
                            Text("D").font(.caption2).foregroundStyle(.white)
                        }
                    }
            }
            .frame(height: 180)
            .padding()
            .background(IvoryTheme.surface, in: RoundedRectangle(cornerRadius: 14))
        }
        .accessibilityLabel("Win rate chart: \(wins) wins, \(losses) losses, \(draws) draws")
    }

    private var recentChart: some View {
        let recent = Array(records.prefix(20).reversed())
        return VStack(alignment: .leading, spacing: 8) {
            Text("Recent Results (last \(min(20, total)))")
                .font(.headline)
                .foregroundStyle(IvoryTheme.primaryText)
            Chart(recent.indices, id: \.self) { i in
                BarMark(
                    x: .value("Game", i + 1),
                    y: .value("Result", recent[i].playerWon ? 1 : (recent[i].isDraw ? 0 : -1))
                )
                .foregroundStyle(
                    recent[i].playerWon ? Color.green :
                    recent[i].isDraw ? IvoryTheme.accent :
                    Color.red
                )
            }
            .frame(height: 120)
            .padding()
            .background(IvoryTheme.surface, in: RoundedRectangle(cornerRadius: 14))
            .accessibilityLabel("Recent results chart, \(min(20, total)) games shown")
        }
    }
}

struct StatCard: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(IvoryTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(IvoryTheme.surface, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}
