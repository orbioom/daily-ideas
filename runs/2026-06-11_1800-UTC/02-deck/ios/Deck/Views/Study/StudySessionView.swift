import SwiftUI
import SwiftData

struct StudySessionView: View {
    @State var session: StudySession
    let deckName: String
    let deckColor: Color
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var flip = 0.0
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        ZStack {
            DeckTheme.bg.ignoresSafeArea()

            if session.isComplete {
                sessionComplete
            } else {
                VStack(spacing: 0) {
                    headerBar
                        .padding(.horizontal)
                        .padding(.top, 16)

                    Spacer()

                    if let card = session.current {
                        flashCard(card: card)
                            .padding(.horizontal, 24)
                            .offset(x: dragOffset)
                            .gesture(
                                DragGesture()
                                    .onChanged { v in
                                        guard session.isFlipped else { return }
                                        dragOffset = v.translation.width * 0.4
                                    }
                                    .onEnded { v in
                                        guard session.isFlipped else { return }
                                        withAnimation(reduceMotion ? .none : .spring(response: 0.3)) {
                                            dragOffset = 0
                                        }
                                    }
                            )
                    }

                    Spacer()

                    if session.isFlipped {
                        ratingButtons
                            .padding(.horizontal, 24)
                            .padding(.bottom, 48)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        tapToFlipHint
                            .padding(.bottom, 48)
                    }
                }
            }
        }
        .animation(reduceMotion ? .none : .spring(response: 0.35), value: session.isFlipped)
        .animation(reduceMotion ? .none : .spring(response: 0.35), value: session.isComplete)
    }

    @ViewBuilder
    private var headerBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(DeckTheme.subtle)
                    .accessibilityLabel("End session")
            }

            Spacer()

            Text("\(session.currentIndex + 1) / \(session.queue.count)")
                .font(.caption.weight(.medium))
                .foregroundStyle(DeckTheme.subtle)

            Spacer()

            Text(deckName)
                .font(.caption.weight(.medium))
                .foregroundStyle(deckColor)
        }
    }

    @ViewBuilder
    private func flashCard(card: FlashCard) -> some View {
        let displayFront = card.cardType == .cloze ? card.clozeDisplayFront : card.front
        let displayBack  = card.cardType == .cloze ? card.clozeAnswer : card.back

        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(DeckTheme.card)
                .shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: 8)
                .rotation3DEffect(.degrees(flip), axis: (x: 0, y: 1, z: 0))

            if flip < 90 {
                VStack(spacing: 16) {
                    Text("QUESTION")
                        .font(.caption2.weight(.bold))
                        .tracking(2)
                        .foregroundStyle(deckColor)
                    Text(displayFront)
                        .font(.title3)
                        .foregroundStyle(DeckTheme.text)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Spacer()
                }
                .padding(28)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Question: \(displayFront)")
            } else {
                VStack(spacing: 16) {
                    Text("ANSWER")
                        .font(.caption2.weight(.bold))
                        .tracking(2)
                        .foregroundStyle(.green)
                    Text(displayBack.isEmpty ? "—" : displayBack)
                        .font(.title3)
                        .foregroundStyle(DeckTheme.text)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Spacer()
                }
                .padding(28)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Answer: \(displayBack)")
            }
        }
        .frame(height: 300)
        .contentShape(Rectangle())
        .onTapGesture {
            if !session.isFlipped {
                withAnimation(reduceMotion ? .none : .spring(response: 0.5)) {
                    flip = 180
                    session.flip()
                }
            }
        }
        .accessibilityHint(session.isFlipped ? "" : "Double-tap to reveal the answer")
    }

    @ViewBuilder
    private var ratingButtons: some View {
        HStack(spacing: 12) {
            ForEach(ReviewRating.allCases, id: \.rawValue) { rating in
                Button {
                    withAnimation(reduceMotion ? .none : .spring(response: 0.3)) {
                        session.answer(rating: rating, context: ctx)
                        flip = 0
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text(rating.label)
                            .font(.caption.weight(.bold))
                        Text(ratingHint(rating))
                            .font(.caption2)
                            .opacity(0.6)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(DeckTheme.ratingColor(rating).opacity(0.15))
                    .foregroundStyle(DeckTheme.ratingColor(rating))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .accessibilityLabel("\(rating.label): \(ratingHint(rating))")
            }
        }
    }

    private func ratingHint(_ r: ReviewRating) -> String {
        switch r {
        case .again: return "<1d"
        case .hard:  return "~1d"
        case .good:  return "~\(max(1, session.current?.intervalDays ?? 1))d"
        case .easy:  return "~\(max(1, Int(Double(session.current?.intervalDays ?? 1) * 1.5)))d"
        }
    }

    @ViewBuilder
    private var tapToFlipHint: some View {
        VStack(spacing: 8) {
            Image(systemName: "hand.tap")
                .font(.title3)
                .foregroundStyle(DeckTheme.subtle.opacity(0.5))
                .accessibilityHidden(true)
            Text("Tap card to reveal")
                .font(.caption)
                .foregroundStyle(DeckTheme.subtle.opacity(0.6))
        }
    }

    @ViewBuilder
    private var sessionComplete: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(deckColor)
                .accessibilityHidden(true)

            Text("Session Complete!")
                .font(.title2.weight(.bold))
                .foregroundStyle(DeckTheme.text)

            VStack(spacing: 8) {
                HStack {
                    Text("Reviewed"); Spacer(); Text("\(session.reviewedCount)")
                        .foregroundStyle(deckColor)
                }
                Divider()
                HStack {
                    Text("Again"); Spacer(); Text("\(session.againCount)")
                        .foregroundStyle(.orange)
                }
                Divider()
                HStack {
                    Text("Passed"); Spacer(); Text("\(session.reviewedCount - session.againCount)")
                        .foregroundStyle(.green)
                }
            }
            .font(.body)
            .foregroundStyle(DeckTheme.text)
            .padding()
            .background(DeckTheme.card, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 40)

            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
                .tint(deckColor)
                .accessibilityHint("Close and return to deck")
        }
        .padding()
    }
}

struct AllDueStudyView: View {
    let decks: [FlashDeck]
    @State private var session = StudySession()
    @AppStorage("dailyReviewLimit") private var dailyLimit = 20
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let dueCards = decks.flatMap { $0.cards }.filter(\.isDue)
        StudySessionView(
            session: {
                let s = StudySession()
                s.load(cards: dueCards, limit: dailyLimit)
                return s
            }(),
            deckName: "All Decks",
            deckColor: DeckTheme.accent
        )
    }
}
