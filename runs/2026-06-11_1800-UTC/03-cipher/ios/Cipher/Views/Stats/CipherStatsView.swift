import SwiftUI
import SwiftData
import Charts

struct CipherStatsView: View {
    @Query private var allProgress: [PuzzleProgress]

    private var solved: [PuzzleProgress] { allProgress.filter(\.isSolved) }
    private var streak: Int {
        let today = Calendar.current.startOfDay(for: Date())
        var current = today
        var count = 0
        while true {
            let puzzle = CryptoPuzzle.puzzle(for: current)
            if let p = allProgress.first(where: { $0.puzzleId == puzzle.id }), p.isSolved {
                count += 1
                current = Calendar.current.date(byAdding: .day, value: -1, to: current) ?? current
            } else {
                break
            }
        }
        return count
    }
    private var avgTime: Int {
        guard !solved.isEmpty else { return 0 }
        return solved.reduce(0) { $0 + $1.elapsedSeconds } / solved.count
    }
    private var avgHints: Double {
        guard !solved.isEmpty else { return 0 }
        return Double(solved.reduce(0) { $0 + $1.hintsUsed }) / Double(solved.count)
    }

    private var timeDistribution: [(label: String, count: Int)] {
        var bins: [String: Int] = ["<1min": 0, "1–3min": 0, "3–5min": 0, ">5min": 0]
        for p in solved {
            let m = p.elapsedSeconds / 60
            if m < 1 { bins["<1min", default: 0] += 1 }
            else if m < 3 { bins["1–3min", default: 0] += 1 }
            else if m < 5 { bins["3–5min", default: 0] += 1 }
            else { bins[">5min", default: 0] += 1 }
        }
        return [("<1min", bins["<1min"] ?? 0), ("1–3min", bins["1–3min"] ?? 0),
                ("3–5min", bins["3–5min"] ?? 0), (">5min", bins[">5min"] ?? 0)]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if allProgress.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(CipherTheme.accent.opacity(0.3))
                            .accessibilityHidden(true)
                        Text("No stats yet")
                            .font(.headline)
                            .foregroundStyle(CipherTheme.text)
                        Text("Solve your first puzzle to see statistics.")
                            .foregroundStyle(CipherTheme.subtle)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, minHeight: 400)
                } else {
                    VStack(spacing: 20) {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            StatCard(value: "\(streak)", label: "Streak", icon: "flame.fill", color: .orange)
                            StatCard(value: "\(solved.count)", label: "Solved", icon: "checkmark.seal.fill", color: CipherTheme.solved)
                            StatCard(value: timeStr(avgTime), label: "Avg Time", icon: "clock.fill", color: CipherTheme.accent)
                            StatCard(value: String(format: "%.1f", avgHints), label: "Avg Hints", icon: "lightbulb.fill", color: CipherTheme.amber)
                        }

                        if solved.count >= 3 {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Solve Time Distribution")
                                    .font(.headline)
                                    .foregroundStyle(CipherTheme.text)
                                Chart(timeDistribution, id: \.label) { item in
                                    BarMark(x: .value("Range", item.label), y: .value("Count", item.count))
                                        .foregroundStyle(CipherTheme.accent.gradient)
                                        .cornerRadius(6)
                                }
                                .frame(height: 140)
                            }
                            .padding()
                            .background(CipherTheme.card, in: RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 80)
                }
            }
            .background(CipherTheme.bg)
            .navigationTitle("Stats")
        }
    }

    private func timeStr(_ sec: Int) -> String {
        let m = sec / 60; let s = sec % 60
        return String(format: "%d:%02d", m, s)
    }
}

private struct StatCard: View {
    let value: String; let label: String; let icon: String; let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).font(.title3).foregroundStyle(color).accessibilityHidden(true)
            Text(value).font(.title2.weight(.bold)).foregroundStyle(CipherTheme.text)
            Text(label).font(.caption).foregroundStyle(CipherTheme.subtle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(CipherTheme.card, in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}
