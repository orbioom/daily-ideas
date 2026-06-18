import SwiftUI

struct HowToPlayView: View {
    @EnvironmentObject private var settings: AppSettings

    private struct Rule: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let body: String
    }

    private var rules: [Rule] {
        [
            Rule(icon: "mountain.2.fill", title: "The board",
                 body: "28 cards form three overlapping peaks. Below them sit a stock pile and a waste pile."),
            Rule(icon: "lock.open.fill", title: "Open cards",
                 body: "A card is face-up and playable once both cards covering it from below have been cleared."),
            Rule(icon: "arrow.up.arrow.down", title: "Play a card",
                 body: "Tap any open card whose rank is one above or one below the top waste card. It moves to the waste."),
            Rule(icon: "arrow.triangle.2.circlepath",
                 title: settings.wrapAround ? "Wrap-around (on)" : "Wrap-around (off)",
                 body: settings.wrapAround
                    ? "King and Ace count as neighbours, so you can play either onto the other."
                    : "King and Ace are not neighbours. Turn on Wrap-around in Settings to change this."),
            Rule(icon: "rectangle.stack.fill", title: "Draw from stock",
                 body: "Stuck? Tap the stock to flip its top card to the waste. Drawing resets your combo."),
            Rule(icon: "flame.fill", title: "Combos",
                 body: "Each card you clear without drawing raises your combo, and each step is worth more points."),
            Rule(icon: "crown.fill", title: "Winning",
                 body: "Clear all 28 peak cards to win. You lose if the stock empties and no legal move remains.")
        ]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(rules) { r in
                    SurfaceCard {
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: r.icon)
                                .font(.system(size: 22))
                                .foregroundStyle(Theme.accent)
                                .frame(width: 30)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(r.title)
                                    .font(Theme.rounded(17, .semibold))
                                    .foregroundStyle(Theme.ink)
                                Text(r.body)
                                    .font(Theme.rounded(15))
                                    .foregroundStyle(Theme.inkSoft)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(20)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("How to Play")
        .navigationBarTitleDisplayMode(.inline)
    }
}
