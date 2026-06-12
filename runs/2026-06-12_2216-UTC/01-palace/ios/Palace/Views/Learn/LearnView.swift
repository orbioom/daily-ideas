import SwiftUI

private struct RuleSection: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let body: String
}

struct LearnView: View {
    private let sections: [RuleSection] = [
        RuleSection(
            title: "The Goal",
            icon: "crown",
            body: "Move all 52 cards onto the four foundations, one pile per suit, building up from ace to king. When the last king lands, the game is won."
        ),
        RuleSection(
            title: "The Tableau",
            icon: "rectangle.split.3x1",
            body: "Seven columns hold the main play. Build them downward in alternating colors — a red six on a black seven, a black five on that red six. Any face-up run can be moved as a unit, or split anywhere if the destination accepts the top card of the part you take. Only a king may move to an empty column."
        ),
        RuleSection(
            title: "Stock & Waste",
            icon: "rectangle.stack",
            body: "Tap the stock to deal cards to the waste — one or three at a time, set in Settings. Only the top waste card is playable. When the stock runs out, tap it again to recycle the waste back into a fresh stock."
        ),
        RuleSection(
            title: "Tap to Move",
            icon: "hand.tap",
            body: "There is no dragging in Palace. Tap any face-up card and it glides to the best legal home — foundation first, then a tableau column. If the card shakes, it has nowhere to go right now. Tap a foundation card to bring it back down when you need it."
        ),
        RuleSection(
            title: "Scoring",
            icon: "number",
            body: "Waste to tableau: +5. Any card to a foundation: +10. Turning over a hidden tableau card: +5. Foundation back to tableau: −15. Recycling the waste in draw-one costs 100 points. The score never drops below zero."
        ),
        RuleSection(
            title: "Finishing",
            icon: "wand.and.stars",
            body: "Once nothing is hidden and the stock and waste are empty, a Finish Game button appears and plays the rest for you — every game in that position is already won."
        ),
        RuleSection(
            title: "A Few Habits of Strong Players",
            icon: "lightbulb",
            body: "Reveal hidden cards before anything else — an exposed card is worth more than a tidy foundation. Empty columns are precious: hold them for kings you can actually use. Don't rush aces and twos up automatically if you may need them to move runs. In draw-three, count the stock and plan which third cards you can reach."
        ),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(sections) { section in
                        VStack(alignment: .leading, spacing: 8) {
                            Label(section.title, systemImage: section.icon)
                                .font(.headline)
                                .fontDesign(.serif)
                                .foregroundStyle(PalaceTheme.gold)
                            Text(section.body)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .palacePanel()
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("How to Play")
        }
    }
}
