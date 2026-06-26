import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query private var progressList: [PuzzleProgress]

    var completedPuzzles: [PuzzleDefinition] {
        progressList
            .filter { $0.isCompleted }
            .compactMap { p in PuzzleCatalog.puzzle(id: p.puzzleId) }
    }

    var categoryBreakdown: [(PuzzleCategory, Int)] {
        var map: [PuzzleCategory: Int] = [:]
        for p in completedPuzzles { map[p.category, default: 0] += 1 }
        return map.sorted { $0.value > $1.value }
    }

    var totalTime: Int { progressList.reduce(0) { $0 + $1.timeSpentSeconds } }

    var body: some View {
        NavigationStack {
            ScrollView {
                if progressList.isEmpty || completedPuzzles.isEmpty {
                    ContentUnavailableView {
                        Label("No Completions Yet", systemImage: "paintbrush")
                    } description: {
                        Text("Complete some puzzles to see your stats.")
                    }
                } else {
                    VStack(spacing: 20) {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            StatCard2(title: "Completed", value: "\(completedPuzzles.count)", icon: "checkmark.circle.fill", color: .green)
                            StatCard2(title: "Time Painting", value: formatTime(totalTime), icon: "clock.fill", color: DaubTheme.accent)
                            StatCard2(title: "In Progress", value: "\(progressList.filter { !$0.isCompleted }.count)", icon: "paintbrush", color: Color(red: 0.4, green: 0.2, blue: 0.8))
                            StatCard2(title: "Total Puzzles", value: "\(PuzzleCatalog.all.count)", icon: "square.grid.2x2", color: .orange)
                        }

                        if !categoryBreakdown.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Completed by Category")
                                    .font(.headline)
                                Chart(categoryBreakdown, id: \.0) { item in
                                    BarMark(
                                        x: .value("Count", item.1),
                                        y: .value("Category", item.0.rawValue)
                                    )
                                    .foregroundStyle(DaubTheme.accent.gradient)
                                    .cornerRadius(4)
                                    .annotation(position: .trailing) {
                                        Text("\(item.1)").font(.caption2).foregroundStyle(.secondary)
                                    }
                                }
                                .frame(height: CGFloat(categoryBreakdown.count) * 44)
                                .chartXAxis(.hidden)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        // Recent completions
                        let recent = progressList
                            .filter { $0.isCompleted }
                            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
                            .prefix(5)

                        if !recent.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Recent Completions")
                                    .font(.headline)
                                ForEach(Array(recent), id: \.puzzleId) { p in
                                    if let def = PuzzleCatalog.puzzle(id: p.puzzleId) {
                                        HStack {
                                            Label(def.title, systemImage: def.category.icon)
                                            Spacer()
                                            if let date = p.completedAt {
                                                Text(date, style: .date)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Progress")
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
}

private struct StatCard2: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.title2.bold())
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}
