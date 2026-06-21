import SwiftUI
import SwiftData
import Charts

struct RungStatsView: View {
    @Query(sort: \RungResult.date, order: .reverse) private var results: [RungResult]

    private var solved: [RungResult] { results.filter(\.solved) }
    private var solveRate: Double {
        results.isEmpty ? 0 : Double(solved.count) / Double(results.count)
    }
    private var avgSteps: Double {
        solved.isEmpty ? 0 : Double(solved.map(\.steps).reduce(0, +)) / Double(solved.count)
    }
    private var underPar: Int { solved.filter { $0.steps <= $0.parSteps }.count }

    var body: some View {
        NavigationStack {
            if results.isEmpty {
                ContentUnavailableView("No Stats Yet", systemImage: "chart.bar",
                    description: Text("Complete a puzzle to see your stats."))
                    .navigationTitle("Stats")
            } else {
                List {
                    Section("Overview") {
                        statRow("Puzzles Played", value: "\(results.count)")
                        statRow("Solved", value: "\(solved.count)")
                        statRow("Solve Rate", value: String(format: "%.0f%%", solveRate * 100))
                        statRow("Under Par", value: "\(underPar)")
                        statRow("Avg Steps", value: String(format: "%.1f", avgSteps))
                    }
                    if solved.count >= 3 {
                        Section("Recent Performance") {
                            Chart(solved.prefix(10).reversed()) { r in
                                BarMark(
                                    x: .value("Date", r.date, unit: .day),
                                    y: .value("Steps", r.steps)
                                )
                                .foregroundStyle(r.steps <= r.parSteps ? Color.green : Color.orange)
                            }
                            .frame(height: 100)
                            .chartXAxis(.hidden)
                            .chartYAxisLabel("Steps")
                        }
                    }
                    Section("Recent Games") {
                        ForEach(results.prefix(15)) { r in
                            HStack {
                                Image(systemName: r.solved ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(r.solved ? .green : .red)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(r.startWord.uppercased()) → \(r.targetWord.uppercased())")
                                        .font(.subheadline.weight(.semibold))
                                    Text(r.solved ? "\(r.steps) steps (par \(r.parSteps))" : "Not solved")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(r.date, style: .date)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .navigationTitle("Stats")
            }
        }
    }

    private func statRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).foregroundStyle(.secondary)
        }
    }
}
