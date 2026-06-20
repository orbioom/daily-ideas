import SwiftUI

struct GammonRulesView: View {
    var body: some View {
        ZStack {
            GammonTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: GammonTheme.sectionSpacing) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("How to Play")
                            .font(GammonTheme.titleFont)
                            .foregroundStyle(GammonTheme.textPrimary)
                        Text("The complete guide to Backgammon")
                            .font(.subheadline)
                            .foregroundStyle(GammonTheme.textSecondary)
                    }
                    .padding(.top, 8)

                    RulesSection(
                        title: "Objective",
                        icon: "trophy.fill",
                        color: GammonTheme.accent
                    ) {
                        RuleText("Be the first player to bear off (remove) all 15 of your pieces from the board. White pieces move from higher-numbered points toward point 1. Black pieces move from lower-numbered points toward point 24.")
                    }

                    RulesSection(
                        title: "Setup",
                        icon: "rectangle.checkered",
                        color: Color(red: 0.4, green: 0.7, blue: 0.4)
                    ) {
                        RuleText("Each player starts with 15 pieces arranged in the standard backgammon position:")
                        BulletPoint("2 pieces on your opponent's 24-point")
                        BulletPoint("5 pieces on the 13-point")
                        BulletPoint("3 pieces on your 8-point")
                        BulletPoint("5 pieces on your 6-point")
                    }

                    RulesSection(
                        title: "Rolling the Dice",
                        icon: "die.face.5.fill",
                        color: Color(red: 0.6, green: 0.4, blue: 0.9)
                    ) {
                        RuleText("On your turn, tap **Roll Dice** to roll two dice. You must use both dice values as separate moves if legally possible.")
                        RuleText("**Doubles:** If you roll doubles (e.g. 4-4), you get to make four moves of that value instead of two.")
                        RuleText("If you can only use one die value, you must use the higher one if possible. If no moves are available, your turn is skipped.")
                    }

                    RulesSection(
                        title: "Movement",
                        icon: "arrow.right.circle.fill",
                        color: Color(red: 0.3, green: 0.6, blue: 0.9)
                    ) {
                        RuleText("Tap a point with your pieces to select it (highlighted with a gold ring), then tap a highlighted destination to move.")
                        RuleText("You may move to any point that is:")
                        BulletPoint("Empty")
                        BulletPoint("Occupied by one or more of your own pieces")
                        BulletPoint("Occupied by exactly one opponent piece (a **blot**)")
                        RuleText("You cannot move to a point occupied by 2 or more opponent pieces.")
                    }

                    RulesSection(
                        title: "Hitting a Blot",
                        icon: "target",
                        color: Color(red: 0.9, green: 0.4, blue: 0.3)
                    ) {
                        RuleText("When you land on a point occupied by a single opponent piece (a blot), that piece is **hit** and placed on the **bar** in the center of the board.")
                        RuleText("A player with pieces on the bar must re-enter them into the opponent's home board (points 19–24 for White, points 1–6 for Black) before making any other moves.")
                        RuleText("Tap the bar area to select your piece(s) on the bar.")
                    }

                    RulesSection(
                        title: "Bearing Off",
                        icon: "arrow.up.right.square.fill",
                        color: Color(red: 0.8, green: 0.6, blue: 0.2)
                    ) {
                        RuleText("Once all 15 of your pieces are in your home board (points 1–6 for White, 19–24 for Black), you may begin **bearing off**.")
                        RuleText("To bear off, roll a number and remove a piece from that exact point. If no piece is on that point:")
                        BulletPoint("If the rolled number is higher than your highest occupied point, remove a piece from your highest occupied point.")
                        BulletPoint("Otherwise, you must make a legal move within your home board.")
                        RuleText("Tap the bear-off area (right side of the board) after selecting a piece to bear it off.")
                    }

                    RulesSection(
                        title: "Winning",
                        icon: "crown.fill",
                        color: GammonTheme.accent
                    ) {
                        RuleText("The first player to bear off all 15 pieces wins.")
                        RuleText("**Gammon:** If the loser has not borne off any pieces, the winner scores a gammon (worth double).")
                        RuleText("**Backgammon:** If the loser has not borne off any pieces AND still has pieces on the bar or in the winner's home board, it's a backgammon (worth triple).")
                    }

                    RulesSection(
                        title: "Tips & Strategy",
                        icon: "brain.head.profile",
                        color: Color(red: 0.5, green: 0.8, blue: 0.5)
                    ) {
                        BulletPoint("**Make points:** Having 2+ pieces on a point blocks your opponent.")
                        BulletPoint("**Build primes:** Six consecutive blocked points trap opponent's pieces.")
                        BulletPoint("**Hit blots:** Sending opponent to the bar gains tempo.")
                        BulletPoint("**Anchor:** Secure a point in your opponent's home board as insurance.")
                        BulletPoint("**Race:** When ahead in pip count, avoid contact and race to bear off.")
                    }
                }
                .padding(.horizontal, GammonTheme.cardPadding)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Rules")
    }
}

// MARK: - Helper Views

struct RulesSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 28)
                Text(title)
                    .font(GammonTheme.headingFont)
                    .foregroundStyle(GammonTheme.textPrimary)
            }

            VStack(alignment: .leading, spacing: 8) {
                content()
            }
            .padding(GammonTheme.cardPadding)
            .gammonCard()
        }
    }
}

struct RuleText: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(LocalizedStringKey(text))
            .font(.body)
            .foregroundStyle(GammonTheme.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .lineSpacing(3)
    }
}

struct BulletPoint: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(GammonTheme.accent)
                .frame(width: 5, height: 5)
                .padding(.top, 7)
            Text(LocalizedStringKey(text))
                .font(.body)
                .foregroundStyle(GammonTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
        }
    }
}

#Preview {
    GammonRulesView()
        .preferredColorScheme(.dark)
}
