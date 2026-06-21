import SwiftUI
import SwiftData

struct GameContainerView: View {
    @Query private var settingsArr: [BuckSettings]
    @Environment(\.modelContext) private var ctx
    @State private var viewModel = GameViewModel()
    @State private var gameStarted = false

    var settings: BuckSettings {
        settingsArr.first ?? BuckSettings()
    }

    var body: some View {
        Group {
            if gameStarted {
                GameView(viewModel: viewModel, settings: settings)
            } else {
                StartGameView(onStart: {
                    viewModel.startNewGame(difficulty: settings.difficulty, screwTheDealer: settings.screwTheDealer)
                    gameStarted = true
                })
            }
        }
    }
}

struct StartGameView: View {
    let onStart: () -> Void

    var body: some View {
        ZStack {
            BuckTheme.feltGreen.ignoresSafeArea()
            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text("♠")
                        .font(.system(size: 80))
                        .foregroundStyle(.white)
                    Text("Buck")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Euchre Card Game")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.75))
                }

                Button(action: onStart) {
                    Text("Deal New Game")
                        .font(.headline.bold())
                        .foregroundStyle(BuckTheme.feltGreen)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                }
                .padding(.horizontal, 40)
            }
        }
    }
}
