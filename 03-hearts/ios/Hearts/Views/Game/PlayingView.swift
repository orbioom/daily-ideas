import SwiftUI

struct PlayingView: View {
    @Bindable var engine: HeartsEngine
    @AppStorage("heartsHaptics") private var hapticsEnabled = true

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                opponentArea(index: 2, label: "North")
                    .frame(height: 100)

                HStack(alignment: .center) {
                    opponentArea(index: 1, label: "West")
                        .frame(width: 80)
                    Spacer()
                    opponentArea(index: 3, label: "East")
                        .frame(width: 80)
                }
                .frame(height: 90)

                trickArea
                    .frame(height: 120)

                Spacer(minLength: 0)

                playerHandArea
                    .padding(.bottom, 20)
            }

            if engine.showTrickResult {
                trickResultOverlay
            }
        }
    }

    private func opponentArea(index: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.6))
            HStack(spacing: -14) {
                ForEach(0..<min(engine.hands[index].count, 8), id: \.self) { _ in
                    CardView(card: Card(suit: .clubs, rank: .two), isFaceDown: true, size: .tiny)
                }
                if engine.hands[index].count > 8 {
                    Text("+\(engine.hands[index].count - 8)")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            Text("\(engine.roundScores[index]) pts")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    private var trickArea: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
                .padding(.horizontal, 20)

            VStack(spacing: 4) {
                if engine.currentTrick.isEmpty {
                    Text(engine.currentPlayerIndex == 0 ? "Your turn to lead" : "Waiting…")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                } else {
                    HStack(spacing: 8) {
                        ForEach(engine.currentTrick) { tc in
                            VStack(spacing: 2) {
                                CardView(card: tc.card, size: .small)
                                Text(engine.playerNames[tc.playerIndex])
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                        }
                    }
                }
            }
        }
    }

    private var playerHandArea: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Your hand")
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
                Text("\(engine.roundScores[0]) pts this round")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.horizontal, 20)

            let legal = engine.legalCards(for: 0)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: -18) {
                    ForEach(engine.hands[0]) { card in
                        let isLegal = engine.phase == .playing && engine.currentPlayerIndex == 0 && legal.contains(card)
                        CardView(card: card, size: .normal)
                            .opacity(isLegal ? 1.0 : 0.45)
                            .onTapGesture {
                                guard isLegal else { return }
                                engine.playCard(card)
                                if hapticsEnabled { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
                            }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private var trickResultOverlay: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 12) {
                let winner = engine.lastTrickWinner
                Text("\(engine.playerNames[winner]) wins the trick")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                let pts = engine.lastCompletedTrick.reduce(0) { $0 + $1.card.pointValue }
                if pts > 0 {
                    Text("+\(pts) point\(pts == 1 ? "" : "s")")
                        .font(.headline)
                        .foregroundStyle(.red)
                }
                HStack(spacing: 6) {
                    ForEach(engine.lastCompletedTrick) { tc in
                        CardView(card: tc.card, size: .small)
                    }
                }
                Button("Continue") {
                    engine.dismissTrickResult()
                    if hapticsEnabled { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
                }
                .font(.headline)
                .foregroundStyle(.black)
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(24)
        }
    }
}
