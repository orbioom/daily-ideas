import SwiftUI
import SwiftData

/// Draws cards for the chosen spread and reveals each position one at a time,
/// with a tasteful flip/fade that respects Reduce Motion. Saves a Reading.
struct DrawRevealView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(PrefKey.allowReversed) private var allowReversed = true
    @AppStorage(PrefKey.deckBack) private var deckBackRaw = DeckBack.midnight.rawValue

    let spread: Spread
    let question: String

    @State private var drawn: [(cardID: Int, reversed: Bool)] = []
    @State private var revealedCount = 0
    @State private var didSave = false

    private var deckBack: DeckBack { DeckBack(rawValue: deckBackRaw) ?? .midnight }
    private var allRevealed: Bool { revealedCount >= spread.cardCount && spread.cardCount > 0 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 4) {
                            Eyebrow(text: "Your question")
                            Text(question)
                                .font(.body.weight(.medium))
                                .foregroundStyle(Brand.text)
                        }
                    }
                }

                ForEach(Array(spread.positions.enumerated()), id: \.element.id) { index, position in
                    positionCard(index: index, position: position)
                }

                if !allRevealed {
                    Button {
                        revealNext()
                    } label: {
                        Label(revealedCount == 0 ? "Reveal first card" : "Reveal next card",
                              systemImage: "hand.tap.fill")
                    }
                    .buttonStyle(InkButtonStyle())
                } else if didSave {
                    savedState
                } else {
                    Button {
                        save()
                    } label: {
                        Label("Save reading", systemImage: "tray.and.arrow.down.fill")
                    }
                    .buttonStyle(InkButtonStyle())
                }
            }
            .padding(20)
        }
        .background(Brand.pageBackground)
        .navigationTitle(spread.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if drawn.isEmpty {
                drawn = ArcanaEngine.draw(spread: spread, allowReversed: allowReversed)
            }
        }
    }

    @ViewBuilder
    private func positionCard(index: Int, position: SpreadPosition) -> some View {
        let isRevealed = index < revealedCount
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("\(index + 1)")
                    .font(Brand.mono(13, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(Brand.magic, in: Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 1) {
                    Text(position.title)
                        .font(.headline)
                        .foregroundStyle(Brand.text)
                    Text(position.prompt)
                        .font(.footnote)
                        .foregroundStyle(Brand.text3)
                }
            }

            if isRevealed, index < drawn.count, let card = TarotDeck.card(id: drawn[index].cardID) {
                let reversed = drawn[index].reversed
                VStack(alignment: .leading, spacing: 12) {
                    CardFace(card: card, reversed: reversed, size: .medium)
                        .transition(reduceMotion ? .opacity : .asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.92)),
                            removal: .opacity))
                    KeywordChips(keywords: card.keywords(reversed: reversed))
                    Text(card.meaning(reversed: reversed))
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                CardBack(deckBack: deckBack, height: 200)
            }
        }
        .glassCard()
    }

    private var savedState: some View {
        GlassCard {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Brand.magic)
                    .accessibilityHidden(true)
                Text("Reading saved")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Brand.text)
                Text("Find it anytime in your Journal.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
                Button("Done") {
                    Haptics.tap()
                    dismiss()
                }
                .buttonStyle(GlassButtonStyle())
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
        }
    }

    private func revealNext() {
        guard revealedCount < spread.cardCount else { return }
        Haptics.tap()
        withAnimation(reduceMotion ? .default : Brand.ease(0.5)) {
            revealedCount += 1
        }
    }

    private func save() {
        Haptics.success()
        let reading = Reading(date: .now,
                              spreadName: spread.name,
                              question: question.trimmingCharacters(in: .whitespacesAndNewlines))
        context.insert(reading)
        for (index, position) in spread.positions.enumerated() where index < drawn.count {
            let d = DrawnCard(positionIndex: index,
                              positionTitle: position.title,
                              cardID: drawn[index].cardID,
                              isReversed: drawn[index].reversed)
            d.reading = reading
            context.insert(d)
        }
        try? context.save()
        withAnimation(Brand.ease()) { didSave = true }
    }
}
