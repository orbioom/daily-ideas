import SwiftUI

struct GameOutcomeOverlay: View {
    let outcome: GameOutcome
    let score: Int
    let cardsCleared: Int
    let longestCombo: Int
    let elapsed: Double
    let onPlayAgain: () -> Void
    let onHome: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    private var won: Bool { outcome == .won }

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
                .transition(.opacity)

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(won ? Theme.accent.opacity(0.16) : Theme.bad.opacity(0.16))
                        .frame(width: 96, height: 96)
                    Image(systemName: won ? "crown.fill" : "flag.checkered")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(won ? Theme.gold : Theme.bad)
                        .accessibilityHidden(true)
                }
                .scaleEffect(appeared || reduceMotion ? 1 : 0.6)

                Text(won ? "Peaks cleared!" : "No moves left")
                    .font(Theme.rounded(26, .bold))
                    .foregroundStyle(Theme.ink)
                Text(won ? "You cleared all 28 cards." : "The stock ran dry. Try a new deal.")
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)

                HStack(spacing: 10) {
                    StatPill(label: "Score", value: Format.score(score))
                    StatPill(label: "Cleared", value: "\(cardsCleared)/28")
                }
                HStack(spacing: 10) {
                    StatPill(label: "Best combo", value: "x\(longestCombo)", tint: Theme.gold)
                    StatPill(label: "Time", value: Format.clock(elapsed))
                }

                VStack(spacing: 10) {
                    PrimaryButton(title: "Play again", icon: "arrow.clockwise") { onPlayAgain() }
                    PrimaryButton(title: "Home", icon: "house.fill", fill: false) { onHome() }
                }
                .padding(.top, 4)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(Theme.hairline, lineWidth: 1)
            )
            .padding(28)
            .scaleEffect(appeared || reduceMotion ? 1 : 0.94)
            .opacity(appeared || reduceMotion ? 1 : 0)
        }
        .onAppear {
            if reduceMotion { appeared = true }
            else { withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) { appeared = true } }
        }
        .accessibilityElement(children: .contain)
    }
}
