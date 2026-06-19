import SwiftUI

struct RulesView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.04, green: 0.08, blue: 0.04).ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(rules) { rule in
                            RuleCard(rule: rule)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Rules")
            .toolbarBackground(Color(red: 0.04, green: 0.08, blue: 0.04), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private struct Rule: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let body: String
    }

    private let rules: [Rule] = [
        Rule(icon: "suit.heart.fill", title: "Objective",
             body: "Have the lowest score when any player reaches 100 points. Avoid taking hearts and the Queen of Spades."),
        Rule(icon: "square.grid.2x2", title: "The Deal",
             body: "All 52 cards are dealt evenly — 13 cards to each of the 4 players."),
        Rule(icon: "arrow.right.circle.fill", title: "Passing",
             body: "Before each round, pass 3 cards to another player. Direction rotates: Left → Right → Across → Hold (no pass) → repeat."),
        Rule(icon: "2.circle.fill", title: "First Trick",
             body: "The player holding the 2♣ leads first. Hearts and the Q♠ cannot be played on the first trick."),
        Rule(icon: "checkmark.circle.fill", title: "Following Suit",
             body: "You must follow the led suit if you can. If you can't, you may play any card. The highest card of the led suit wins the trick."),
        Rule(icon: "heart.slash.fill", title: "Hearts Broken",
             body: "You cannot lead hearts until they have been played on a previous trick (\"hearts broken\"). Then hearts may be led freely."),
        Rule(icon: "plusminus", title: "Scoring",
             body: "Each heart = 1 point. Queen of Spades (Q♠) = 13 points. All other cards = 0. Low score wins."),
        Rule(icon: "moon.fill", title: "Shoot the Moon",
             body: "If one player takes ALL 13 hearts AND the Q♠ in a single round, they score 0 and all other players score 26.")
    ]
}

private struct RuleCard: View {
    let rule: RulesView.Rule

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: rule.icon)
                .font(.title3)
                .foregroundStyle(.red)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(rule.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(rule.body)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

extension RulesView.Rule: @retroactive Identifiable {}
