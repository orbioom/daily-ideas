import SwiftUI
import SwiftData

/// The last 60 daily puzzles, computed from `DailyEngine`, each showing your
/// rank/score for that day. Tap to play or resume that day's puzzle. This is
/// the feature NYT gates behind a subscription — here it's free.
struct ArchiveView: View {
    @Environment(\.modelContext) private var context
    @Query private var records: [GameProgress]

    private struct Day: Identifiable {
        let date: Date
        let key: String
        let puzzle: Puzzle
        var id: String { key }
    }

    private var days: [Day] {
        let bank = PuzzleBank.core
        guard !bank.isEmpty else { return [] }
        let cal = Calendar.current
        var result: [Day] = []
        for offset in 0..<60 {
            guard let date = cal.date(byAdding: .day, value: -offset, to: .now) else { continue }
            let idx = DailyEngine.puzzleIndex(for: date, count: bank.count)
            guard bank.indices.contains(idx) else { continue }
            result.append(Day(date: date, key: DailyEngine.dayKey(for: date), puzzle: bank[idx]))
        }
        return result
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if days.isEmpty {
                    EmptyStateView(icon: "calendar",
                                   title: "Archive unavailable",
                                   message: "Daily puzzles will appear here once the bank loads.")
                } else {
                    List {
                        ForEach(days) { day in
                            NavigationLink {
                                ZStack {
                                    Theme.bg.ignoresSafeArea()
                                    BoardHost(puzzle: day.puzzle, dayKey: day.key)
                                        .id("archive-\(day.key)-\(day.puzzle.id)")
                                }
                                .navigationTitle(Fmt.relativeDay(day.date))
                                .navigationBarTitleDisplayMode(.inline)
                            } label: {
                                row(for: day)
                            }
                            .listRowBackground(Theme.surface)
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Archive")
        }
    }

    private func row(for day: Day) -> some View {
        let rec = records.first { $0.puzzleID == day.puzzle.id && $0.dayKey == day.key }
        let max = ScoreEngine.maxScore(day.puzzle)
        let score = rec.map { ScoreEngine.currentScore(found: $0.foundWords, in: day.puzzle) } ?? 0
        let rank = ScoreEngine.rank(for: score, max: max)
        let played = rec != nil && score > 0
        return HStack(spacing: 14) {
            Text(String(day.puzzle.center).uppercased())
                .font(Theme.rounded(18, .heavy)).foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Theme.accent, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(Fmt.relativeDay(day.date))
                    .font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                Text(played ? rank.name : "Not started")
                    .font(Theme.rounded(13, .medium))
                    .foregroundStyle(played ? Theme.accent : Theme.inkSoft)
            }
            Spacer()
            if played {
                Text("\(score)/\(max)")
                    .font(Theme.rounded(14, .bold)).foregroundStyle(Theme.inkSoft)
            } else {
                Image(systemName: "play.circle").foregroundStyle(Theme.inkFaint)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(Fmt.relativeDay(day.date)), \(played ? "\(rank.name), \(score) of \(max) points" : "not started")")
    }
}
