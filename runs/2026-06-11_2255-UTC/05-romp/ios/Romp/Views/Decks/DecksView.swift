import SwiftUI
import SwiftData

struct DecksView: View {
    @Query(sort: \CustomDeck.createdAt) private var customDecks: [CustomDeck]
    @Query private var results: [GameResult]
    @AppStorage("roundSeconds") private var roundSeconds = 60

    @State private var selectedDeck: PlayableDeck?

    private var allDecks: [PlayableDeck] {
        DeckLibrary.decks + customDecks.map {
            PlayableDeck(id: "custom-\($0.persistentModelID.hashValue)",
                         name: $0.name, emoji: $0.emoji,
                         blurb: "\($0.words.count) custom cards",
                         words: $0.words, isCustom: true)
        }
    }

    private let columns = [GridItem(.adaptive(minimum: 160), spacing: 14)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    roundLengthPicker
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(Array(allDecks.enumerated()), id: \.element.id) { index, deck in
                            DeckCardView(
                                deck: deck,
                                color: Theme.deckColors[index % Theme.deckColors.count],
                                bestScore: bestScore(for: deck.name)
                            ) {
                                if deck.words.count >= 5 {
                                    Haptics.tap()
                                    selectedDeck = deck
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(Theme.bgPrimary)
            .navigationTitle("Romp")
            .fullScreenCover(item: $selectedDeck) { deck in
                GameView(deck: deck, roundSeconds: roundSeconds)
            }
        }
    }

    private var roundLengthPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Round length")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
            Picker("Round length", selection: $roundSeconds) {
                Text("30s").tag(30)
                Text("60s").tag(60)
                Text("90s").tag(90)
                Text("120s").tag(120)
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Round length in seconds")
        }
    }

    private func bestScore(for deckName: String) -> Int? {
        let scores = results.filter { $0.deckName == deckName }.map(\.score)
        return scores.max()
    }
}

struct DeckCardView: View {
    let deck: PlayableDeck
    let color: Color
    let bestScore: Int?
    let onPlay: () -> Void

    var body: some View {
        Button(action: onPlay) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(deck.emoji)
                        .font(.system(size: 36))
                        .accessibilityHidden(true)
                    Spacer()
                    if let bestScore {
                        Label("\(bestScore)", systemImage: "trophy.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(.white.opacity(0.2), in: Capsule())
                            .accessibilityLabel("Best score \(bestScore)")
                    }
                }
                Spacer(minLength: 4)
                Text(deck.name)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                Text(deck.blurb)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                if deck.words.count < 5 {
                    Label("Needs 5+ cards", systemImage: "exclamationmark.circle")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)
            .background(
                LinearGradient(colors: [color, color.opacity(0.75)],
                               startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(deck.name), \(deck.words.count) cards")
        .accessibilityHint(deck.words.count >= 5 ? "Starts a round" : "Add at least 5 cards to play this deck")
    }
}
