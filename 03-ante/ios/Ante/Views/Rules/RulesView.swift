import SwiftUI

struct RulesSection: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let content: [RuleItem]
}

struct RuleItem: Identifiable {
    let id = UUID()
    let heading: String
    let body: String
}

struct RulesView: View {
    @State private var expandedSections: Set<UUID> = []

    private let sections: [RulesSection] = [
        RulesSection(
            title: "The Basics",
            icon: "info.circle.fill",
            color: .cyan,
            content: [
                RuleItem(heading: "Objective", body: "Score points by forming melds (sets and runs) and reducing your deadwood (unmatched cards) to zero or below 10 to knock. First player to reach 100 points wins the game."),
                RuleItem(heading: "Setup", body: "Each player is dealt 10 cards. The remaining cards form the stock pile. The top card is turned face-up to start the discard pile."),
                RuleItem(heading: "Turn Structure", body: "On your turn: (1) Draw from the stock pile or take the top discard. (2) Optionally knock if your deadwood ≤ 10. (3) Discard one card face-up."),
            ]
        ),
        RulesSection(
            title: "Melds",
            icon: "square.grid.2x2.fill",
            color: AnteTheme.gold,
            content: [
                RuleItem(heading: "Sets (Books)", body: "Three or four cards of the same rank. Example: 7♠ 7♥ 7♦ is a valid set."),
                RuleItem(heading: "Runs (Sequences)", body: "Three or more consecutive cards of the same suit. Example: 4♣ 5♣ 6♣ 7♣ is a valid run. Aces are always low (A-2-3 valid, Q-K-A not valid)."),
                RuleItem(heading: "Card Values", body: "Aces = 1 pt. Face cards (J, Q, K) = 10 pts each. Number cards = face value. Values count toward deadwood."),
            ]
        ),
        RulesSection(
            title: "Knocking",
            icon: "hand.tap.fill",
            color: .orange,
            content: [
                RuleItem(heading: "When to Knock", body: "You can knock on your turn after drawing (before discarding) when your total deadwood value is 10 or fewer points."),
                RuleItem(heading: "How to Knock", body: "Tap the KNOCK button. Both hands are revealed. Your opponent can lay off their unmatched cards onto your melds to reduce their deadwood."),
                RuleItem(heading: "Scoring After Knock", body: "Knocker scores the difference: opponent's deadwood minus knocker's deadwood. If knocker's deadwood is higher, the opponent undercuts and scores the difference + 25 bonus."),
            ]
        ),
        RulesSection(
            title: "Gin!",
            icon: "crown.fill",
            color: AnteTheme.gold,
            content: [
                RuleItem(heading: "Going Gin", body: "If you knock with 0 deadwood (all 10 cards in melds), you've gone Gin! The opponent cannot lay off cards."),
                RuleItem(heading: "Gin Bonus", body: "Going Gin earns you opponent's full deadwood value PLUS a 25-point bonus."),
                RuleItem(heading: "Big Gin", body: "If you can form melds using all 11 cards (10 in hand + drawn card without discarding), you've made Big Gin — same scoring as Gin."),
            ]
        ),
        RulesSection(
            title: "Undercut & Winning",
            icon: "bolt.fill",
            color: .red,
            content: [
                RuleItem(heading: "Undercut", body: "If the defender's deadwood is equal to or less than the knocker's deadwood after laying off, the defender undercuts and earns the difference + 25 bonus."),
                RuleItem(heading: "Dead Hand", body: "If the stock pile runs out before anyone knocks, the hand is a draw — no points scored."),
                RuleItem(heading: "Winning", body: "The first player to reach the target score (default 100) wins the game. Points accumulate across multiple rounds."),
            ]
        ),
    ]

    var body: some View {
        ZStack {
            AnteTheme.feltGreenDark
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 12) {
                    // Header
                    VStack(spacing: 6) {
                        Text("How to Play")
                            .font(.largeTitle.weight(.black))
                            .foregroundColor(.white)
                        Text("Gin Rummy")
                            .font(.title3.weight(.medium))
                            .foregroundColor(AnteTheme.gold)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 8)

                    ForEach(sections) { section in
                        ruleSectionCard(section)
                    }

                    // Quick reference card
                    quickReferenceCard
                        .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationTitle("Rules")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func ruleSectionCard(_ section: RulesSection) -> some View {
        let isExpanded = expandedSections.contains(section.id)
        return VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    if isExpanded {
                        expandedSections.remove(section.id)
                    } else {
                        expandedSections.insert(section.id)
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: section.icon)
                        .foregroundColor(section.color)
                        .font(.title3)
                        .frame(width: 32)
                    Text(section.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(AnteTheme.textMuted)
                        .font(.caption.weight(.bold))
                }
                .padding(16)
            }

            if isExpanded {
                Divider()
                    .background(AnteTheme.gold.opacity(0.2))

                VStack(alignment: .leading, spacing: 16) {
                    ForEach(section.content) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.heading)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(section.color)
                            Text(item.body)
                                .font(.subheadline)
                                .foregroundColor(AnteTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(16)
            }
        }
        .background(AnteTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isExpanded ? AnteTheme.gold.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }

    private var quickReferenceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Quick Reference", systemImage: "bolt.circle.fill")
                .font(.headline)
                .foregroundColor(AnteTheme.gold)

            quickRefRow(icon: "hand.tap", label: "Knock when", value: "Deadwood ≤ 10")
            quickRefRow(icon: "crown", label: "Gin bonus", value: "+25 pts")
            quickRefRow(icon: "bolt", label: "Undercut bonus", value: "+25 pts")
            quickRefRow(icon: "flag.checkered", label: "Game ends at", value: "100 pts")
            quickRefRow(icon: "suit.heart", label: "Ace value", value: "1 point")
            quickRefRow(icon: "suit.diamond", label: "Face card value", value: "10 points")
        }
        .padding(16)
        .background(AnteTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AnteTheme.gold.opacity(0.2), lineWidth: 1)
        )
    }

    private func quickRefRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(AnteTheme.textMuted)
                .frame(width: 24)
            Text(label)
                .font(.subheadline)
                .foregroundColor(AnteTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(AnteTheme.gold)
        }
    }
}
