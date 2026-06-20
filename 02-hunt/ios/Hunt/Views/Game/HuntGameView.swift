import SwiftUI
import SwiftData

struct HuntGameView: View {
    let isDaily: Bool
    let dailySeed: UInt64?

    @State private var game = HuntGame()
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hunt_timer_duration") private var timerDuration = 120
    @AppStorage("hunt_haptics_enabled") private var hapticsEnabled = true
    @State private var showTimeUp = false
    @State private var wordBounce = false

    init(isDaily: Bool, dailySeed: UInt64? = nil) {
        self.isDaily = isDaily
        self.dailySeed = dailySeed
    }

    var body: some View {
        ZStack {
            HuntTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                Spacer(minLength: 8)

                // Board
                if game.isLoadingBoard {
                    ProgressView()
                        .tint(HuntTheme.accent)
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity)
                        .padding(60)
                } else if game.board.isEmpty {
                    startPrompt
                } else {
                    HuntBoardView(
                        board: game.board,
                        selectedPath: game.selectedPath,
                        onSelectCell: { r, c in
                            if hapticsEnabled { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
                            game.selectCell(r, c)
                        },
                        onCommit: {
                            let prevCount = game.foundWords.count
                            game.commitSelection()
                            if game.foundWords.count > prevCount {
                                if hapticsEnabled { UINotificationFeedbackGenerator().notificationOccurred(.success) }
                                withAnimation(.spring(duration: 0.3)) { wordBounce = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { wordBounce = false }
                            }
                        },
                        onCancel: { game.cancelSelection() }
                    )
                    .padding(.horizontal, 16)
                }

                Spacer(minLength: 8)

                // Current word display
                currentWordView
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)

                // Word bank
                HuntWordBankView(
                    foundWords: game.foundWords,
                    lastWordValid: game.lastWordValid,
                    lastWord: game.lastWord
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .onChange(of: game.phase) { _, newPhase in
            if newPhase == .timeUp {
                saveResult()
                showTimeUp = true
            }
        }
        .sheet(isPresented: $showTimeUp) {
            TimeUpSheet(game: game, isDaily: isDaily) {
                showTimeUp = false
                startNewGame()
            }
            .presentationDetents([.medium, .large])
        }
        .onAppear {
            game.gameDuration = timerDuration
            if isDaily {
                if game.board.isEmpty {
                    startNewGame()
                }
            }
        }
    }

    private var headerView: some View {
        HStack {
            // Score
            VStack(alignment: .leading, spacing: 2) {
                Text("SCORE")
                    .font(.caption2.bold())
                    .foregroundStyle(HuntTheme.secondaryText)
                Text("\(game.score)")
                    .font(.title2.bold())
                    .foregroundStyle(HuntTheme.primaryText)
                    .contentTransition(.numericText())
            }

            Spacer()

            // Timer ring
            timerView

            Spacer()

            // Words found
            VStack(alignment: .trailing, spacing: 2) {
                Text("FOUND")
                    .font(.caption2.bold())
                    .foregroundStyle(HuntTheme.secondaryText)
                Text("\(game.foundWords.count)/\(game.allWords.count)")
                    .font(.title2.bold())
                    .foregroundStyle(HuntTheme.primaryText)
                    .contentTransition(.numericText())
            }
        }
    }

    private var timerView: some View {
        ZStack {
            Circle()
                .stroke(HuntTheme.tileBackground, lineWidth: 5)
                .frame(width: 56, height: 56)

            Circle()
                .trim(from: 0, to: game.phase == .idle ? 1.0 : CGFloat(game.timeRemaining) / CGFloat(game.gameDuration))
                .stroke(
                    HuntTheme.timerColor(for: game.timeRemaining, total: game.gameDuration),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .frame(width: 56, height: 56)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: game.timeRemaining)

            if game.phase == .idle && !game.board.isEmpty {
                Button {
                    game.startGame()
                } label: {
                    Image(systemName: "play.fill")
                        .font(.title3)
                        .foregroundStyle(HuntTheme.timerNormal)
                }
            } else {
                Text(game.phase == .idle ? "--:--" : "\(game.timeRemaining / 60):\(String(format: "%02d", game.timeRemaining % 60))")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(HuntTheme.timerColor(for: game.timeRemaining, total: game.gameDuration))
            }
        }
    }

    private var currentWordView: some View {
        HStack {
            if !game.currentWord.isEmpty {
                Text(game.currentWord)
                    .font(.title3.bold())
                    .foregroundStyle(HuntTheme.primaryText)
                    .tracking(4)
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(duration: 0.2), value: game.currentWord)
            } else if game.phase == .idle && !game.board.isEmpty {
                Text("Tap play to start")
                    .font(.callout)
                    .foregroundStyle(HuntTheme.secondaryText)
            } else if game.phase == .playing {
                Text("Swipe to find words")
                    .font(.callout)
                    .foregroundStyle(HuntTheme.secondaryText)
            }
            Spacer()

            if !isDaily || game.phase == .idle {
                Button {
                    startNewGame()
                } label: {
                    Label("New", systemImage: "arrow.clockwise")
                        .font(.caption.bold())
                        .foregroundStyle(HuntTheme.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(HuntTheme.cardBackground)
                        .clipShape(Capsule())
                }
            }
        }
    }

    private var startPrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "textformat.abc")
                .font(.system(size: 60))
                .foregroundStyle(HuntTheme.accent)

            Text(isDaily ? "Today's Challenge" : "Word Hunt")
                .font(.title2.bold())
                .foregroundStyle(HuntTheme.primaryText)

            Button {
                startNewGame()
            } label: {
                Text("New Game")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(HuntTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }

    private func startNewGame() {
        game.gameDuration = timerDuration
        if isDaily {
            game.newGame(seed: dailySeed ?? BoardGenerator.dailySeed())
        } else {
            game.newGame()
        }
    }

    private func saveResult() {
        let result = HuntResult(
            score: game.score,
            wordsFound: game.foundWords.count,
            totalWords: game.allWords.count,
            duration: game.gameDuration,
            isDaily: isDaily
        )
        modelContext.insert(result)
    }
}

private struct TimeUpSheet: View {
    let game: HuntGame
    let isDaily: Bool
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            HuntTheme.background.ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Time's Up!")
                    .font(.largeTitle.bold())
                    .foregroundStyle(HuntTheme.primaryText)

                VStack(spacing: 12) {
                    StatRow(label: "Score", value: "\(game.score)")
                    StatRow(label: "Words Found", value: "\(game.foundWords.count) / \(game.allWords.count)")
                    StatRow(label: "Best Word", value: game.foundWords.max(by: { $0.count < $1.count })?.uppercased() ?? "—")
                    StatRow(label: "Coverage", value: String(format: "%.0f%%", game.percentFound * 100))
                }
                .padding()
                .background(HuntTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 24)

                if !game.foundWords.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(game.foundWords.sorted(), id: \.self) { word in
                                Text(word.uppercased())
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(HuntTheme.validWord)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }

                Button(action: onDismiss) {
                    Text(isDaily ? "Done" : "Play Again")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(HuntTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 24)
            }
            .padding(.top, 32)
        }
    }
}

private struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(HuntTheme.secondaryText)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(HuntTheme.primaryText)
        }
        .font(.callout)
    }
}

#Preview {
    HuntGameView(isDaily: false)
        .modelContainer(for: HuntResult.self, inMemory: true)
}
