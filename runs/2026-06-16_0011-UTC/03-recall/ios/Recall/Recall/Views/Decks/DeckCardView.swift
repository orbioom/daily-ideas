import SwiftUI

/// A deck card with a colorSeed gradient header, due/new badges, and a mini progress bar.
struct DeckCardView: View {
    let deck: Deck
    let dueCount: Int
    let newCount: Int

    private var cards: [Card] { deck.activeCards }

    /// Fraction of the deck that is mature (a sense of long-term progress).
    private var maturityFraction: Double {
        let total = cards.count
        guard total > 0 else { return 0 }
        let mature = cards.filter { $0.maturity == .mature || $0.maturity == .young }.count
        return Double(mature) / Double(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            footer
        }
        .background(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    private var header: some View {
        ZStack(alignment: .topLeading) {
            Theme.deckGradient(seed: deck.colorSeed)
                .frame(height: 84)
            VStack(alignment: .leading, spacing: 4) {
                Text(deck.category.uppercased())
                    .font(Theme.rounded(11, .bold))
                    .foregroundStyle(.white.opacity(0.85))
                Text(deck.name)
                    .font(Theme.rounded(20, .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
            }
            .padding(14)
            .shadow(color: .black.opacity(0.18), radius: 3, y: 1)
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                if dueCount > 0 {
                    CountBadge(count: dueCount, label: "due", color: Theme.warn)
                }
                if newCount > 0 {
                    CountBadge(count: newCount, label: "new", color: Theme.accent)
                }
                if dueCount == 0 && newCount == 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Done today")
                    }
                    .font(Theme.rounded(12, .semibold))
                    .foregroundStyle(Theme.good)
                }
                Spacer()
                Text("\(cards.count) cards")
                    .font(Theme.rounded(12, .medium))
                    .foregroundStyle(Theme.inkFaint)
            }
            progressBar
        }
        .padding(14)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.surfaceAlt)
                Capsule()
                    .fill(Theme.deckGradient(seed: deck.colorSeed))
                    .frame(width: max(6, geo.size.width * maturityFraction))
            }
        }
        .frame(height: 6)
        .accessibilityHidden(true)
    }

    private var accessibilitySummary: String {
        var parts = ["\(deck.name), \(deck.category), \(cards.count) cards"]
        if dueCount > 0 { parts.append("\(dueCount) due") }
        if newCount > 0 { parts.append("\(newCount) new") }
        if dueCount == 0 && newCount == 0 { parts.append("done for today") }
        return parts.joined(separator: ", ")
    }
}
