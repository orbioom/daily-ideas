import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query(sort: \EuchreGameRecord.date, order: .reverse) private var records: [EuchreGameRecord]

    private var wins: Int { records.filter(\.humanTeamWon).count }
    private var losses: Int { records.filter { !$0.humanTeamWon }.count }
    private var winRate: Double {
        records.isEmpty ? 0 : Double(wins) / Double(records.count)
    }
    private var avgScore: Double {
        records.isEmpty ? 0 : Double(records.map(\.humanTeamScore).reduce(0, +)) / Double(records.count)
    }
    private var last10: [EuchreGameRecord] {
        Array(records.prefix(10).reversed())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if records.isEmpty {
                    EmptyStateView(
                        icon: "chart.bar.xaxis",
                        title: "No Stats Yet",
                        message: "Play some games to see your statistics here."
                    )
                    .padding(.top, 60)
                } else {
                    VStack(spacing: 20) {
                        // Win Rate Donut
                        VStack(spacing: 12) {
                            Text("Win Rate")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            HStack(spacing: 24) {
                                Chart {
                                    SectorMark(
                                        angle: .value("Wins", wins),
                                        innerRadius: .ratio(0.6),
                                        angularInset: 2
                                    )
                                    .foregroundStyle(BuckTheme.accent)

                                    SectorMark(
                                        angle: .value("Losses", max(losses, 0)),
                                        innerRadius: .ratio(0.6),
                                        angularInset: 2
                                    )
                                    .foregroundStyle(Color.secondary.opacity(0.25))
                                }
                                .frame(width: 120, height: 120)
                                .overlay(
                                    VStack(spacing: 2) {
                                        Text("\(Int(winRate * 100))%")
                                            .font(.system(size: 22, weight: .black, design: .rounded))
                                        Text("Won")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                )

                                VStack(alignment: .leading, spacing: 14) {
                                    StatRow(label: "Games Played", value: "\(records.count)")
                                    StatRow(label: "Wins", value: "\(wins)")
                                    StatRow(label: "Losses", value: "\(losses)")
                                    StatRow(label: "Avg Score", value: String(format: "%.1f", avgScore))
                                }
                            }
                        }
                        .padding(16)
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        // Recent 10 games bar chart
                        if last10.count >= 2 {
                            VStack(spacing: 12) {
                                Text("Last \(last10.count) Games")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Chart(Array(last10.enumerated()), id: \.offset) { index, record in
                                    BarMark(
                                        x: .value("Game", index + 1),
                                        y: .value("Your Score", record.humanTeamScore)
                                    )
                                    .foregroundStyle(record.humanTeamWon ? BuckTheme.accent : Color.secondary.opacity(0.5))
                                    .cornerRadius(4)
                                }
                                .frame(height: 160)
                                .chartYScale(domain: 0...10)
                                .chartXAxis {
                                    AxisMarks(values: .automatic) { _ in
                                        AxisValueLabel()
                                    }
                                }
                                .chartYAxis {
                                    AxisMarks(values: [0, 5, 10]) { _ in
                                        AxisGridLine()
                                        AxisValueLabel()
                                    }
                                }

                                HStack(spacing: 16) {
                                    Label("Win", systemImage: "square.fill")
                                        .font(.caption)
                                        .foregroundStyle(BuckTheme.accent)
                                    Label("Loss", systemImage: "square.fill")
                                        .font(.caption)
                                        .foregroundStyle(Color.secondary)
                                }
                            }
                            .padding(16)
                            .background(Color(UIColor.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }

                        // Difficulty breakdown
                        VStack(spacing: 12) {
                            Text("By Difficulty")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            ForEach(["Beginner", "Standard", "Advanced"], id: \.self) { diff in
                                let diffRecords = records.filter { $0.difficulty == diff }
                                if !diffRecords.isEmpty {
                                    let diffWins = diffRecords.filter(\.humanTeamWon).count
                                    HStack {
                                        Text(diff)
                                            .font(.subheadline)
                                        Spacer()
                                        Text("\(diffWins)/\(diffRecords.count) wins")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        .padding(16)
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Statistics")
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.title3.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
