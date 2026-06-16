import SwiftUI
import SwiftData

/// Lists the puzzles within a pack at the chosen difficulty, with solved checks and best times.
struct PuzzleListView: View {
    let pack: WordPack
    let difficulty: Difficulty

    @EnvironmentObject private var pro: ProStore
    @Query private var allProgress: [PuzzleProgress]
    @State private var showPaywall = false

    private var puzzles: [Puzzle] {
        (0..<FreeTier.totalPuzzlesPerPackPerDifficulty).map {
            Puzzle(packID: pack.id, index: $0, difficulty: difficulty)
        }
    }

    var body: some View {
        List {
            Section {
                ForEach(puzzles) { puzzle in
                    row(for: puzzle)
                }
            } header: {
                Text("\(difficulty.rawValue) • \(difficulty.gridSize)×\(difficulty.gridSize) grid")
                    .font(Theme.rounded(13, .medium))
                    .foregroundStyle(Theme.inkSoft)
                    .textCase(nil)
            } footer: {
                if !pro.isPro {
                    Text("Free includes the first \(FreeTier.puzzlesPerPackPerDifficulty) puzzles. Unlock Pro for unlimited play.")
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(pack.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    @ViewBuilder
    private func row(for puzzle: Puzzle) -> some View {
        let locked = puzzle.isLocked(isPro: pro.isPro, packIsPro: pack.isPro)
        let record = progress(for: puzzle)
        let solved = record?.isComplete ?? false

        if locked {
            Button {
                showPaywall = true
            } label: {
                rowContent(puzzle: puzzle, solved: false, best: nil, locked: true)
            }
            .buttonStyle(.plain)
            .listRowBackground(Theme.surface)
        } else {
            NavigationLink {
                GameView(
                    puzzle: puzzle,
                    pack: pack,
                    isDaily: false,
                    dailyDateKey: nil
                )
            } label: {
                rowContent(puzzle: puzzle, solved: solved, best: record?.bestTimeSec, locked: false)
            }
            .listRowBackground(Theme.surface)
        }
    }

    private func rowContent(puzzle: Puzzle, solved: Bool, best: Int?, locked: Bool) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(solved ? Theme.good.opacity(0.16) : pack.color.opacity(0.14))
                    .frame(width: 38, height: 38)
                Image(systemName: solved ? "checkmark" : (locked ? "lock.fill" : "puzzlepiece.fill"))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(solved ? Theme.good : (locked ? Theme.inkSoft : pack.color))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(puzzle.title(packName: pack.name))
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                if let best {
                    Text("Best \(Formatters.clock(best))")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                } else if locked {
                    Text("Pro")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                } else {
                    Text("Not started")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            Spacer()
            if locked {
                LockBadge()
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(puzzle.title(packName: pack.name))
        .accessibilityValue(locked ? "Locked" : (solved ? "Solved" : "Not started"))
    }

    private func progress(for puzzle: Puzzle) -> PuzzleProgress? {
        allProgress.first { $0.puzzleKey == puzzle.key }
    }
}
