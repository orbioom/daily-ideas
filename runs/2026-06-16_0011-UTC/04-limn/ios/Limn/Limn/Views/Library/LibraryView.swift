import SwiftUI
import SwiftData

/// The puzzle library home: themed packs, each a grid of mini-thumbnail tiles. Completed
/// puzzles reveal their picture and best time; locked packs are marked Pro.
struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query private var records: [PuzzleRecord]
    @Query private var savedGames: [SavedGame]

    @State private var paywallReason: PaywallReason?

    private var recordByID: [String: PuzzleRecord] {
        Dictionary(records.map { ($0.puzzleID, $0) }, uniquingKeysWith: { a, _ in a })
    }
    private var savedIDs: Set<String> { Set(savedGames.map(\.puzzleID)) }

    private let columns = [GridItem(.adaptive(minimum: 96), spacing: 12)]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 22) {
                        overviewBar
                        ForEach(PuzzleBank.packs) { pack in
                            packSection(pack)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Puzzles")
            .navigationDestination(for: Puzzle.self) { puzzle in
                PlayView(puzzle: puzzle)
            }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        }
    }

    // MARK: - Overview

    private var overviewBar: some View {
        let solved = records.filter { $0.completed }.count
        let total = PuzzleBank.allPuzzles.count
        return HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 26))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(solved) of \(total) solved")
                    .font(Theme.rounded(17, .bold))
                    .foregroundStyle(Theme.ink)
                Text("Pick a pack and start filling.")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
        .accessibilityElement(children: .combine)
    }

    // MARK: - Pack section

    private func packSection(_ pack: PuzzlePack) -> some View {
        let locked = pack.requiresPro && !isPro
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: pack.symbol)
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 1) {
                    Text(pack.title).font(Theme.rounded(18, .bold)).foregroundStyle(Theme.ink)
                    Text(pack.subtitle).font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                if locked { ProLockChip() }
            }

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(pack.puzzles) { puzzle in
                    puzzleTile(puzzle, locked: locked)
                }
            }
        }
    }

    @ViewBuilder
    private func puzzleTile(_ puzzle: Puzzle, locked: Bool) -> some View {
        let record = recordByID[puzzle.id]
        let completed = record?.completed ?? false
        let inProgress = savedIDs.contains(puzzle.id)

        Group {
            if locked {
                Button { paywallReason = .lockedPack } label: { tileBody(puzzle, completed: false, locked: true, inProgress: false, record: nil) }
                    .buttonStyle(PressableScale())
            } else {
                NavigationLink(value: puzzle) {
                    tileBody(puzzle, completed: completed, locked: false, inProgress: inProgress, record: record)
                }
                .buttonStyle(PressableScale())
            }
        }
        .accessibilityLabel(tileAccessibility(puzzle, completed: completed, locked: locked, inProgress: inProgress, record: record))
    }

    private func tileBody(_ puzzle: Puzzle, completed: Bool, locked: Bool, inProgress: Bool, record: PuzzleRecord?) -> some View {
        VStack(spacing: 6) {
            PuzzleThumbnail(puzzle: puzzle, revealed: completed, locked: locked)
                .aspectRatio(1, contentMode: .fit)
            Text(completed ? puzzle.name : (locked ? "Locked" : "Solve me"))
                .font(Theme.rounded(12, .semibold))
                .foregroundStyle(completed ? Theme.ink : Theme.inkSoft)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(subtitleText(completed: completed, inProgress: inProgress, record: record))
                .font(Theme.mono(11, .medium))
                .foregroundStyle(completed ? Theme.accentDeep : Theme.inkFaint)
                .lineLimit(1)
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .cardSurface(fill: Theme.surface, corner: Theme.cornerSmall)
    }

    private func subtitleText(completed: Bool, inProgress: Bool, record: PuzzleRecord?) -> String {
        if completed, let t = record?.bestTimeSeconds, t > 0 {
            return timeString(t)
        }
        if inProgress { return "In progress" }
        return "—"
    }

    private func timeString(_ seconds: Int) -> String {
        let m = seconds / 60, s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    private func tileAccessibility(_ puzzle: Puzzle, completed: Bool, locked: Bool, inProgress: Bool, record: PuzzleRecord?) -> String {
        if locked { return "\(puzzle.sizeLabel) puzzle, locked. Requires Pro." }
        if completed {
            let t = record?.bestTimeSeconds ?? 0
            return "\(puzzle.name), \(puzzle.sizeLabel), solved in \(timeString(t)). Double-tap to replay."
        }
        if inProgress { return "\(puzzle.sizeLabel) puzzle, in progress. Double-tap to resume." }
        return "Unsolved \(puzzle.sizeLabel) puzzle. Double-tap to play."
    }
}
