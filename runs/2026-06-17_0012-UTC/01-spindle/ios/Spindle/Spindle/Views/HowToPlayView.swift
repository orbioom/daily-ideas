import SwiftUI

/// A clear rules walkthrough with small visual examples.
struct HowToPlayView: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        NavigationStack {
            ZStack {
                SpindleBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        section(
                            "Objective",
                            "suit.spade.fill",
                            "Clear the table by building eight complete runs of the same suit, from King down to Ace. Each completed run flies to a foundation at the top. Empty the board and you win."
                        )

                        exampleSection

                        section(
                            "Building",
                            "arrow.down",
                            "In the ten columns you build down by one, regardless of suit. A 7 of any suit can go on any 8. Only the bottom card of a column needs to match."
                        )

                        section(
                            "Moving runs",
                            "rectangle.stack",
                            "Pick up a single card, or a whole same-suit run that descends by one — like 8♠ 7♠ 6♠ — and move it as a unit. A descending sequence of mixed suits can only be moved one card at a time."
                        )

                        section(
                            "Dealing",
                            "square.stack.3d.up",
                            "Tap the stock to deal one card face-up to every column. You can only deal when no column is empty — fill the gaps first."
                        )

                        section(
                            "Completing a run",
                            "checkmark.seal.fill",
                            "When a full King-to-Ace same-suit run forms at the bottom of a column, it is collected automatically and you score 100 points. Collect all eight to win."
                        )

                        section(
                            "Scoring & help",
                            "lightbulb",
                            "You start at 500 and lose a point per move, gaining 100 per completed run. Use Undo freely, tap Hint for a legal move, or Auto-collect to gather easy progress. Double-tap a card to auto-move it to the best spot."
                        )
                    }
                    .padding(20)
                }
            }
            .navigationTitle("How to Play")
        }
    }

    private func section(_ title: String, _ icon: String, _ body: String) -> some View {
        SpindleCard {
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: icon)
                    .font(.headline)
                    .foregroundStyle(SpindleTheme.emeraldDeep)
                Text(body)
                    .font(.subheadline)
                    .foregroundStyle(SpindleTheme.primaryText(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    /// A tiny visual: a same-suit run example using real CardViews.
    private var exampleSection: some View {
        SpindleCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("A movable run", systemImage: "hand.tap")
                    .font(.headline)
                    .foregroundStyle(SpindleTheme.emeraldDeep)
                HStack(spacing: -14) {
                    ForEach([8, 7, 6], id: \.self) { rank in
                        CardView(card: Card(suit: .spades, rank: rank, faceUp: true), width: 46, selected: true)
                    }
                }
                .accessibilityElement()
                .accessibilityLabel("Example: eight, seven, six of spades — a same-suit run you can move together.")
                Text("Same suit, each one lower — move all three at once onto any 9.")
                    .font(.caption)
                    .foregroundStyle(SpindleTheme.secondaryText(scheme))
            }
        }
    }
}
