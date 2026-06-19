import SwiftUI
import SwiftData

struct HeartsGameView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("heartsAILevel") private var aiLevelRaw = AILevel.medium.rawValue
    @AppStorage("heartsHaptics") private var hapticsEnabled = true

    @State private var engine: HeartsEngine
    @State private var showExitConfirm = false

    init() {
        let level = AILevel(rawValue: UserDefaults.standard.string(forKey: "heartsAILevel") ?? AILevel.medium.rawValue) ?? .medium
        _engine = State(initialValue: HeartsEngine(aiLevel: level))
    }

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.14, blue: 0.08).ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                switch engine.phase {
                case .passing:
                    PassView(engine: engine)
                case .playing:
                    PlayingView(engine: engine)
                case .roundEnd:
                    RoundEndView(engine: engine, onNextRound: {
                        engine.startNextRound()
                    }, onSaveAndExit: {
                        saveGame()
                        dismiss()
                    })
                case .gameOver:
                    gameOverView
                }
            }
        }
        .alert("Quit Game?", isPresented: $showExitConfirm) {
            Button("Save & Quit") { saveGame(); dismiss() }
            Button("Keep Playing", role: .cancel) {}
        } message: {
            Text("Your progress will be saved.")
        }
        .navigationBarHidden(true)
    }

    private var topBar: some View {
        HStack {
            Button {
                showExitConfirm = true
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Circle())
            }
            .padding(.leading, 16)

            Spacer()

            VStack(spacing: 2) {
                Text(phaseLabel)
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.5))
                Text("Round \(engine.completedRounds.count + 1)")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)
                    .font(.caption)
                Text(engine.heartsBroken ? "Broken" : "Intact")
                    .font(.caption.bold())
                    .foregroundStyle(engine.heartsBroken ? .red : .white.opacity(0.5))
            }
            .padding(.trailing, 16)
        }
        .padding(.top, 56)
        .padding(.bottom, 12)
    }

    private var phaseLabel: String {
        switch engine.phase {
        case .passing: return "PASSING"
        case .playing: return "PLAYING"
        case .roundEnd: return "ROUND END"
        case .gameOver: return "GAME OVER"
        }
    }

    private var gameOverView: some View {
        VStack(spacing: 20) {
            Spacer()
            if let winner = engine.gameWinnerIndex {
                Image(systemName: winner == 0 ? "crown.fill" : "trophy")
                    .font(.system(size: 56))
                    .foregroundStyle(winner == 0 ? .yellow : .white.opacity(0.6))
                Text(winner == 0 ? "You Win!" : "\(engine.playerNames[winner]) Wins")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
            }

            VStack(spacing: 0) {
                ForEach(Array(engine.totalScores.enumerated().sorted { $0.element < $1.element }), id: \.offset) { rank, pair in
                    let idx = pair.0, score = pair.1
                    HStack {
                        Text("\(rank + 1).")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.5))
                            .frame(width: 24)
                        Text(engine.playerNames[idx])
                            .font(.headline)
                            .foregroundStyle(idx == 0 ? .yellow : .white)
                        Spacer()
                        Text("\(score) pts")
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(idx == 0 ? .yellow : .white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(idx == 0 ? Color.yellow.opacity(0.12) : Color.clear)
                }
            }
            .background(Color.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 24)

            Spacer()

            Button {
                saveGame()
                engine.startNewGame()
            } label: {
                Label("Play Again", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(red: 0.85, green: 0.1, blue: 0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)

            Button("Exit") { saveGame(); dismiss() }
                .foregroundStyle(.white.opacity(0.6))
                .padding(.bottom, 40)
        }
    }

    private func saveGame() {
        guard !engine.completedRounds.isEmpty else { return }
        let won = (engine.gameWinnerIndex == 0) || (engine.totalScores[0] == engine.totalScores.min())
        let record = HeartsGameRecord(
            finalScores: engine.totalScores,
            playerWon: won,
            rounds: engine.completedRounds.count,
            aiLevel: engine.aiLevel
        )
        modelContext.insert(record)
    }
}

private extension Array where Element == (offset: Int, element: Int) {
    func sorted(by compare: (Element, Element) -> Bool) -> [Element] {
        self.sorted { compare($0, $1) }
    }
}
