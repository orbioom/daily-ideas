import SwiftUI
import SwiftData

struct StatsView: View {
    @Query(sort: \PuzzleRecord.date, order: .reverse) private var records: [PuzzleRecord]

    var body: some View {
        ZStack {
            SeekTheme.background.ignoresSafeArea()
            if records.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        overviewGrid
                        categoryBreakdown
                        recentGames
                    }
                    .padding(16)
                }
            }
        }
        .navigationTitle("Stats")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(SeekTheme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 52))
                .foregroundStyle(SeekTheme.textSecondary)
            Text("No Games Yet")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(SeekTheme.textPrimary)
            Text("Complete a puzzle to see your stats here.")
                .font(.system(size: 15))
                .foregroundStyle(SeekTheme.textSecondary)
        }
    }

    var overviewGrid: some View {
        let completed = records.filter { $0.completed }
        let avgTime = completed.isEmpty ? 0 : completed.reduce(0) { $0 + $1.timeSeconds } / completed.count
        let bestTime = completed.min(by: { $0.timeSeconds < $1.timeSeconds })?.timeSeconds ?? 0
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statCard(value: "\(records.count)", label: "Puzzles Played", color: SeekTheme.accent)
            statCard(value: "\(completed.count)", label: "Completed", color: SeekTheme.foundColor)
            statCard(value: formatTime(avgTime), label: "Avg Time", color: SeekTheme.accentGold)
            statCard(value: formatTime(bestTime), label: "Best Time", color: SeekTheme.accent)
        }
    }

    func statCard(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(SeekTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(SeekTheme.surface, in: RoundedRectangle(cornerRadius: 12))
    }

    var categoryBreakdown: some View {
        let byCategory = Dictionary(grouping: records, by: { $0.category })
        return VStack(alignment: .leading, spacing: 10) {
            Text("By Category")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(SeekTheme.textSecondary)
            ForEach(byCategory.sorted(by: { $0.value.count > $1.value.count }), id: \.key) { cat, recs in
                HStack {
                    Text(cat)
                        .font(.system(size: 14))
                        .foregroundStyle(SeekTheme.textPrimary)
                    Spacer()
                    Text("\(recs.count) game\(recs.count == 1 ? "" : "s")")
                        .font(.system(size: 13))
                        .foregroundStyle(SeekTheme.textSecondary)
                    Text("· \(recs.filter { $0.completed }.count) ✓")
                        .font(.system(size: 13))
                        .foregroundStyle(SeekTheme.foundColor)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(SeekTheme.surface, in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    var recentGames: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Games")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(SeekTheme.textSecondary)
            ForEach(records.prefix(10)) { r in
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(r.category)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(SeekTheme.textPrimary)
                        HStack(spacing: 8) {
                            Text(r.difficulty)
                                .font(.system(size: 12))
                                .foregroundStyle(SeekTheme.textSecondary)
                            Text("·")
                                .foregroundStyle(SeekTheme.textSecondary)
                            Text("\(r.wordsFound)/\(r.totalWords) words")
                                .font(.system(size: 12))
                                .foregroundStyle(SeekTheme.textSecondary)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 3) {
                        Text(formatTime(r.timeSeconds))
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(r.completed ? SeekTheme.foundColor : SeekTheme.accentGold)
                        Text(r.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 11))
                            .foregroundStyle(SeekTheme.textSecondary)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(SeekTheme.surface, in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    func formatTime(_ s: Int) -> String {
        guard s > 0 else { return "—" }
        return String(format: "%d:%02d", s/60, s%60)
    }
}
