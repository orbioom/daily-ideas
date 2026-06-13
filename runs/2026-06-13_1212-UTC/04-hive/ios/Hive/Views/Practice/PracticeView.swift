import SwiftUI
import SwiftData

/// Pick any puzzle from the bank and play it unlimited times. Practice runs use
/// an empty `dayKey`, so they never collide with the dated daily puzzle.
struct PracticeView: View {
    @Environment(ProStore.self) private var pro
    @Environment(\.modelContext) private var context
    @Query private var records: [GameProgress]

    private var puzzles: [Puzzle] { PuzzleBank.all(includePro: pro.isPro) }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 14)], spacing: 14) {
                        ForEach(puzzles) { puzzle in
                            NavigationLink {
                                ZStack {
                                    Theme.bg.ignoresSafeArea()
                                    BoardHost(puzzle: puzzle, dayKey: "")
                                        .id("practice-\(puzzle.id)")
                                }
                                .navigationTitle(puzzle.letterSummary)
                                .navigationBarTitleDisplayMode(.inline)
                            } label: {
                                PuzzleCard(puzzle: puzzle, percent: percent(for: puzzle))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Practice")
        }
    }

    /// Completion percentage of a practice run (found score / max score).
    private func percent(for puzzle: Puzzle) -> Int {
        guard let rec = records.first(where: { $0.puzzleID == puzzle.id && $0.dayKey == "" }) else { return 0 }
        let max = ScoreEngine.maxScore(puzzle)
        guard max > 0 else { return 0 }
        let score = ScoreEngine.currentScore(found: rec.foundWords, in: puzzle)
        return Int((Double(score) / Double(max) * 100).rounded())
    }
}

struct PuzzleCard: View {
    let puzzle: Puzzle
    let percent: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(puzzle.center).uppercased())
                    .font(Theme.rounded(20, .heavy)).foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                Spacer()
                Text("\(percent)%")
                    .font(Theme.rounded(15, .bold))
                    .foregroundStyle(percent >= 70 ? Theme.good : Theme.inkSoft)
            }
            Text(puzzle.outer.sorted().map { String($0).uppercased() }.joined(separator: " "))
                .font(Theme.rounded(15, .semibold)).foregroundStyle(Theme.ink)
                .lineLimit(1).minimumScaleFactor(0.6)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.surfaceAlt)
                    Capsule().fill(percent >= 70 ? Theme.good : Theme.accent)
                        .frame(width: max(4, geo.size.width * Double(percent) / 100.0))
                }
            }
            .frame(height: 7)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Theme.hairline, lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Puzzle centred on \(String(puzzle.center).uppercased()), \(percent) percent complete")
    }
}
