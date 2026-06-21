import SwiftUI

struct RulesView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    rulesSection(
                        title: "Objective",
                        icon: "trophy.fill",
                        content: "Capture all of your opponent's pieces, or leave them with no legal moves. The first player to do so wins."
                    )

                    rulesSection(
                        title: "The Board",
                        icon: "checkerboard.rectangle",
                        content: "The game is played on an 8×8 board. Pieces only ever occupy the dark squares. Red starts at the top (rows 1–3), Black at the bottom (rows 6–8). Red moves first."
                    )

                    rulesSection(
                        title: "Moving",
                        icon: "arrow.up.right",
                        content: "Regular pieces (men) slide diagonally forward one square to an empty dark square. You cannot move backward."
                    )

                    rulesSection(
                        title: "Capturing",
                        icon: "xmark.circle.fill",
                        content: "Jump over an adjacent opponent piece to an empty square beyond it. The captured piece is removed from the board. If a jump is available anywhere on the board, you MUST jump — this is the mandatory jump rule."
                    )

                    rulesSection(
                        title: "Multiple Jumps",
                        icon: "arrow.triangle.branch",
                        content: "After landing from a jump, if your piece can jump again from its new position, it must continue jumping. A single turn can capture multiple pieces."
                    )

                    rulesSection(
                        title: "Kings",
                        icon: "crown.fill",
                        content: "When a man reaches the opponent's back row (row 8 for Red, row 1 for Black), it becomes a King — marked with a gold crown. Kings can move and jump diagonally in all four directions."
                    )

                    rulesSection(
                        title: "Winning",
                        icon: "star.fill",
                        content: "You win by capturing all opponent pieces, or by blocking all of their moves so they cannot make a legal move on their turn."
                    )

                    Divider()
                        .background(DraughtsTheme.separatorColor)

                    Text("Tips")
                        .font(.title3.bold())
                        .foregroundStyle(DraughtsTheme.gold)

                    VStack(alignment: .leading, spacing: 12) {
                        tipRow(text: "Control the centre of the board early.")
                        tipRow(text: "Trade pieces only when you come out ahead.")
                        tipRow(text: "Push pieces to the back row to create kings.")
                        tipRow(text: "Keep your back row occupied to prevent the opponent from kinging.")
                        tipRow(text: "Look for forced multi-jump combinations.")
                    }

                    Spacer(minLength: 32)
                }
                .padding()
            }
            .background(DraughtsTheme.background.ignoresSafeArea())
            .navigationTitle("How to Play")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(DraughtsTheme.gold)
                }
            }
        }
        .tint(DraughtsTheme.gold)
    }

    @ViewBuilder
    private func rulesSection(title: String, icon: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(DraughtsTheme.gold)

            Text(content)
                .font(.body)
                .foregroundStyle(DraughtsTheme.text.opacity(0.90))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(DraughtsTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func tipRow(text: String) -> some View {
        Label(text, systemImage: "checkmark.circle")
            .font(.subheadline)
            .foregroundStyle(DraughtsTheme.text.opacity(0.80))
    }
}

#Preview {
    RulesView()
}
