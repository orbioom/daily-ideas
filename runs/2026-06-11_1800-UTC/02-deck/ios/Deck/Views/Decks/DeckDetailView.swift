import SwiftUI
import SwiftData

struct DeckDetailView: View {
    @Bindable var deck: FlashDeck
    @Environment(\.modelContext) private var ctx
    @State private var showAddCard = false
    @State private var studySession: StudySession? = nil
    @State private var editCard: FlashCard? = nil
    @State private var showStudy = false
    @AppStorage("dailyReviewLimit") private var dailyLimit = 20

    private var sortedCards: [FlashCard] {
        deck.cards.sorted { $0.createdAt < $1.createdAt }
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    DeckStat(value: "\(deck.cards.count)", label: "Cards", color: DeckTheme.colorFromHex(deck.colorHex))
                    DeckStat(value: "\(deck.dueCount)", label: "Due", color: deck.dueCount > 0 ? .orange : DeckTheme.subtle)
                    DeckStat(value: "\(Int(deck.retentionRate * 100))%", label: "Retention", color: .green)
                }
                .padding(.vertical, 8)

                if deck.dueCount > 0 {
                    Button {
                        let session = StudySession()
                        session.load(cards: deck.cards, limit: dailyLimit)
                        studySession = session
                        showStudy = true
                    } label: {
                        Label("Study \(deck.dueCount) Due Cards", systemImage: "brain.filled.head.profile")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(DeckTheme.colorFromHex(deck.colorHex))
                    .accessibilityHint("Start a study session for cards due today")
                } else {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("All caught up!")
                            .foregroundStyle(DeckTheme.subtle)
                    }
                    .font(.subheadline)
                    .accessibilityLabel("All cards reviewed for today")
                }
            }

            if sortedCards.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "plus.rectangle.on.rectangle")
                            .font(.system(size: 40))
                            .foregroundStyle(DeckTheme.subtle.opacity(0.5))
                            .accessibilityHidden(true)
                        Text("No cards yet")
                            .foregroundStyle(DeckTheme.subtle)
                        Button("Add First Card") { showAddCard = true }
                            .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            } else {
                Section("Cards (\(sortedCards.count))") {
                    ForEach(sortedCards) { card in
                        CardRowView(card: card)
                            .contentShape(Rectangle())
                            .onTapGesture { editCard = card }
                    }
                    .onDelete { offsets in
                        for idx in offsets { ctx.delete(sortedCards[idx]) }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(DeckTheme.bg)
        .navigationTitle(deck.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAddCard = true } label: {
                    Image(systemName: "plus")
                        .accessibilityLabel("Add card")
                }
            }
        }
        .sheet(isPresented: $showAddCard) {
            CardEditorView(deck: deck, card: nil)
        }
        .sheet(item: $editCard) { card in
            CardEditorView(deck: deck, card: card)
        }
        .fullScreenCover(isPresented: $showStudy) {
            if let session = studySession {
                StudySessionView(session: session, deckName: deck.name, deckColor: DeckTheme.colorFromHex(deck.colorHex))
            }
        }
    }
}

private struct DeckStat: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(DeckTheme.subtle)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

private struct CardRowView: View {
    let card: FlashCard

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(card.cardType == .cloze ? card.clozeDisplayFront : card.front)
                .font(.body)
                .foregroundStyle(DeckTheme.text)
                .lineLimit(2)

            HStack(spacing: 8) {
                Text(card.cardType.rawValue)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(DeckTheme.accent.opacity(0.15), in: Capsule())
                    .foregroundStyle(DeckTheme.accent)

                if card.isDue {
                    Text("Due")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                } else {
                    Text("In \(card.intervalDays)d")
                        .font(.caption2)
                        .foregroundStyle(DeckTheme.subtle)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Card: \(card.front), \(card.isDue ? "due" : "next review in \(card.intervalDays) days")")
    }
}
