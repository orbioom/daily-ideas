import SwiftUI
import SwiftData

/// Lists all language decks with mastery progress. Tapping opens the detail.
struct DecksView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Deck.sortIndex) private var decks: [Deck]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                content
            }
            .navigationTitle("Decks")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        AddDeckView()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add a deck")
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if decks.isEmpty {
            EmptyStateView(
                symbol: "rectangle.stack.badge.plus",
                title: "No decks yet",
                message: "Add a language deck to start building your travel phrasebook.",
                actionTitle: "Add a deck",
                action: {}
            )
            // Note: action handled via the toolbar link; this empty state is a
            // safety net for a freshly cleared store.
        } else {
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.lg) {
                    ForEach(decks) { deck in
                        NavigationLink {
                            DeckDetailView(deck: deck)
                        } label: {
                            DeckCard(deck: deck)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(Theme.Spacing.lg)
            }
        }
    }
}

/// Visual card summarising one deck.
private struct DeckCard: View {
    let deck: Deck

    private var progress: DeckProgress {
        DeckProgress.make(phrases: deck.phrases)
    }

    var body: some View {
        let p = progress
        HStack(spacing: Theme.Spacing.lg) {
            Text(deck.flag)
                .font(.system(size: 44))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(deck.name)
                    .font(.title3.bold())
                    .foregroundStyle(Theme.textPrimary)
                Text("\(deck.endonym) · \(p.total) phrases")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                HStack(spacing: Theme.Spacing.sm) {
                    if p.dueCount > 0 {
                        Label("\(p.dueCount) due", systemImage: "clock.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.warn)
                    } else {
                        Label("Up to date", systemImage: "checkmark.circle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.success)
                    }
                }
                .padding(.top, 2)
            }

            Spacer()

            ProgressRing(
                fraction: p.masteryFraction,
                lineWidth: 7,
                label: "\(Int(p.masteryFraction * 100))%"
            )
            .frame(width: 56, height: 56)
        }
        .cardSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(deck.name), \(p.total) phrases, \(Int(p.masteryFraction * 100)) percent mastered, \(p.dueCount) due")
    }
}

#Preview {
    if let container = PersistenceController.previewContainer() {
        DecksView().modelContainer(container)
    }
}
