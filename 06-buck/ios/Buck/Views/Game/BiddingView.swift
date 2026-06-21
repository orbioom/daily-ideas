import SwiftUI

struct BiddingView: View {
    @Bindable var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 20) {
                if viewModel.bidPhase == .round1 {
                    Round1BidView(viewModel: viewModel)
                } else {
                    Round2BidView(viewModel: viewModel)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: .black.opacity(0.3), radius: 20, y: -8)
            )
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Round 1 Bidding

struct Round1BidView: View {
    @Bindable var viewModel: GameViewModel
    @State private var goAlone: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Order Up?")
                .font(.title2.bold())

            if let flipped = viewModel.flippedCard {
                HStack(spacing: 16) {
                    CardView(card: flipped, size: .large, faceDown: false)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Flipped Card")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(flipped.rank.display) of \(flipped.suit.rawValue)")
                            .font(.headline)
                        Text("Would be \(flipped.suit.rawValue) trump")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Toggle("Go Alone", isOn: $goAlone)
                .tint(BuckTheme.accent)

            HStack(spacing: 16) {
                Button(action: { viewModel.humanPass() }) {
                    Text("Pass")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.secondary.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button(action: { viewModel.humanOrderUp(goAlone: goAlone) }) {
                    Text("Order Up")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(BuckTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
}

// MARK: - Round 2 Bidding

struct Round2BidView: View {
    @Bindable var viewModel: GameViewModel

    private var excludedSuit: Suit {
        viewModel.roundFirstBidderExcludedSuit ?? viewModel.flippedCard?.suit ?? .spades
    }

    private var isDealer: Bool {
        viewModel.dealerSeat == .south
    }

    private func suitName(_ suit: Suit) -> String {
        switch suit {
        case .hearts: return "Hearts"
        case .diamonds: return "Diamonds"
        case .clubs: return "Clubs"
        case .spades: return "Spades"
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(isDealer && viewModel.screwTheDealer ? "You Must Call Trump" : "Name Trump Suit")
                .font(.title2.bold())

            Text("Turned-down suit: \(excludedSuit.rawValue)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(Suit.allCases, id: \.self) { suit in
                    if suit != excludedSuit {
                        Button(action: { viewModel.humanCallSuit(suit) }) {
                            HStack {
                                Text(suit.rawValue)
                                    .font(.title)
                                Text(suitName(suit))
                                    .font(.headline)
                            }
                            .foregroundStyle(
                                suit.color == "red"
                                    ? Color(red: 0.85, green: 0.10, blue: 0.10)
                                    : Color.primary
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(
                                        suit.color == "red"
                                            ? Color(red: 0.85, green: 0.10, blue: 0.10).opacity(0.4)
                                            : Color.primary.opacity(0.2),
                                        lineWidth: 1
                                    )
                            )
                        }
                    }
                }
            }

            if !(isDealer && viewModel.screwTheDealer) {
                Button(action: { viewModel.humanPass() }) {
                    Text("Pass")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.secondary.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
}
