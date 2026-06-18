import SwiftUI
import SwiftData

/// Start a fresh random puzzle, or browse and replay past Dailies (archive).
struct PracticeView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var pro: ProStore
    @EnvironmentObject private var ledger: PracticeLedger
    @Query(sort: \DailyResult.date, order: .reverse) private var results: [DailyResult]

    @State private var path = NavigationPath()
    @State private var showPaywall = false

    private var remaining: Int { ledger.remaining(isPro: pro.isPro) }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        practiceCard
                        archiveSection
                    }
                    .padding(18)
                }
            }
            .navigationTitle("Practice")
            .navigationDestination(for: Puzzle.self) { p in
                PlayView(puzzle: p)
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var practiceCard: some View {
        SectionCard(padding: 20) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Fresh puzzle")
                            .font(Theme.rounded(22, .heavy))
                            .foregroundStyle(Theme.ink)
                        Text(pro.isPro
                             ? "Unlimited practice — generate as many as you like."
                             : "Free practice today: \(max(0, remaining)) of \(ProStore.freePracticePerDay) left.")
                            .font(Theme.rounded(14))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    Spacer()
                    Image(systemName: "dice.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(Theme.accent)
                        .accessibilityHidden(true)
                }

                Button {
                    startPractice()
                } label: {
                    HStack {
                        Image(systemName: "sparkles").accessibilityHidden(true)
                        Text("New practice puzzle")
                            .font(Theme.rounded(17, .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Capsule().fill(ledger.canStart(isPro: pro.isPro) ? Theme.accent : Theme.inkSoft))
                }
                .disabled(!ledger.canStart(isPro: pro.isPro) && !pro.isPro)
                .accessibilityHint("Generates a new random puzzle")

                if !pro.isPro && remaining <= 0 {
                    Button {
                        showPaywall = true
                    } label: {
                        Text("Unlock unlimited with Pro")
                            .font(Theme.rounded(15, .semibold))
                            .foregroundStyle(Theme.accentDeep)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var archiveSection: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Daily archive")
                        .font(Theme.rounded(18, .bold))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    if !pro.isPro {
                        Label("Pro", systemImage: "lock.fill")
                            .font(Theme.rounded(12, .semibold))
                            .foregroundStyle(Theme.accentDeep)
                            .accessibilityLabel("Pro feature")
                    }
                }

                if results.isEmpty {
                    EmptyStateView(
                        symbol: "calendar",
                        title: "No history yet",
                        message: "Play a few Dailies and they'll appear here to replay."
                    )
                } else {
                    ForEach(archiveItems) { item in
                        archiveRow(item)
                    }
                    if !pro.isPro {
                        Button {
                            showPaywall = true
                        } label: {
                            Text("Unlock the full archive")
                                .font(Theme.rounded(15, .semibold))
                                .foregroundStyle(Theme.accentDeep)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 4)
                        }
                    }
                }
            }
        }
    }

    private struct ArchiveItem: Identifiable {
        let id: String
        let result: DailyResult
    }

    /// Free users see the most recent few; Pro sees all.
    private var archiveItems: [ArchiveItem] {
        let mapped = results.map { ArchiveItem(id: $0.dateKey, result: $0) }
        return pro.isPro ? mapped : Array(mapped.prefix(3))
    }

    private func archiveRow(_ item: ArchiveItem) -> some View {
        let result = item.result
        let puzzle = PuzzleGenerator.daily(for: result.dateKey)
        let rank = RankLadder.rank(score: result.score, max: max(puzzle.totalPossibleScore, 1))
        return NavigationLink(value: puzzle) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(DateKey.display(result.dateKey))
                        .font(Theme.rounded(16, .semibold))
                        .foregroundStyle(Theme.ink)
                    Text("\(result.wordsFound) words · \(rank.title)")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                Text("\(result.score)")
                    .font(Theme.rounded(17, .bold))
                    .foregroundStyle(Theme.accentDeep)
                    .monospacedDigit()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.inkSoft)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Replay this past daily")
    }

    private func startPractice() {
        guard ledger.canStart(isPro: pro.isPro) else {
            showPaywall = true
            return
        }
        if !pro.isPro { ledger.recordStart() }
        let salt = UInt64(Date().timeIntervalSince1970 * 1000) ^ UInt64(results.count + 1)
        path.append(PuzzleGenerator.practice(salt: salt))
    }
}
