import SwiftUI
import SwiftData

/// Home: deck grid with due/new badges, a "due today" summary, and study-all.
struct DecksScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @Query(sort: \Deck.createdDate, order: .reverse) private var allDecks: [Deck]

    @State private var editingDeck: Deck?
    @State private var showNewDeck = false
    @State private var paywallReason: PaywallReason?
    @State private var studyConfig: StudyConfig?

    private var decks: [Deck] {
        allDecks.filter { !$0.isArchived }
    }

    private var totalDueToday: Int {
        decks.reduce(0) { $0 + StudyQueue.dueCount(in: $1.cards) }
    }

    private var totalNewAvailable: Int {
        decks.reduce(0) { acc, deck in
            acc + min(StudyQueue.newCount(in: deck.cards), settings.boundedNewLimit())
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Decks")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { attemptCreate() } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("New deck")
                }
            }
            .sheet(isPresented: $showNewDeck) { DeckEditorView(deck: nil) }
            .sheet(item: $editingDeck) { DeckEditorView(deck: $0) }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
            .fullScreenCover(item: $studyConfig) { config in
                StudyPlayerView(config: config)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if decks.isEmpty {
            EmptyStateView(symbol: "rectangle.stack.badge.plus",
                           title: "No decks yet",
                           message: "Create your first deck of flashcards, or load a set of sample decks to explore Recall.",
                           actionTitle: "Create a deck") {
                attemptCreate()
            }
        } else {
            ScrollView {
                VStack(spacing: 16) {
                    summaryCard
                    deckGrid
                }
                .padding(20)
            }
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(totalDueToday)")
                    .font(Theme.rounded(40, .bold))
                    .foregroundStyle(Theme.accent)
                    .monospacedDigit()
                Text(totalDueToday == 1 ? "card due today" : "cards due today")
                    .font(Theme.rounded(17, .semibold))
                    .foregroundStyle(Theme.ink)
            }
            if totalNewAvailable > 0 {
                Text("Plus \(totalNewAvailable) new \(totalNewAvailable == 1 ? "card" : "cards") ready to learn.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
            }
            if totalDueToday > 0 || totalNewAvailable > 0 {
                PrimaryButton(title: "Study all due", systemImage: "play.fill") {
                    studyAllDue()
                }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.good)
                    Text("All caught up — nothing due right now.")
                        .font(Theme.rounded(15, .medium))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .cardSurface()
        .accessibilityElement(children: .combine)
    }

    private var deckGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 14)], spacing: 14) {
            ForEach(decks) { deck in
                Button {
                    openStudy(for: deck)
                } label: {
                    DeckCardView(deck: deck,
                                 dueCount: StudyQueue.dueCount(in: deck.cards),
                                 newCount: min(StudyQueue.newCount(in: deck.cards), settings.boundedNewLimit()))
                }
                .buttonStyle(PressableScale())
                .contextMenu {
                    Button { editingDeck = deck } label: {
                        Label("Edit deck", systemImage: "pencil")
                    }
                    Button { openStudy(for: deck) } label: {
                        Label("Study", systemImage: "play.fill")
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func attemptCreate() {
        if isPro || decks.count < Pro.freeDeckLimit {
            showNewDeck = true
        } else {
            paywallReason = .deckLimit
        }
    }

    private func openStudy(for deck: Deck) {
        let mode = settings.defaultStudyMode
        // Free users can only use flip; downgrade silently to flip for the launch.
        let effectiveMode = (isPro || Pro.modeIsFree(mode)) ? mode : .flip
        let queue = StudyQueue.buildSessionQueue(cards: deck.cards,
                                                 newLimit: settings.boundedNewLimit(),
                                                 reviewLimit: settings.boundedReviewLimit(),
                                                 shuffle: settings.shuffleOrder)
        guard !queue.isEmpty else {
            // Nothing due — offer a quick Cram-like flip over all cards for Pro, else just open empty player.
            studyConfig = StudyConfig(title: deck.name,
                                      mode: effectiveMode,
                                      queue: [],
                                      distractorPool: deck.activeCards,
                                      scopedDeck: deck)
            return
        }
        studyConfig = StudyConfig(title: deck.name,
                                  mode: effectiveMode,
                                  queue: queue,
                                  distractorPool: deck.activeCards,
                                  scopedDeck: deck)
    }

    private func studyAllDue() {
        let allCards = decks.flatMap { $0.cards }
        let mode = settings.defaultStudyMode
        let effectiveMode = (isPro || Pro.modeIsFree(mode)) ? mode : .flip
        let queue = StudyQueue.buildSessionQueue(cards: allCards,
                                                 newLimit: settings.boundedNewLimit() * max(1, decks.count),
                                                 reviewLimit: settings.boundedReviewLimit() * max(1, decks.count),
                                                 shuffle: settings.shuffleOrder)
        studyConfig = StudyConfig(title: "All Decks",
                                  mode: effectiveMode,
                                  queue: queue,
                                  distractorPool: allCards.filter { !$0.isSuspended },
                                  scopedDeck: nil)
    }
}

#Preview {
    DecksScreen()
        .environmentObject(AppSettings())
        .modelContainer(PreviewContainer.shared)
}
