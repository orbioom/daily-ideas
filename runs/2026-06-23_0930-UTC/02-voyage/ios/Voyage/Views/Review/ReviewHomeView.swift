import SwiftUI
import SwiftData

/// Review hub: shows each deck's due count and lets the user start a session.
struct ReviewHomeView: View {
    @Query(sort: \Deck.sortIndex) private var decks: [Deck]
    @State private var activeDeck: Deck?

    private var totalDue: Int {
        decks.reduce(0) { $0 + DeckProgress.make(phrases: $1.phrases).dueCount }
    }

    private var totalNew: Int {
        decks.reduce(0) { $0 + DeckProgress.make(phrases: $1.phrases).newCount }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                content
            }
            .navigationTitle("Review")
            .sheet(item: $activeDeck) { deck in
                ReviewSessionView(deck: deck)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if decks.isEmpty {
            EmptyStateView(
                symbol: "brain.head.profile",
                title: "Nothing to review",
                message: "Add a deck and study phrases to build your review queue."
            )
        } else {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    summaryHeader
                    ForEach(decks) { deck in
                        ReviewDeckRow(deck: deck) { activeDeck = deck }
                    }
                }
                .padding(Theme.Spacing.lg)
            }
        }
    }

    private var summaryHeader: some View {
        VStack(spacing: Theme.Spacing.md) {
            Text(totalDue > 0 ? "\(totalDue)" : "0")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(totalDue == 1 ? "phrase due across all decks" : "phrases due across all decks")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
            if totalDue == 0 {
                Text(totalNew > 0 ? "You're caught up. \(totalNew) new phrases waiting." : "All caught up. Beautiful work.")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.xl)
        .background(Theme.brandGradient, in: RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(totalDue) phrases due across all decks")
    }
}

private struct ReviewDeckRow: View {
    let deck: Deck
    let onStudy: () -> Void

    private var progress: DeckProgress { DeckProgress.make(phrases: deck.phrases) }

    var body: some View {
        let p = progress
        HStack(spacing: Theme.Spacing.lg) {
            Text(deck.flag).font(.system(size: 36)).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(deck.name).font(.headline).foregroundStyle(Theme.textPrimary)
                Text(p.dueCount > 0 ? "\(p.dueCount) due · \(p.newCount) new" : "\(p.newCount) new to learn")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Button(action: onStudy) {
                Text(p.dueCount > 0 || p.newCount > 0 ? "Study" : "Review")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(Capsule().fill(Theme.brand))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Study \(deck.name)")
        }
        .cardSurface()
    }
}

#Preview {
    if let container = PersistenceController.previewContainer() {
        ReviewHomeView().modelContainer(container)
    }
}
