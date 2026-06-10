import SwiftUI
import SwiftData

struct DeckDetailView: View {
    @Bindable var deck: Deck
    @Environment(\.modelContext) private var context
    @AppStorage("maxSessionCards") private var maxSessionCards = 15
    @AppStorage("typedAnswers") private var typedAnswers = true
    @AppStorage("requireArticle") private var requireArticle = false

    @State private var session: StudySession?
    @State private var search = ""
    @State private var editorCard: Card?
    @State private var showNewCard = false
    @State private var confirmReset = false

    var body: some View {
        ZStack {
            Brand.pageBackground
            ScrollView {
                VStack(spacing: 14) {
                    header
                    boxBars
                    studyButton
                    cardList
                }
                .padding(16)
            }
        }
        .navigationTitle(deck.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showNewCard = true
                    } label: {
                        Label("Add card", systemImage: "plus")
                    }
                    Button(role: .destructive) {
                        confirmReset = true
                    } label: {
                        Label("Reset progress", systemImage: "arrow.counterclockwise")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Deck options")
            }
        }
        .fullScreenCover(item: $session) { s in
            StudyView(session: s)
        }
        .sheet(item: $editorCard) { card in
            CardEditorView(deck: deck, card: card)
        }
        .sheet(isPresented: $showNewCard) {
            CardEditorView(deck: deck, card: nil)
        }
        .alert("Reset all progress?", isPresented: $confirmReset) {
            Button("Reset", role: .destructive) {
                for card in deck.cards {
                    card.box = 1
                    card.dueDate = .now
                    card.reviews = 0
                    card.lapses = 0
                    card.lastReviewed = nil
                }
                Haptics.warning()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Every card returns to box 1 and becomes due now. The cards themselves are kept.")
        }
    }

    private var due: [Card] { deck.dueCards() }

    private var header: some View {
        HStack(spacing: 14) {
            stat("\(due.count)", "due now")
            stat("\(deck.masteredCount)", "mastered")
            stat("\(deck.cards.count)", "cards")
        }
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Brand.mono(20, weight: .semibold))
                .foregroundStyle(Brand.text)
            Text(label)
                .font(.caption)
                .foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity)
        .glassCard(padding: 12)
        .accessibilityElement(children: .combine)
    }

    private var boxBars: some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(text: "Leitner boxes")
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(1...LeitnerEngine.boxCount, id: \.self) { box in
                    let count = deck.cards.filter { $0.box == box }.count
                    let maxCount = max(1, (1...LeitnerEngine.boxCount).map { b in deck.cards.filter { $0.box == b }.count }.max() ?? 1)
                    VStack(spacing: 4) {
                        Text("\(count)")
                            .font(Brand.mono(11))
                            .foregroundStyle(Brand.text3)
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(box == LeitnerEngine.boxCount ? AnyShapeStyle(Brand.live.gradient) : AnyShapeStyle(Brand.inkGradient))
                            .frame(height: max(6, 64 * CGFloat(count) / CGFloat(maxCount)))
                        Text("B\(box)")
                            .font(Brand.mono(10))
                            .foregroundStyle(Brand.text3)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Box \(box): \(count) cards")
                }
            }
            Text("Box 5 words are mastered — they come back every two weeks to stay fresh.")
                .font(.caption)
                .foregroundStyle(Brand.text3)
        }
        .glassCard()
    }

    private var studyButton: some View {
        VStack(spacing: 8) {
            Button {
                guard !deck.cards.isEmpty else { return }
                let cards = due.isEmpty
                    ? Array(deck.cards.sorted { $0.dueDate < $1.dueDate }.prefix(maxSessionCards))
                    : due
                session = StudySession(deck: deck, dueCards: cards,
                                       maxCards: maxSessionCards,
                                       typedEnabled: typedAnswers,
                                       requireArticle: requireArticle)
                Haptics.tap()
            } label: {
                Label(due.isEmpty ? "Early practice" : "Study \(min(due.count, maxSessionCards)) due cards",
                      systemImage: "play.fill")
            }
            .buttonStyle(InkButtonStyle())
            .disabled(deck.cards.isEmpty)
            if due.isEmpty && !deck.cards.isEmpty {
                Text("Nothing is due — early practice reviews the words coming up next.")
                    .font(.caption)
                    .foregroundStyle(Brand.text3)
            }
        }
    }

    @ViewBuilder
    private var cardList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Cards")
            TextField("Search cards", text: $search)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
            if filteredCards.isEmpty {
                Text(search.isEmpty
                     ? "No cards yet — add the first one from the menu."
                     : "No cards match “\(search)”.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text3)
                    .padding(.vertical, 16)
            }
            ForEach(filteredCards) { card in
                Button {
                    editorCard = card
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(card.front)
                                .font(.body.weight(.medium))
                                .foregroundStyle(Brand.text)
                            Text(card.back)
                                .font(.subheadline)
                                .foregroundStyle(Brand.text2)
                        }
                        Spacer()
                        Text("B\(card.box)")
                            .font(Brand.mono(12, weight: .semibold))
                            .foregroundStyle(card.box >= LeitnerEngine.boxCount ? Brand.live : Brand.text3)
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(card.front), \(card.back), box \(card.box)")
                .accessibilityHint("Opens the card editor")
                Divider()
            }
        }
        .glassCard()
    }

    private var filteredCards: [Card] {
        let sorted = deck.cards.sorted { $0.front.localizedCaseInsensitiveCompare($1.front) == .orderedAscending }
        let q = search.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return sorted }
        return sorted.filter {
            $0.front.localizedCaseInsensitiveContains(q) || $0.back.localizedCaseInsensitiveContains(q)
        }
    }
}
