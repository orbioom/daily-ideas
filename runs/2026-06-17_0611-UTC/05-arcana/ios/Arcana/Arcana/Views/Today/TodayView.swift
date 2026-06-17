import SwiftUI
import SwiftData

struct TodayView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var context
    @Query(sort: \DailyDraw.date, order: .reverse) private var draws: [DailyDraw]

    @State private var revealed = false
    @State private var reflectionText = ""
    @State private var saveState: SaveState = .idle
    @State private var didLoad = false

    private enum SaveState { case idle, saving, saved }

    private var todayKey: String { Date().dayKey }

    /// The deterministic card+orientation for today.
    private var todays: (cardId: Int, reversed: Bool) {
        ShuffleEngine.dailyCard(for: .now, reversalChance: settings.effectiveReversalChance)
    }

    private var todayCard: TarotCard? { Deck.card(id: todays.cardId) }

    private var todaysDraw: DailyDraw? {
        draws.first { $0.dayKey == todayKey }
    }

    /// "This day last…" — past daily draws on the same calendar day in earlier months/years.
    private var historyPeek: [DailyDraw] {
        let cal = Calendar.current
        let today = cal.dateComponents([.day], from: .now).day
        return draws.filter {
            $0.dayKey != todayKey && cal.dateComponents([.day], from: $0.date).day == today
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.skyGradient.ignoresSafeArea()
                Starfield(starCount: 80).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 22) {
                        header
                        if let card = todayCard {
                            cardSection(card)
                            if revealed {
                                meaningSection(card)
                                reflectionSection
                            }
                        } else {
                            EmptyStateView(icon: "questionmark.circle",
                                           title: "Card unavailable",
                                           message: "Today's card couldn't be drawn. Please relaunch Arcana.")
                                .cardSurface()
                        }
                        if !historyPeek.isEmpty {
                            historySection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: loadForToday)
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text(Date.now, format: .dateTime.weekday(.wide).month(.wide).day())
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.inkSoft)
            Text("Your Card of the Day")
                .font(Theme.serif(26, .bold))
                .foregroundStyle(Theme.ink)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private func cardSection(_ card: TarotCard) -> some View {
        VStack(spacing: 14) {
            FlipCardView(card: card, reversed: todays.reversed, revealed: $revealed,
                         deckTheme: settings.deckTheme) {
                Haptics.reveal(settings.hapticsEnabled)
                upsertTodayDraw()
            }
            .frame(maxWidth: 240)

            if !revealed {
                Text("Tap the card to reveal today's draw")
                    .font(.callout)
                    .foregroundStyle(Theme.inkSoft)
            } else {
                HStack(spacing: 8) {
                    Text(card.name).font(Theme.serif(22, .semibold))
                    if todays.reversed {
                        Text("Reversed")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Theme.gold)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Capsule().fill(Theme.goldSoft))
                    }
                }
                .foregroundStyle(Theme.ink)
            }
        }
    }

    private func meaningSection(_ card: TarotCard) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeading(title: "Meaning", icon: "text.book.closed")
            Text(todays.reversed ? card.reversed : card.upright)
                .font(.body)
                .foregroundStyle(Theme.ink)
            KeywordRow(keywords: card.keywords)
            NavigationLink {
                CardDetailView(card: card)
            } label: {
                Label("Read the full card", systemImage: "arrow.right.circle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.accentDeep)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .cardSurface()
    }

    private var reflectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading(title: "Reflection", icon: "square.and.pencil")
            Text("What does this card stir in you today?")
                .font(.callout).foregroundStyle(Theme.inkSoft)
            TextEditor(text: $reflectionText)
                .frame(minHeight: 96)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(RoundedRectangle(cornerRadius: Theme.cornerSmall).fill(Theme.surfaceAlt))
                .accessibilityLabel("Reflection note for today's card")
            HStack {
                if saveState == .saved {
                    Label("Saved", systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.good)
                }
                Spacer()
                Button {
                    saveReflection()
                } label: {
                    Text(saveState == .saving ? "Saving…" : "Save reflection")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16).padding(.vertical, 9)
                        .background(Capsule().fill(Theme.accent))
                }
                .disabled(saveState == .saving)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .cardSurface()
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading(title: "This day, before", icon: "clock.arrow.circlepath")
            ForEach(historyPeek) { draw in
                if let card = draw.card {
                    HStack(spacing: 12) {
                        CardArtView(card: card, reversed: draw.reversed, showName: false)
                            .frame(width: 44)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(card.name).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.ink)
                            Text(draw.date, format: .dateTime.month().day().year())
                                .font(.caption).foregroundStyle(Theme.inkSoft)
                        }
                        Spacer()
                        if draw.reversed {
                            Image(systemName: "arrow.uturn.down").foregroundStyle(Theme.gold)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(cardAccessibilityLabel(card, reversed: draw.reversed)) on \(draw.date.formatted(.dateTime.month().day().year()))")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .cardSurface()
    }

    // MARK: - Data

    private func loadForToday() {
        guard !didLoad else { return }
        didLoad = true
        if let existing = todaysDraw {
            revealed = true
            reflectionText = existing.reflection
            saveState = existing.reflection.isEmpty ? .idle : .saved
        }
    }

    /// Persist (or confirm) today's draw the first time it's revealed.
    private func upsertTodayDraw() {
        if todaysDraw == nil {
            let draw = DailyDraw(dayKey: todayKey, date: .now,
                                 cardId: todays.cardId, reversed: todays.reversed)
            context.insert(draw)
            try? context.save()
        }
    }

    private func saveReflection() {
        saveState = .saving
        upsertTodayDraw()
        if let existing = todaysDraw {
            existing.reflection = reflectionText
            try? context.save()
        }
        Haptics.success(settings.hapticsEnabled)
        saveState = .saved
    }
}
