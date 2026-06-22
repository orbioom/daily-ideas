import SwiftUI

struct RulesView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    RulesSection(title: "Overview", icon: "info.circle.fill") {
                        RulesText("Draw Dominoes is played with a double-six set (28 tiles). The goal is to score 100 points before your opponent.")
                    }
                    RulesSection(title: "Setup", icon: "shuffle") {
                        RulesText("Both players draw 7 tiles. Remaining tiles form the boneyard. The player with the highest double plays first; if no doubles, the highest tile goes first.")
                    }
                    RulesSection(title: "Gameplay", icon: "arrow.right.circle.fill") {
                        RulesText("On your turn, play a tile that matches either open end of the chain. If you cannot play, draw from the boneyard until you can play or the boneyard is empty.")
                    }
                    RulesSection(title: "Scoring", icon: "star.fill") {
                        RulesText("A round ends when a player plays all their tiles, or the game is blocked (no one can play). The winner scores the sum of all pips remaining in the opponent's hand. First to 100 wins the match.")
                    }
                    RulesSection(title: "Doubles", icon: "square.on.square") {
                        RulesText("Doubles are placed sideways on the chain. They count as 0+N pips on both ends (e.g., [6|6] both ends are 6).")
                    }
                    RulesSection(title: "Blocked Game", icon: "xmark.circle.fill") {
                        RulesText("If neither player can play and the boneyard is empty, the player with fewer pips in hand wins the round and scores the sum of all pips remaining in both hands.")
                    }
                }
                .padding()
            }
            .background(DominoTheme.background.ignoresSafeArea())
            .navigationTitle("Rules")
            .navigationBarTitleDisplayMode(.large)
        }
        .preferredColorScheme(.dark)
    }
}

private struct RulesSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(DominoTheme.amber)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(DominoTheme.ivory)
            }
            content()
        }
        .padding()
        .background(DominoTheme.card, in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct RulesText: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(DominoTheme.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
    }
}
