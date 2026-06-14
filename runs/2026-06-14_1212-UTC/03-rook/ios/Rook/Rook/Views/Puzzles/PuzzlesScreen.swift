import SwiftUI
import SwiftData

/// Browse and solve puzzles: daily hero + full library with solved checks and Pro gating.
struct PuzzlesScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query private var results: [PuzzleResult]

    @State private var paywallReason: PaywallReason?

    private let daily = PuzzleBank.daily()

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        dailyHero
                        libraryHeader
                        puzzleGrid
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Puzzles")
            .toolbar {
                if !isPro {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { paywallReason = .puzzleLibrary } label: {
                            Label("Pro", systemImage: "crown.fill")
                                .font(Theme.rounded(13, .semibold))
                        }
                    }
                }
            }
            .navigationDestination(for: Puzzle.self) { puzzle in
                PuzzlePlayerView(puzzle: puzzle)
            }
            .sheet(item: $paywallReason) { reason in
                PaywallView(reason: reason)
            }
        }
    }

    // MARK: Solved lookups

    private func isSolved(_ id: Int) -> Bool {
        results.contains { $0.puzzleID == id && $0.solved }
    }

    private func isAttempted(_ id: Int) -> Bool {
        results.contains { $0.puzzleID == id }
    }

    private var solvedCount: Int {
        Set(results.filter { $0.solved }.map { $0.puzzleID }).count
    }

    // MARK: Daily hero

    private var dailyHero: some View {
        NavigationLink(value: daily) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Daily Puzzle", systemImage: "calendar")
                        .font(Theme.rounded(13, .semibold))
                        .foregroundStyle(Theme.accent)
                    Spacer()
                    if isSolved(daily.id) {
                        Label("Solved", systemImage: "checkmark.seal.fill")
                            .font(Theme.rounded(12, .semibold))
                            .foregroundStyle(Theme.good)
                    }
                }
                HStack(alignment: .top, spacing: 14) {
                    BoardView(board: daily.board,
                              theme: settings.effectiveBoardTheme(isPro: isPro),
                              pieceStyle: settings.pieceStyle,
                              flipped: daily.sideToMove == .black,
                              showCoordinates: false)
                        .frame(width: 128, height: 128)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(daily.prompt)
                            .font(Theme.serif(19, .semibold))
                            .foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 6) {
                            TagPill(text: daily.theme.rawValue, symbol: daily.theme.symbol)
                        }
                        Spacer(minLength: 0)
                        Text("Tap to solve")
                            .font(Theme.rounded(13, .semibold))
                            .foregroundStyle(Theme.accent)
                    }
                    Spacer(minLength: 0)
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.surface))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Theme.accent.opacity(0.25), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: Library

    private var libraryHeader: some View {
        HStack {
            Text("Library")
                .font(Theme.serif(20, .bold))
                .foregroundStyle(Theme.ink)
            Spacer()
            Text("\(solvedCount)/\(PuzzleBank.all.count) solved")
                .font(Theme.rounded(13, .medium))
                .foregroundStyle(Theme.inkSoft)
        }
    }

    private var puzzleGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(PuzzleBank.all) { puzzle in
                puzzleCell(puzzle)
            }
        }
    }

    @ViewBuilder
    private func puzzleCell(_ puzzle: Puzzle) -> some View {
        let unlocked = Pro.canPlayPuzzle(id: puzzle.id, isPro: isPro)
        Group {
            if unlocked {
                NavigationLink(value: puzzle) { cellContent(puzzle, locked: false) }
                    .buttonStyle(.plain)
            } else {
                Button { paywallReason = .puzzleLibrary } label: { cellContent(puzzle, locked: true) }
                    .buttonStyle(.plain)
            }
        }
    }

    private func cellContent(_ puzzle: Puzzle, locked: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                BoardView(board: puzzle.board,
                          theme: settings.effectiveBoardTheme(isPro: isPro),
                          pieceStyle: settings.pieceStyle,
                          flipped: puzzle.sideToMove == .black,
                          showCoordinates: false)
                    .frame(height: 150)
                    .opacity(locked ? 0.5 : 1)
                if locked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(7)
                        .background(Circle().fill(Theme.ink.opacity(0.7)))
                        .padding(6)
                } else if isSolved(puzzle.id) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Theme.good)
                        .padding(6)
                } else if isAttempted(puzzle.id) {
                    Image(systemName: "circle.dashed")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.gold)
                        .padding(6)
                }
            }
            Text(puzzle.theme.rawValue)
                .font(Theme.rounded(13, .semibold))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
            Text(puzzle.difficultyLabel)
                .font(Theme.rounded(11))
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(puzzle.theme.rawValue), \(puzzle.difficultyLabel)\(locked ? ", locked, Pro" : isSolved(puzzle.id) ? ", solved" : "")")
    }
}
