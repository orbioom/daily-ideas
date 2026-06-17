import SwiftUI
import SwiftData

/// The live spread flow: ask → draw → reveal each position → reflect → save.
struct ReadingFlowView: View {
    let spread: SpreadType

    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isPro") private var isPro = false

    @Query private var allReadings: [Reading]

    @State private var question = ""
    @State private var results: [DrawnResult] = []
    @State private var revealed: Set<Int> = []
    @State private var reflection = ""
    @State private var mood: Int? = nil
    @State private var phase: Phase = .ask
    @State private var saved = false

    private enum Phase { case ask, reading }

    private var allRevealed: Bool {
        !results.isEmpty && revealed.count == results.count
    }

    var body: some View {
        ZStack {
            Theme.skyGradient.ignoresSafeArea()
            Starfield(starCount: 70).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    switch phase {
                    case .ask: askSection
                    case .reading: readingSection
                    }
                }
                .padding()
            }
        }
        .navigationTitle(spread.rawValue)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Ask

    private var askSection: some View {
        VStack(spacing: 18) {
            VStack(spacing: 8) {
                Image(systemName: spread.icon)
                    .font(.system(size: 48))
                    .foregroundStyle(Theme.gold)
                    .accessibilityHidden(true)
                Text(spread.blurb)
                    .font(.body).foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)

            VStack(alignment: .leading, spacing: 8) {
                SectionHeading(title: "Your Question", icon: "text.bubble")
                Text("Optional — hold a question or intention in mind.")
                    .font(.callout).foregroundStyle(Theme.inkSoft)
                TextField("What's on your mind?", text: $question, axis: .vertical)
                    .lineLimit(1...3)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: Theme.cornerSmall).fill(Theme.surfaceAlt))
                    .accessibilityLabel("Your question")
            }
            .padding()
            .cardSurface()

            PrimaryButton(title: "Draw \(spread.cardCount) Card\(spread.cardCount == 1 ? "" : "s")",
                          icon: "sparkles") {
                drawCards()
            }
        }
    }

    // MARK: - Reading

    private var readingSection: some View {
        VStack(spacing: 18) {
            if !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("“\(question.trimmingCharacters(in: .whitespacesAndNewlines))”")
                    .font(Theme.serif(18, .medium).italic())
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }

            if !allRevealed {
                Text("Tap each card to reveal it")
                    .font(.callout).foregroundStyle(Theme.inkSoft)
            }

            // Yes/No gets a verdict banner once revealed.
            if spread == .yesNo, allRevealed, let r = results.first {
                yesNoBanner(r)
            }

            ForEach(results) { result in
                positionCard(result)
            }

            if allRevealed {
                reflectAndSave
            }
        }
    }

    private func yesNoBanner(_ r: DrawnResult) -> some View {
        let verdict = YesNoVerdict.from(card: r.card, reversed: r.reversed)
        return HStack(spacing: 12) {
            Image(systemName: verdict.icon)
                .font(.system(size: 30))
                .foregroundStyle(verdict.color)
            VStack(alignment: .leading) {
                Text(verdict.rawValue)
                    .font(Theme.serif(26, .bold))
                    .foregroundStyle(Theme.ink)
                Text("as read from \(r.card.name)\(r.reversed ? ", reversed" : "")")
                    .font(.caption).foregroundStyle(Theme.inkSoft)
            }
            Spacer()
        }
        .padding()
        .cardSurface(fill: verdict.color.opacity(0.12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Answer: \(verdict.rawValue), from \(cardAccessibilityLabel(r.card, reversed: r.reversed))")
    }

    private func positionCard(_ result: DrawnResult) -> some View {
        let isUp = revealed.contains(result.position.index)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(result.position.title)
                    .font(Theme.serif(19, .semibold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text("\(result.position.index + 1)/\(results.count)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.inkFaint)
            }
            Text(result.position.role)
                .font(.callout).foregroundStyle(Theme.inkSoft)

            HStack(alignment: .top, spacing: 14) {
                FlipCardView(card: result.card, reversed: result.reversed,
                             revealed: bindingForReveal(result.position.index),
                             deckTheme: settings.deckTheme) {
                    Haptics.reveal(settings.hapticsEnabled)
                }
                .frame(width: 92)

                if isUp {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Text(result.card.name).font(.subheadline.weight(.bold)).foregroundStyle(Theme.ink)
                            if result.reversed {
                                Text("Rev").font(.caption2.weight(.bold))
                                    .foregroundStyle(Theme.gold)
                                    .padding(.horizontal, 5).padding(.vertical, 2)
                                    .background(Capsule().fill(Theme.goldSoft))
                            }
                        }
                        Text(result.interpretation)
                            .font(.footnote).foregroundStyle(Theme.ink)
                    }
                    .transition(.opacity)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .cardSurface()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(result.position.title): \(result.position.role)")
    }

    private var reflectAndSave: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeading(title: "Reflect & Save", icon: "square.and.pencil")
            TextEditor(text: $reflection)
                .frame(minHeight: 90)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(RoundedRectangle(cornerRadius: Theme.cornerSmall).fill(Theme.surfaceAlt))
                .accessibilityLabel("Reflection on this reading")

            Text("Mood (optional)")
                .font(.subheadline.weight(.semibold)).foregroundStyle(Theme.inkSoft)
            MoodPicker(mood: $mood)

            if saved {
                Label("Saved to your journal", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.good)
            }

            HStack(spacing: 12) {
                Button {
                    redraw()
                } label: {
                    Label("Draw again", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity).padding(.vertical, 13)
                        .background(Capsule().fill(Theme.surfaceAlt))
                        .foregroundStyle(Theme.ink)
                }
                Button {
                    saveReading()
                } label: {
                    Label(saved ? "Saved" : "Save", systemImage: "tray.and.arrow.down")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity).padding(.vertical, 13)
                        .background(Capsule().fill(saved ? Theme.good.opacity(0.5) : Theme.accent))
                        .foregroundStyle(.white)
                }
                .disabled(saved)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .cardSurface()
    }

    private func bindingForReveal(_ index: Int) -> Binding<Bool> {
        Binding(
            get: { revealed.contains(index) },
            set: { newValue in
                if newValue { revealed.insert(index) }
                else { revealed.remove(index) }
            }
        )
    }

    // MARK: - Actions

    private func drawCards() {
        let draws = ShuffleEngine.drawSpread(spread, reversalChance: settings.effectiveReversalChance)
        var built: [DrawnResult] = []
        for (i, pos) in spread.positions.enumerated() {
            guard let pair = draws[safe: i], let card = Deck.card(id: pair.cardId) else { continue }
            built.append(DrawnResult(position: pos, card: card, reversed: pair.reversed))
        }
        results = built
        revealed = []
        saved = false
        Haptics.tap(settings.hapticsEnabled)
        withAnimation(.easeInOut) { phase = .reading }
    }

    private func redraw() {
        reflection = ""
        mood = nil
        drawCards()
    }

    private func saveReading() {
        // Free journal cap (daily draws excluded).
        if !isPro && allReadings.count >= Pro.freeReadingLimit {
            // Politely keep it usable: overwrite the oldest rather than block, so nothing is a dead end.
            if let oldest = allReadings.sorted(by: { $0.date < $1.date }).first {
                context.delete(oldest)
            }
        }
        let reading = Reading(date: .now, spreadType: spread,
                              question: question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : question,
                              reflection: reflection, mood: mood)
        for result in results {
            let dc = DrawnCard(cardId: result.card.id,
                               positionIndex: result.position.index,
                               reversed: result.reversed)
            dc.reading = reading
            reading.cards.append(dc)
        }
        context.insert(reading)
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        withAnimation { saved = true }
    }
}
