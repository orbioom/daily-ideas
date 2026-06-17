import SwiftUI
import SwiftData

/// The Play tab: a welcoming hub with Continue, Daily, and Quick Play.
struct PlayHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme
    @Query private var progress: [PuzzleProgress]
    @Query private var savedBoards: [SavedBoard]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header

                    if let resume = resumeInfo {
                        continueCard(resume)
                    }

                    dailyCard
                    quickPlayCard
                    progressSummary
                }
                .padding(16)
            }
            .background(ConduitTheme.appBackground(scheme).ignoresSafeArea())
            .navigationTitle("Conduit")
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Welcome back")
                .font(.title2.weight(.bold))
                .foregroundStyle(ConduitTheme.primaryText(scheme))
            Text("Connect every pair and fill the board.")
                .font(.subheadline)
                .foregroundStyle(ConduitTheme.secondaryText(scheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func continueCard(_ resume: ResumeInfo) -> some View {
        NavigationLink {
            GameView(puzzle: resume.puzzle, context: .level, resume: (resume.paths, resume.elapsed, resume.moves))
        } label: {
            ConduitCard {
                HStack(spacing: 14) {
                    miniBoard(resume.puzzle)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Continue")
                            .font(.headline)
                            .foregroundStyle(ConduitTheme.primaryText(scheme))
                        Text(resume.puzzle.name)
                            .font(.subheadline)
                            .foregroundStyle(ConduitTheme.secondaryText(scheme))
                        Text("\(DailyPuzzle.formatTime(resume.elapsed)) · \(resume.moves) moves")
                            .font(.caption)
                            .foregroundStyle(ConduitTheme.secondaryText(scheme))
                    }
                    Spacer()
                    Image(systemName: "play.fill").foregroundStyle(ConduitTheme.accent)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Continue \(resume.puzzle.name)")
    }

    private var dailyCard: some View {
        Group {
            if let daily = DailyPuzzle.puzzle() {
                NavigationLink {
                    GameView(puzzle: daily, context: .daily(dayKey: DailyPuzzle.dayKey()))
                } label: {
                    ConduitCard {
                        HStack(spacing: 14) {
                            Image(systemName: "calendar")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .frame(width: 46, height: 46)
                                .background(Circle().fill(ConduitTheme.accent))
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Today's Daily").font(.headline)
                                    .foregroundStyle(ConduitTheme.primaryText(scheme))
                                Text(dailySolved ? "Solved — replay any time" : "\(daily.size)×\(daily.size) · keep your streak")
                                    .font(.subheadline)
                                    .foregroundStyle(ConduitTheme.secondaryText(scheme))
                            }
                            Spacer()
                            if dailySolved {
                                Image(systemName: "checkmark.seal.fill").foregroundStyle(ConduitTheme.accent)
                            } else {
                                Image(systemName: "chevron.right").foregroundStyle(ConduitTheme.secondaryText(scheme))
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var quickPlayCard: some View {
        Group {
            if let next = nextUnsolved {
                NavigationLink {
                    GameView(puzzle: next, context: .level)
                } label: {
                    ConduitCard {
                        HStack(spacing: 14) {
                            Image(systemName: "bolt.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .frame(width: 46, height: 46)
                                .background(Circle().fill(ConduitTheme.accent.opacity(0.85)))
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Quick play").font(.headline)
                                    .foregroundStyle(ConduitTheme.primaryText(scheme))
                                Text("Next: \(next.name)")
                                    .font(.subheadline)
                                    .foregroundStyle(ConduitTheme.secondaryText(scheme))
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(ConduitTheme.secondaryText(scheme))
                        }
                    }
                }
                .buttonStyle(.plain)
            } else {
                ConduitCard {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.seal.fill").foregroundStyle(ConduitTheme.accent)
                        Text("Every free level solved — nice! Try the Levels tab or unlock Pro packs.")
                            .font(.subheadline)
                            .foregroundStyle(ConduitTheme.secondaryText(scheme))
                    }
                }
            }
        }
    }

    private var progressSummary: some View {
        ConduitCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Your progress").font(.headline)
                    .foregroundStyle(ConduitTheme.primaryText(scheme))
                HStack(spacing: 16) {
                    summaryStat("\(solvedCount)", "solved")
                    summaryStat("\(perfectCount)", "perfect")
                    summaryStat("\(PuzzleBank.all.count)", "total")
                }
            }
        }
    }

    private func summaryStat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.title3.weight(.bold))
                .foregroundStyle(ConduitTheme.accent)
            Text(label).font(.caption).foregroundStyle(ConduitTheme.secondaryText(scheme))
        }
        .frame(maxWidth: .infinity)
    }

    private func miniBoard(_ puzzle: Puzzle) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(ConduitTheme.boardSurface(scheme))
            VStack(spacing: 2) {
                ForEach(0..<min(puzzle.size, 6), id: \.self) { _ in
                    HStack(spacing: 2) {
                        ForEach(0..<min(puzzle.size, 6), id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(ConduitTheme.cellSurface(scheme))
                                .frame(width: 5, height: 5)
                        }
                    }
                }
            }
        }
        .frame(width: 54, height: 54)
        .accessibilityHidden(true)
    }

    // MARK: - Derived

    private struct ResumeInfo {
        let puzzle: Puzzle
        let paths: [PipeColor: [Cell]]
        let elapsed: Int
        let moves: Int
    }

    private var resumeInfo: ResumeInfo? {
        guard let board = savedBoards.sorted(by: { $0.savedAt > $1.savedAt }).first,
              let puzzle = PuzzleBank.puzzle(id: board.puzzleId) else { return nil }
        let paths = SavedPaths.decode(board.pathsJSON).toPaths()
        return ResumeInfo(puzzle: puzzle, paths: paths, elapsed: board.elapsedSeconds, moves: board.moveCount)
    }

    private var solvedCount: Int { progress.filter { $0.solved }.count }
    private var perfectCount: Int { progress.filter { $0.perfect }.count }

    private var dailySolved: Bool {
        ProgressStore.dailyResult(dayKey: DailyPuzzle.dayKey(), in: modelContext)?.solved ?? false
    }

    private var nextUnsolved: Puzzle? {
        let solvedIds = Set(progress.filter { $0.solved }.map { $0.puzzleId })
        return PuzzleBank.all.first { !$0.packId.requiresPro && !solvedIds.contains($0.id) }
            ?? PuzzleBank.all.first { !$0.packId.requiresPro }
    }
}
