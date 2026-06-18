import SwiftUI

struct HowToPlayView: View {
    private struct Rule: Identifiable {
        let id = UUID()
        let symbol: String
        let title: String
        let body: String
    }

    private let rules: [Rule] = [
        Rule(symbol: "textformat.abc", title: "Four letters or more",
             body: "Every word must be at least four letters long."),
        Rule(symbol: "key.fill", title: "Always use the center",
             body: "The amber center letter must appear in every word you make."),
        Rule(symbol: "arrow.triangle.2.circlepath", title: "Letters can repeat",
             body: "You can use any of the seven letters as many times as you like in a single word."),
        Rule(symbol: "number", title: "Scoring",
             body: "A four-letter word is 1 point. Longer words score their length. A pangram earns a +7 bonus."),
        Rule(symbol: "star.fill", title: "Pangrams",
             body: "Use all seven distinct letters in one word for a pangram — every puzzle has at least one."),
        Rule(symbol: "chart.bar.fill", title: "Rank ladder",
             body: "Your score is a share of the puzzle's maximum. Reach 70% for Genius and 100% for Queen Bee.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(rules) { rule in
                        SectionCard {
                            HStack(alignment: .top, spacing: 14) {
                                Image(systemName: rule.symbol)
                                    .font(.system(size: 22))
                                    .foregroundStyle(Theme.accent)
                                    .frame(width: 30)
                                    .accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(rule.title)
                                        .font(Theme.rounded(17, .bold))
                                        .foregroundStyle(Theme.ink)
                                    Text(rule.body)
                                        .font(Theme.rounded(15))
                                        .foregroundStyle(Theme.inkSoft)
                                }
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(18)
            }
        }
        .navigationTitle("How to Play")
        .navigationBarTitleDisplayMode(.inline)
    }
}
