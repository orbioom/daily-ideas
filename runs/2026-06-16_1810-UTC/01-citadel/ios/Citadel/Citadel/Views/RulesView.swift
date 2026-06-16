import SwiftUI

/// How to play FreeCell, nicely typeset, plus a few strategy tips.
struct RulesView: View {
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                theme.feltGradient(for: colorScheme).ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        intro

                        section(
                            title: "The goal",
                            symbol: "trophy.fill",
                            body: "Move all 52 cards to the four foundations, building each suit up from Ace to King. Solve every foundation and you win."
                        )

                        section(
                            title: "The layout",
                            symbol: "rectangle.3.group.fill",
                            body: "Eight columns hold every card face-up. Above them sit four free cells (each holds one card) and four foundations (one per suit)."
                        )

                        rulesList

                        tipsCard
                    }
                    .padding(18)
                }
            }
            .navigationTitle("How to Play")
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("FreeCell")
                .font(.system(.largeTitle, design: .serif).weight(.bold))
                .foregroundStyle(Theme.feltText(for: colorScheme))
            Text("A game of pure skill. Nearly every deal can be won — no luck required, just a clear plan.")
                .font(.body)
                .foregroundStyle(Theme.feltTextSecondary(for: colorScheme))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func section(title: String, symbol: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbol)
                .font(.headline)
                .foregroundStyle(Theme.feltText(for: colorScheme))
            Text(body)
                .font(.body)
                .foregroundStyle(Theme.feltTextSecondary(for: colorScheme))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.slotFill(for: colorScheme))
        )
    }

    private let moves: [(String, String)] = [
        ("Move within columns", "Place a card onto one of the opposite color and one rank higher — a red 6 onto a black 7."),
        ("Use the free cells", "Park any single card in a free cell to free up a column. Bring it back whenever it fits."),
        ("Build the foundations", "Send Aces up first, then 2s, 3s, and so on, each on its own suit."),
        ("Move sequences", "With free cells and empty columns, you can move an ordered run of cards at once — Citadel does the shuffling for you."),
        ("Empty a column", "An empty column accepts any card, and dramatically increases how many cards you can move at once.")
    ]

    private var rulesList: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Legal moves", systemImage: "arrow.left.arrow.right")
                .font(.headline)
                .foregroundStyle(Theme.feltText(for: colorScheme))
            ForEach(Array(moves.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.accent)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.0)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.feltText(for: colorScheme))
                        Text(item.1)
                            .font(.subheadline)
                            .foregroundStyle(Theme.feltTextSecondary(for: colorScheme))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.slotFill(for: colorScheme))
        )
    }

    private let tips: [String] = [
        "Plan several moves ahead before you touch a card — FreeCell rewards foresight.",
        "Try to empty a column early; empty columns are your most powerful resource.",
        "Don't rush Aces and 2s up — but everything else, send home only when it's safe.",
        "Keep at least one free cell open as long as you can.",
        "Use Auto-collect to sweep up cards that can never be needed again."
    ]

    private var tipsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Strategy tips", systemImage: "lightbulb.fill")
                .font(.headline)
                .foregroundStyle(Theme.gold)
            ForEach(Array(tips.enumerated()), id: \.offset) { _, tip in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "sparkle")
                        .font(.caption)
                        .foregroundStyle(Theme.gold)
                        .accessibilityHidden(true)
                    Text(tip)
                        .font(.subheadline)
                        .foregroundStyle(Theme.feltText(for: colorScheme))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.gold.opacity(0.12))
        )
    }
}
