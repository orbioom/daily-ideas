import SwiftUI

struct TrickView: View {
    let vm: GameViewModel
    var body: some View {
        VStack(spacing: 8) {
            // North (partner)
            playedCardSlot(seat: .north, label: "Partner")
            HStack(spacing: 20) {
                playedCardSlot(seat: .west, label: "West")
                Spacer()
                playedCardSlot(seat: .east, label: "East")
            }
            .padding(.horizontal, 40)
            // South (human) - we show hand below, just show played card
            playedCardSlot(seat: .south, label: "You")
        }
        .padding()
    }

    private func playedCardSlot(seat: PlayerSeat, label: String) -> some View {
        VStack(spacing: 4) {
            Text(label).font(.caption2).foregroundStyle(.white.opacity(0.6))
            if let entry = vm.currentTrick.cards.first(where: { $0.seat == seat }) {
                CardView(card: entry.card, isHighlighted: vm.currentTrick.winner == seat)
                    .frame(width: 52, height: 80)
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
                    .frame(width: 52, height: 80)
            }
            if let bid = vm.bids[seat] {
                Text(bid.isNil ? "NIL" : "Bid:\(bid.amount)").font(.caption2).foregroundStyle(.white.opacity(0.5))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(vm.currentTrick.cards.first(where: { $0.seat == seat }).map { "\($0.card.rank.symbol)\($0.card.suit.symbol)" } ?? "no card played")")
    }
}
