import SwiftUI
import SwiftData

struct GameView: View {
    @Query private var settingsArr: [TricksSettings]
    @Environment(\.modelContext) private var ctx
    @State private var vm = GameViewModel()
    @State private var showNewGameAlert = false

    private var settings: TricksSettings {
        settingsArr.first ?? { let s = TricksSettings(); ctx.insert(s); return s }()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                TricksTheme.felt.ignoresSafeArea()
                VStack(spacing: 0) {
                    scoreHeader.padding(.horizontal).padding(.top, 8)
                    Spacer()
                    tableArea
                    Spacer()
                    humanHandArea
                }
            }
            .navigationTitle("Spades")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showNewGameAlert = true } label: { Label("New Game", systemImage: "arrow.counterclockwise") }
                }
            }
            .alert("New Game?", isPresented: $showNewGameAlert) {
                Button("Cancel", role: .cancel) {}
                Button("New Game", role: .destructive) {
                    vm.startGame(difficulty: settings.difficulty, target: settings.targetScore)
                }
            }
            .onAppear {
                if vm.hands.isEmpty { vm.startGame(difficulty: settings.difficulty, target: settings.targetScore) }
            }
            .onChange(of: vm.phase) { _, phase in
                if case .gameOver = phase { saveGame() }
            }
        }
    }

    private var scoreHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("You & Partner").font(.caption).foregroundStyle(TricksTheme.accent)
                Text("\(vm.gameState.humanTeamScore)").font(.title2.bold()).foregroundStyle(.white)
                Text("Bags: \(vm.gameState.humanTeamBags)").font(.caption2).foregroundStyle(.white.opacity(0.6))
            }
            Spacer()
            VStack(spacing: 2) {
                Text(vm.statusMessage).font(.caption).foregroundStyle(.white.opacity(0.8)).multilineTextAlignment(.center).lineLimit(2)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("Opponents").font(.caption).foregroundStyle(.red.opacity(0.8))
                Text("\(vm.gameState.aiTeamScore)").font(.title2.bold()).foregroundStyle(.white)
                Text("Bags: \(vm.gameState.aiTeamBags)").font(.caption2).foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(12)
        .background(Color.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Score: You and Partner \(vm.gameState.humanTeamScore), Opponents \(vm.gameState.aiTeamScore)")
    }

    @ViewBuilder
    private var tableArea: some View {
        if vm.isHumanBidTurn {
            BiddingView(vm: vm)
        } else if case .gameOver = vm.phase {
            gameOverView
        } else if case .handComplete = vm.phase {
            nextHandButton
        } else {
            TrickView(vm: vm)
        }
    }

    private var gameOverView: some View {
        VStack(spacing: 16) {
            let won = vm.gameState.winner == "you"
            Image(systemName: won ? "trophy.fill" : "xmark.circle.fill")
                .font(.system(size: 56)).foregroundStyle(won ? .yellow : .red).accessibilityHidden(true)
            Text(won ? "You Win!" : "Opponents Win").font(.title.bold()).foregroundStyle(.white)
            Text("Final: You \(vm.gameState.humanTeamScore) – \(vm.gameState.aiTeamScore) Opponents")
                .font(.subheadline).foregroundStyle(.white.opacity(0.8))
            Button {
                vm.startGame(difficulty: settings.difficulty, target: settings.targetScore)
            } label: {
                Text("Play Again").font(.headline).foregroundStyle(.white).padding()
                    .background(TricksTheme.accent, in: RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(24)
        .background(Color.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 20))
        .padding()
    }

    private var nextHandButton: some View {
        VStack(spacing: 12) {
            Text("Hand Complete").font(.headline).foregroundStyle(.white)
            HStack {
                VStack {
                    Text("You+Partner").font(.caption).foregroundStyle(TricksTheme.accent)
                    let ts = (vm.bids[.south]?.amount ?? 0) + (vm.bids[.north]?.amount ?? 0)
                    let tt = (vm.completedTricks[.south] ?? 0) + (vm.completedTricks[.north] ?? 0)
                    Text("Bid \(ts), Won \(tt)").font(.subheadline).foregroundStyle(.white)
                }
                Spacer()
                VStack {
                    Text("Opponents").font(.caption).foregroundStyle(.red.opacity(0.8))
                    let es = (vm.bids[.east]?.amount ?? 0) + (vm.bids[.west]?.amount ?? 0)
                    let et = (vm.completedTricks[.east] ?? 0) + (vm.completedTricks[.west] ?? 0)
                    Text("Bid \(es), Won \(et)").font(.subheadline).foregroundStyle(.white)
                }
            }.padding(.horizontal)
            Button {
                vm.dealHand()
            } label: {
                Text("Deal Next Hand").font(.headline).foregroundStyle(.white).frame(maxWidth: .infinity).padding()
                    .background(TricksTheme.accent, in: RoundedRectangle(cornerRadius: 14))
            }.padding(.horizontal)
        }
        .padding(20)
        .background(Color.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 20))
        .padding()
    }

    private var humanHandArea: some View {
        VStack(spacing: 8) {
            if let bid = vm.bids[.south] {
                let tricks = vm.completedTricks[.south] ?? 0
                Text("Your bid: \(bid.isNil ? "NIL" : "\(bid.amount)") | Tricks: \(tricks)")
                    .font(.caption).foregroundStyle(.white.opacity(0.8))
            }
            HandView(cards: vm.hands[.south] ?? [], legal: vm.legalCardsForHuman(), isHuman: true, seat: .south) { card in
                vm.humanPlay(card: card)
            }
        }
        .padding(.bottom, 12)
    }

    private func saveGame() {
        let rec = SpadesGameRecord(humanTeamScore: vm.gameState.humanTeamScore, aiTeamScore: vm.gameState.aiTeamScore, humanTeamWon: vm.gameState.winner == "you", handsPlayed: vm.gameState.handsPlayed, difficulty: settings.difficulty)
        ctx.insert(rec)
    }
}
