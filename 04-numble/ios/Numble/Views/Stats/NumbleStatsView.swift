import SwiftUI
import SwiftData
import Charts

struct NumbleStatsView: View {
    @Query(sort: \NumbleResult.date, order: .reverse) private var results: [NumbleResult]

    private var solved: [NumbleResult] { results.filter(\.solved) }
    private var solveRate: Double { results.isEmpty ? 0 : Double(solved.count) / Double(results.count) }
    private var avgAttempts: Double {
        solved.isEmpty ? 0 : Double(solved.map(\.attemptsUsed).reduce(0, +)) / Double(solved.count)
    }

    private var distributionData: [(attempt: Int, count: Int)] {
        (1...6).map { n in (n, solved.filter { $0.attemptsUsed == n }.count) }
    }

    var body: some View {
        NavigationStack {
            if results.isEmpty {
                ContentUnavailableView("No Stats Yet", systemImage: "function",
                    description: Text("Play a round to see your stats."))
                    .navigationTitle("Stats")
            } else {
                List {
                    Section("Overview") {
                        statRow("Games Played", "\(results.count)")
                        statRow("Solved", "\(solved.count)")
                        statRow("Solve Rate", String(format: "%.0f%%", solveRate * 100))
                        statRow("Avg Attempts", String(format: "%.1f", avgAttempts))
                    }
                    if solved.count >= 2 {
                        Section("Guess Distribution") {
                            Chart(distributionData, id: \.attempt) { d in
                                BarMark(x: .value("Attempts", d.attempt),
                                        y: .value("Count", d.count))
                                    .foregroundStyle(.purple)
                            }
                            .frame(height: 120)
                            .chartXAxisLabel("Guess #")
                        }
                    }
                    Section("Recent") {
                        ForEach(results.prefix(20)) { r in
                            HStack {
                                Image(systemName: r.solved ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(r.solved ? .green : .red)
                                Text(r.equation)
                                    .font(.system(.body, design: .monospaced))
                                Spacer()
                                if r.solved {
                                    Text("\(r.attemptsUsed)/\(r.maxAttempts)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
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

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack { Text(label); Spacer(); Text(value).foregroundStyle(.secondary) }
    }
}
