import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query(sort: \GameRecord.date, order: .reverse) private var records: [GameRecord]

    private var wins: Int { records.filter { $0.didPlayerWin }.count }
    private var losses: Int { records.filter { !$0.didPlayerWin }.count }
    private var winRate: Double { records.isEmpty ? 0 : Double(wins) / Double(records.count) * 100 }
    private var avgRoundsPerMatch: Double {
        records.isEmpty ? 0 : Double(records.reduce(0) { $0 + $1.roundsPlayed }) / Double(records.count)
    }
    private var avgScoreWhenWin: Double {
        let w = records.filter { $0.didPlayerWin }
        guard !w.isEmpty else { return 0 }
        return Double(w.reduce(0) { $0 + $1.playerFinalScore }) / Double(w.count)
    }
    private var recent10: [GameRecord] { Array(records.prefix(10).reversed()) }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    statsGrid
                    if records.count >= 3 {
                        winLossChart
                        scoreChart
                    } else {
                        placeholderNote
                    }
                }
                .padding()
            }
            .background(DominoTheme.background.ignoresSafeArea())
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.large)
        }
        .preferredColorScheme(.dark)
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
            DominoStatCard(value: "\(records.count)", label: "Matches", color: DominoTheme.ivory)
            DominoStatCard(value: String(format: "%.0f%%", winRate), label: "Win Rate", color: DominoTheme.green)
            DominoStatCard(value: "\(wins)W / \(losses)L", label: "Record", color: DominoTheme.amber)
            DominoStatCard(value: String(format: "%.1f", avgRoundsPerMatch), label: "Avg Rounds", color: DominoTheme.ivory.opacity(0.7))
        }
    }

    private var winLossChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Win/Loss Breakdown")
                .font(.headline)
                .foregroundStyle(DominoTheme.ivory)
            Chart {
                SectorMark(angle: .value("Wins", wins), innerRadius: .ratio(0.6), outerRadius: .ratio(1.0))
                    .foregroundStyle(DominoTheme.green)
                    .annotation(position: .overlay) {
                        Text("\(wins)W").font(.caption.weight(.bold)).foregroundStyle(.white)
                    }
                SectorMark(angle: .value("Losses", max(1, losses)), innerRadius: .ratio(0.6), outerRadius: .ratio(1.0))
                    .foregroundStyle(DominoTheme.red)
                    .annotation(position: .overlay) {
                        Text("\(losses)L").font(.caption.weight(.bold)).foregroundStyle(.white)
                    }
            }
            .frame(height: 160)
        }
        .padding()
        .background(DominoTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    private var scoreChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Scores (last 10)")
                .font(.headline)
                .foregroundStyle(DominoTheme.ivory)
            Chart(recent10.enumerated().map { ($0.offset, $0.element) }, id: \.0) { idx, record in
                BarMark(x: .value("Match", idx + 1), y: .value("Score", record.playerFinalScore))
                    .foregroundStyle(record.didPlayerWin ? DominoTheme.green.gradient : DominoTheme.red.gradient)
                    .cornerRadius(3)
                BarMark(x: .value("Match", idx + 1), y: .value("Score", record.aiFinalScore))
                    .foregroundStyle(DominoTheme.ivory.opacity(0.2))
                    .cornerRadius(3)
            }
            .frame(height: 160)
            .chartYAxisLabel("Points")
        }
        .padding()
        .background(DominoTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    private var placeholderNote: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 48))
                .foregroundStyle(DominoTheme.ivory.opacity(0.3))
            Text("Play 3+ matches to see charts")
                .foregroundStyle(DominoTheme.secondaryText)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(DominoTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct DominoStatCard: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(value).font(.title2.weight(.bold)).foregroundStyle(color)
            Text(label).font(.caption).foregroundStyle(DominoTheme.secondaryText).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(DominoTheme.card, in: RoundedRectangle(cornerRadius: 14))
    }
}
