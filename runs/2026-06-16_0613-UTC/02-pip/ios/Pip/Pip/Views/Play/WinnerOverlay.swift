import SwiftUI

/// End-of-game overlay showing the winner and final standings.
struct WinnerOverlay: View {
    let engine: GameEngine
    let onDone: () -> Void
    let onPlayAgain: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    private var ranking: [PlayerState] { engine.ranking }

    private var headline: String {
        guard let winner = engine.winner else { return "Game over" }
        if engine.players.count == 1 {
            return "Nice round!"
        }
        if engine.isTie {
            return "It's a tie!"
        }
        return "\(winner.name) wins!"
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
                .onTapGesture {}

            VStack(spacing: 18) {
                ZStack {
                    Circle().fill(Theme.gold.opacity(0.18)).frame(width: 96, height: 96)
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(Theme.gold)
                        .scaleEffect(appeared || reduceMotion ? 1 : 0.4)
                }
                .accessibilityHidden(true)

                Text(headline)
                    .font(Theme.rounded(26, .bold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)

                if let winner = engine.winner {
                    Text("\(winner.grandTotal) points")
                        .font(Theme.rounded(17, .semibold))
                        .foregroundStyle(Theme.accent)
                }

                VStack(spacing: 0) {
                    ForEach(Array(ranking.enumerated()), id: \.element.id) { idx, player in
                        if idx > 0 { Divider().background(Theme.hairline) }
                        HStack {
                            Text("\(idx + 1)")
                                .font(Theme.rounded(15, .bold))
                                .foregroundStyle(idx == 0 ? Theme.gold : Theme.inkSoft)
                                .frame(width: 24)
                            Text(player.name)
                                .font(Theme.rounded(16, .semibold))
                                .foregroundStyle(Theme.ink)
                            Spacer()
                            Text("\(player.grandTotal)")
                                .font(Theme.rounded(17, .bold))
                                .foregroundStyle(Theme.ink)
                        }
                        .padding(.vertical, 11).padding(.horizontal, 14)
                    }
                }
                .background(Theme.surfaceAlt)
                .clipShape(RoundedRectangle(cornerRadius: Theme.rSmall, style: .continuous))

                PrimaryButton(title: "Done", icon: "checkmark") { onDone() }
                if let onPlayAgain {
                    Button("Play again") { onPlayAgain() }
                        .font(Theme.rounded(16, .semibold))
                        .foregroundStyle(Theme.accent)
                }
            }
            .padding(24)
            .frame(maxWidth: 380)
            .card()
            .padding(24)
            .scaleEffect(appeared || reduceMotion ? 1 : 0.85)
            .opacity(appeared || reduceMotion ? 1 : 0)
        }
        .onAppear {
            if reduceMotion { appeared = true }
            else {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { appeared = true }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }
}
