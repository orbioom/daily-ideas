import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query private var results: [GomokuResult]

    private var wins: Int { results.filter { $0.outcome == "win" }.count }
    private var losses: Int { results.filter { $0.outcome == "loss" }.count }
    private var draws: Int { results.filter { $0.outcome == "draw" }.count }
    private var total: Int { results.count }
    private var winRate: Double { total > 0 ? Double(wins) / Double(total) : 0 }
    private var avgMoves: Double {
        guard total > 0 else { return 0 }
        return Double(results.reduce(0) { $0 + $1.moves }) / Double(total)
    }

    private var last14: [GomokuResult] {
        Array(results.prefix(14).reversed())
    }

    var body: some View {
        NavigationStack {
            if total == 0 {
                ContentUnavailableView("No Stats Yet",
                    systemImage: "chart.bar.xaxis",
                    description: Text("Play some games to see your statistics here."))
                    .navigationTitle("Stats")
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Win rate ring
                        winRateRing
                        // Record row
                        recordRow
                        // Chart
                        if last14.count >= 2 {
                            outcomeChart
                        }
                        // By difficulty
                        difficultyBreakdown
                    }
                    .padding()
                }
                .navigationTitle("Stats")
            }
        }
    }

    private var winRateRing: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 14)
                Circle()
                    .trim(from: 0, to: winRate)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack {
                    Text("\(Int(winRate * 100))%")
                        .font(.system(size: 34, weight: .bold))
                    Text("Win Rate")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 140, height: 140)
            Text("\(total) games played")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var recordRow: some View {
        HStack(spacing: 0) {
            statCell("Wins", "\(wins)", .green)
            Divider().frame(height: 50)
            statCell("Losses", "\(losses)", .red)
            Divider().frame(height: 50)
            statCell("Draws", "\(draws)", .orange)
            Divider().frame(height: 50)
            statCell("Avg Moves", String(format: "%.0f", avgMoves), .blue)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func statCell(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var outcomeChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Games")
                .font(.subheadline.weight(.semibold))
            Chart(last14) { r in
                BarMark(x: .value("Date", r.date, unit: .day),
                        y: .value("Moves", r.moves))
                    .foregroundStyle(r.outcome == "win" ? Color.green : r.outcome == "loss" ? Color.red : Color.orange)
            }
            .frame(height: 120)
            .chartXAxis(.hidden)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var difficultyBreakdown: some View {
        let diffs = ["Easy", "Normal", "Hard"]
        return VStack(alignment: .leading, spacing: 8) {
            Text("By Difficulty")
                .font(.subheadline.weight(.semibold))
            ForEach(diffs, id: \.self) { diff in
                let sub = results.filter { $0.difficulty == diff }
                if !sub.isEmpty {
                    let w = sub.filter { $0.outcome == "win" }.count
                    HStack {
                        Text(diff).font(.callout)
                        Spacer()
                        Text("\(w)/\(sub.count) wins")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
