import SwiftUI
import SwiftData

struct GameView: View {
    @Bindable var viewModel: GameViewModel
    @Environment(\.modelContext) private var ctx
    @Query private var settingsArr: [AlleySettings]
    @State private var showGameOver = false
    @State private var showUndoConfirm = false

    var settings: AlleySettings? { settingsArr.first }

    var body: some View {
        ZStack {
            AlleyTheme.darkBackground.ignoresSafeArea()

            if viewModel.isSetup {
                GameSetupView(viewModel: viewModel)
            } else {
                VStack(spacing: 0) {
                    // Navigation bar area
                    HStack {
                        Button {
                            showUndoConfirm = true
                        } label: {
                            Label("Undo", systemImage: "arrow.uturn.backward")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white.opacity(0.8))
                        }

                        Spacer()

                        Text("Alley")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Spacer()

                        Button {
                            viewModel.resetGame()
                        } label: {
                            Label("New", systemImage: "plus")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                    // Scoreboard
                    ScoreboardView(
                        viewModel: viewModel,
                        showRunningTotal: settings?.showRunningTotal ?? true
                    )
                    .padding(.horizontal, 12)

                    Divider()
                        .background(Color.white.opacity(0.1))
                        .padding(.top, 12)

                    if viewModel.isGameOver {
                        GameOverPanel(viewModel: viewModel)
                    } else {
                        // Pin entry
                        ScrollView {
                            PinEntryView(
                                maxPins: viewModel.maxPins,
                                onEntry: { pins in
                                    let haptic = settings?.hapticEnabled ?? true
                                    viewModel.recordBall(pins, haptic: haptic, context: ctx)
                                },
                                currentFrame: viewModel.currentFrame(for: viewModel.currentPlayer),
                                currentBall: viewModel.currentBallInFrame(for: viewModel.currentPlayer),
                                playerName: viewModel.currentPlayerName
                            )
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                    }
                }
            }
        }
        .confirmationDialog("Undo last ball?", isPresented: $showUndoConfirm, titleVisibility: .visible) {
            Button("Undo", role: .destructive) {
                viewModel.undoLastBall()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct GameOverPanel: View {
    let viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("Game Over!")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Results saved to history")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.top, 24)

            // Winner or all scores
            VStack(spacing: 10) {
                ForEach(Array(viewModel.playerNames.enumerated()), id: \.offset) { idx, name in
                    let scores = viewModel.frameScores(for: idx)
                    let finalScore = scores.compactMap { $0 }.last ?? 0
                    let isPerfect = finalScore == 300

                    HStack {
                        Text(name)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white)

                        Spacer()

                        if isPerfect {
                            Text("PERFECT")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(AlleyTheme.strikeColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(AlleyTheme.strikeColor.opacity(0.15))
                                .clipShape(Capsule())
                        }

                        Text("\(finalScore)")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(isPerfect ? AlleyTheme.strikeColor : .white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(AlleyTheme.frameBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 16)
                }
            }

            Button {
                viewModel.resetGame()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("New Game")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AlleyTheme.accent)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: AlleyTheme.accent.opacity(0.4), radius: 8, y: 4)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }
}
