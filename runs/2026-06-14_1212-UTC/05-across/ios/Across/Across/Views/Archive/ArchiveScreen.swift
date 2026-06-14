import SwiftUI
import SwiftData

/// The full puzzle library. Shows solved status, time, and difficulty. Free users
/// can play the daily plus a limited number of archive puzzles; the rest are
/// gated behind Pro.
struct ArchiveScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @Query private var allProgress: [PuzzleProgress]

    @State private var filter: Filter = .all
    @State private var paywallReason: PaywallReason?

    enum Filter: String, CaseIterable, Identifiable {
        case all = "All"
        case unsolved = "To do"
        case solved = "Solved"
        var id: String { rawValue }
    }

    private var todayDailyID: String { PuzzleBank.dailyID() }

    /// Archive puzzles excluding today's daily (that lives on Today). The free
    /// index is the position among non-daily puzzles, used for gating.
    private var archivePuzzles: [(puzzle: Puzzle, freeIndex: Int)] {
        var idx = 0
        var out: [(Puzzle, Int)] = []
        for p in PuzzleBank.all where p.id != todayDailyID {
            out.append((p, idx))
            idx += 1
        }
        return out
    }

    private func progress(for id: String) -> PuzzleProgress? {
        allProgress.first { $0.puzzleID == id }
    }

    private var filtered: [(puzzle: Puzzle, freeIndex: Int)] {
        archivePuzzles.filter { item in
            let solved = progress(for: item.puzzle.id)?.completed ?? false
            switch filter {
            case .all: return true
            case .unsolved: return !solved
            case .solved: return solved
            }
        }
    }

    private let columns = [GridItem(.adaptive(minimum: 160), spacing: 14)]

    var body: some View {
        NavigationStack {
            ScrollView {
                if !isPro { proBanner }
                Picker("Filter", selection: $filter) {
                    ForEach(Filter.allCases) { f in Text(f.rawValue).tag(f) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 8)

                if filtered.isEmpty {
                    EmptyStateView(symbol: "tray",
                                   title: emptyTitle,
                                   message: emptyMessage)
                        .padding(.top, 40)
                } else {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(filtered, id: \.puzzle.id) { item in
                            cardOrLock(item)
                        }
                    }
                    .padding(16)
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Archive")
            .navigationDestination(for: PuzzleRoute.self) { route in
                boardScreen(for: route)
            }
            .sheet(item: $paywallReason) { reason in PaywallView(reason: reason) }
        }
    }

    private var emptyTitle: String {
        switch filter {
        case .solved: return "No solves yet"
        case .unsolved: return "All caught up"
        case .all: return "No puzzles"
        }
    }
    private var emptyMessage: String {
        switch filter {
        case .solved: return "Solve an archive puzzle and it'll show up here with your time."
        case .unsolved: return "You've finished every puzzle in this view. Nicely done."
        case .all: return "Puzzles will appear here."
        }
    }

    private var proBanner: some View {
        Button { paywallReason = .archive } label: {
            HStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Unlock the full archive")
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(Theme.ink)
                    Text("Free includes \(Pro.freeArchiveLimit) archive puzzles · \(Pro.priceLabel) one-time")
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Theme.inkFaint)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surface))
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    @ViewBuilder
    private func cardOrLock(_ item: (puzzle: Puzzle, freeIndex: Int)) -> some View {
        let unlocked = Pro.archiveUnlocked(freeIndex: item.freeIndex, isPro: isPro)
        if unlocked {
            NavigationLink(value: PuzzleRoute(puzzleID: item.puzzle.id, dailyKey: nil)) {
                ArchiveCard(puzzle: item.puzzle, progress: progress(for: item.puzzle.id), locked: false)
            }
            .buttonStyle(.plain)
        } else {
            Button { paywallReason = .archive } label: {
                ArchiveCard(puzzle: item.puzzle, progress: nil, locked: true)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func boardScreen(for route: PuzzleRoute) -> some View {
        if let puzzle = PuzzleBank.puzzle(id: route.puzzleID) {
            BoardScreen(puzzle: puzzle,
                        dailyDateKey: route.dailyKey,
                        progress: allProgress.first { $0.puzzleID == route.puzzleID },
                        settings: settings)
        } else {
            EmptyStateView(symbol: "questionmark.square.dashed",
                           title: "Puzzle not found",
                           message: "This puzzle is no longer available.")
        }
    }
}
