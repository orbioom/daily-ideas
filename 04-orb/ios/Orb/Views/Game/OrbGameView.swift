import SwiftUI
import SwiftData

struct OrbGameView: View {
    @Bindable var game: OrbGame
    @Environment(\.modelContext) private var modelContext
    @AppStorage("highestLevelReached") private var highestLevelReached = 1
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("showAimLine") private var showAimLine = true
    @AppStorage("colorBlindMode") private var colorBlindMode = false
    @State private var scoreAnimation = false
    @State private var gridRect: CGRect = .zero

    var body: some View {
        ZStack {
            OrbTheme.background.ignoresSafeArea()

            GeometryReader { geo in
                VStack(spacing: 0) {
                    // Header
                    gameHeader
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    // Grid area
                    let availableH = geo.size.height - 120
                    let gridH = availableH * 0.62
                    let gridW = min(geo.size.width - 32, gridH * 0.85)

                    ZStack {
                        BubbleGridView(
                            game: game,
                            colorBlindMode: colorBlindMode,
                            showAimLine: showAimLine
                        )
                        .frame(width: gridW, height: gridH)
                        .background(
                            GeometryReader { gridGeo in
                                Color.clear
                                    .onAppear {
                                        gridRect = gridGeo.frame(in: .global)
                                        if game.phase == .playing && game.grid.isEmpty {
                                            game.loadLevel(game.currentLevel)
                                        }
                                    }
                                    .onChange(of: gridGeo.size) { _, _ in
                                        gridRect = gridGeo.frame(in: .global)
                                    }
                            }
                        )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                    Spacer(minLength: 8)

                    // Shooter area
                    ShooterView(
                        game: game,
                        gridRect: gridRect,
                        colorBlindMode: colorBlindMode,
                        hapticsEnabled: hapticsEnabled
                    )
                    .frame(height: availableH * 0.32)
                    .padding(.bottom, 8)
                }
            }

            // Overlays
            if game.phase == .levelComplete {
                LevelCompleteView(
                    game: game,
                    onNext: {
                        saveResult(won: true)
                        let nextLevel = game.currentLevel + 1
                        if nextLevel <= LevelDefinition.all.count {
                            if nextLevel > highestLevelReached {
                                highestLevelReached = nextLevel
                            }
                            game.loadLevel(nextLevel)
                        } else {
                            game.nextLevel()
                        }
                    },
                    onReplay: {
                        saveResult(won: true)
                        game.restartLevel()
                    }
                )
                .transition(.opacity.combined(with: .scale))
            }

            if game.phase == .gameOver {
                gameOverOverlay
                    .transition(.opacity.combined(with: .scale))
            }

            if game.phase == .victory {
                victoryOverlay
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .onAppear {
            if game.phase == .playing && game.grid.isEmpty {
                game.loadLevel(1)
                highestLevelReached = max(highestLevelReached, 1)
            }
        }
        .animation(.spring(duration: 0.4), value: game.phase)
    }

    private var gameHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("LEVEL \(game.currentLevel)")
                    .font(.caption)
                    .foregroundColor(OrbTheme.accent)
                    .fontWeight(.bold)
                Text("Score: \(game.score)")
                    .font(.title3.bold())
                    .foregroundColor(OrbTheme.textPrimary)
                    .scaleEffect(scoreAnimation ? 1.15 : 1.0)
                    .onChange(of: game.score) { _, _ in
                        withAnimation(.spring(duration: 0.2)) { scoreAnimation = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            withAnimation { scoreAnimation = false }
                        }
                    }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("SHOTS")
                    .font(.caption)
                    .foregroundColor(OrbTheme.textSecondary)
                Text("\(game.shotsUsed)")
                    .font(.title3.bold())
                    .foregroundColor(OrbTheme.textPrimary)
            }

            Button(action: { game.restartLevel() }) {
                Image(systemName: "arrow.counterclockwise")
                    .foregroundColor(OrbTheme.accent)
                    .font(.title3)
                    .padding(8)
                    .background(OrbTheme.surface)
                    .clipShape(Circle())
            }
            .padding(.leading, 8)
        }
    }

    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(red: 0.9, green: 0.2, blue: 0.2))

                Text("Game Over")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Bubbles reached the bottom!\nLevel \(game.currentLevel)")
                    .font(.body)
                    .foregroundColor(OrbTheme.textSecondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: 12) {
                    Button(action: {
                        saveResult(won: false)
                        game.restartLevel()
                    }) {
                        Label("Try Again", systemImage: "arrow.counterclockwise")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(OrbTheme.accent)
                            .cornerRadius(14)
                    }

                    Button(action: {
                        saveResult(won: false)
                        game.loadLevel(1)
                    }) {
                        Label("Back to Level 1", systemImage: "house.fill")
                            .font(.subheadline)
                            .foregroundColor(OrbTheme.textSecondary)
                    }
                }
                .padding(.horizontal, 40)
            }
            .padding(32)
            .background(OrbTheme.surface)
            .cornerRadius(24)
            .padding(.horizontal, 24)
        }
    }

    private var victoryOverlay: some View {
        ZStack {
            Color.black.opacity(0.8).ignoresSafeArea()
            VStack(spacing: 24) {
                Text("YOU WIN!")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [OrbTheme.accent, OrbTheme.starGold],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("All 20 levels completed!")
                    .font(.title3)
                    .foregroundColor(OrbTheme.textSecondary)

                Text("Total Score: \(game.score)")
                    .font(.title.bold())
                    .foregroundColor(.white)

                Button(action: { game.loadLevel(1) }) {
                    Text("Play Again")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(OrbTheme.accent)
                        .cornerRadius(14)
                        .padding(.horizontal, 40)
                }
            }
            .padding(32)
            .background(OrbTheme.surface)
            .cornerRadius(24)
            .padding(.horizontal, 24)
        }
    }

    private func saveResult(won: Bool) {
        let result = OrbResult(
            level: game.currentLevel,
            score: game.score,
            shotsUsed: game.shotsUsed,
            won: won
        )
        modelContext.insert(result)
        try? modelContext.save()
    }
}
