import SwiftUI
import SwiftData

/// Study tab: pick a deck and a mode, then launch the player. Cram & non-flip modes are Pro.
struct StudyHomeScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @Query(sort: \Deck.createdDate, order: .reverse) private var allDecks: [Deck]

    @State private var selectedDeckID: UUID?
    @State private var mode: ReviewMode = .flip
    @State private var studyConfig: StudyConfig?
    @State private var paywallReason: PaywallReason?

    private var decks: [Deck] { allDecks.filter { !$0.isArchived } }

    private var selectedDeck: Deck? {
        if let id = selectedDeckID { return decks.first { $0.id == id } }
        return decks.first
    }

    private var dueInSelected: Int {
        guard let d = selectedDeck else { return 0 }
        return StudyQueue.dueCount(in: d.cards)
    }

    private var newInSelected: Int {
        guard let d = selectedDeck else { return 0 }
        return min(StudyQueue.newCount(in: d.cards), settings.boundedNewLimit())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Study")
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
            .fullScreenCover(item: $studyConfig) { StudyPlayerView(config: $0) }
            .onAppear {
                if selectedDeckID == nil { selectedDeckID = decks.first?.id }
                mode = settings.defaultStudyMode
                if !isPro && !Pro.modeIsFree(mode) { mode = .flip }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if decks.isEmpty {
            EmptyStateView(symbol: "play.slash",
                           title: "No decks to study",
                           message: "Create a deck on the Decks tab (or load sample data in Settings) and your study sessions will start here.")
        } else {
            ScrollView {
                VStack(spacing: 18) {
                    deckPicker
                    modePicker
                    startCard
                }
                .padding(20)
            }
        }
    }

    private var deckPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Deck", systemImage: "rectangle.stack")
            Menu {
                ForEach(decks) { deck in
                    Button {
                        selectedDeckID = deck.id
                        Haptics.selection(enabled: settings.hapticsEnabled)
                    } label: {
                        Label(deck.name, systemImage: deck.id == selectedDeck?.id ? "checkmark" : "rectangle.stack")
                    }
                }
            } label: {
                HStack {
                    Circle().fill(Theme.deckGradient(seed: selectedDeck?.colorSeed ?? 0)).frame(width: 22, height: 22)
                    Text(selectedDeck?.name ?? "Select a deck")
                        .font(Theme.rounded(16, .semibold))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.inkFaint)
                }
                .padding(14)
                .cardSurface()
            }
            .accessibilityLabel("Selected deck: \(selectedDeck?.name ?? "none")")

            HStack(spacing: 8) {
                CountBadge(count: dueInSelected, label: "due", color: Theme.warn)
                CountBadge(count: newInSelected, label: "new", color: Theme.accent)
            }
        }
    }

    private var modePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Mode", systemImage: "slider.horizontal.3")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(ReviewMode.allCases) { m in
                    modeTile(m)
                }
            }
        }
    }

    private func modeTile(_ m: ReviewMode) -> some View {
        let locked = !isPro && !Pro.modeIsFree(m)
        let selected = mode == m
        return Button {
            if locked {
                paywallReason = .studyMode
            } else {
                mode = m
                Haptics.selection(enabled: settings.hapticsEnabled)
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: m.systemImage)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(selected ? .white : Theme.accent)
                    Spacer()
                    if locked { ProLockChip() }
                    else if selected {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.white)
                    }
                }
                Text(m.display)
                    .font(Theme.rounded(15, .bold))
                    .foregroundStyle(selected ? .white : Theme.ink)
                Text(m.caption)
                    .font(Theme.rounded(11))
                    .foregroundStyle(selected ? .white.opacity(0.9) : Theme.inkSoft)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                    .fill(selected ? AnyShapeStyle(Theme.heroGradient) : AnyShapeStyle(Theme.surface))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                    .strokeBorder(Theme.hairline, lineWidth: selected ? 0 : 1)
            )
        }
        .buttonStyle(PressableScale())
        .accessibilityLabel("\(m.display) mode\(locked ? ", Pro feature, locked" : "")\(selected ? ", selected" : "")")
    }

    private var startCard: some View {
        VStack(spacing: 12) {
            let willStudy = sessionCount
            if willStudy == 0 && mode != .cram {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.good)
                    Text("Nothing due in this deck — switch to Cram to drill it anyway.")
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                Text(mode == .cram
                     ? "Cram drills all \(selectedDeck?.activeCards.count ?? 0) cards without touching their schedule."
                     : "This session: \(willStudy) \(willStudy == 1 ? "card" : "cards").")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
            }
            PrimaryButton(title: "Start studying", systemImage: "play.fill") { start() }
                .disabled(selectedDeck == nil)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .cardSurface()
    }

    private var sessionCount: Int {
        guard let deck = selectedDeck else { return 0 }
        if mode == .cram { return deck.activeCards.count }
        return StudyQueue.buildSessionQueue(cards: deck.cards,
                                            newLimit: settings.boundedNewLimit(),
                                            reviewLimit: settings.boundedReviewLimit(),
                                            shuffle: false).count
    }

    private func start() {
        guard let deck = selectedDeck else { return }
        // Re-guard Pro on the chosen mode in case state changed.
        let effectiveMode = (isPro || Pro.modeIsFree(mode)) ? mode : .flip
        let queue: [Card]
        if effectiveMode == .cram {
            queue = StudyQueue.buildCramQueue(cards: deck.cards, shuffle: settings.shuffleOrder)
        } else {
            queue = StudyQueue.buildSessionQueue(cards: deck.cards,
                                                 newLimit: settings.boundedNewLimit(),
                                                 reviewLimit: settings.boundedReviewLimit(),
                                                 shuffle: settings.shuffleOrder)
        }
        studyConfig = StudyConfig(title: deck.name,
                                  mode: effectiveMode,
                                  queue: queue,
                                  distractorPool: deck.activeCards,
                                  scopedDeck: deck)
    }
}

#Preview {
    StudyHomeScreen()
        .environmentObject(AppSettings())
        .modelContainer(PreviewContainer.shared)
}
