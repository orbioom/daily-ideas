import SwiftUI
import SpriteKit
import SwiftData

struct GameContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BrickHighScore.score, order: .reverse) private var allScores: [BrickHighScore]
    @AppStorage("brickHaptics") private var hapticsEnabled = true
    @AppStorage("brickSoundEnabled") private var soundEnabled = true

    let startLevel: Int
    @Binding var isPresented: Bool

    @State private var session = BrickSession()
    @State private var scene: BrickScene?
    @State private var showPowerUpBanner = false
    @State private var powerUpText = ""

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.12).ignoresSafeArea()

                if let scene {
                    SpriteView(scene: scene)
                        .ignoresSafeArea()
                }

                VStack {
                    gameHUD
                    Spacer()
                }

                if showPowerUpBanner {
                    VStack {
                        Spacer().frame(height: 80)
                        Text(powerUpText)
                            .font(.headline.bold())
                            .foregroundStyle(.yellow)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.7))
                            .clipShape(Capsule())
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                if session.state == .idle {
                    idleOverlay
                }
                if session.state == .paused {
                    pausedOverlay
                }
                if session.state == .dead {
                    deadOverlay
                }
                if session.state == .levelComplete {
                    levelCompleteOverlay
                }
            }
        }
        .onAppear { setupScene() }
        .navigationBarHidden(true)
    }

    private func setupScene() {
        let layout = BrickLayout.levels[min(startLevel - 1, BrickLayout.levels.count - 1)]
        let brickCount = layout.grid.flatMap { $0 }.filter { $0 > 0 }.count
        session.reset(level: startLevel, brickCount: brickCount)
        session.highScore = allScores.first(where: { $0.level == startLevel })?.score ?? 0

        let s = BrickScene()
        s.size = UIScreen.main.bounds.size
        s.scaleMode = .aspectFill
        s.level = layout
        s.brickDelegate = BrickDelegateAdapter(session: session, onPowerUp: showBanner, hapticsEnabled: hapticsEnabled)
        scene = s
    }

    private func showBanner(text: String) {
        powerUpText = text
        withAnimation { showPowerUpBanner = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showPowerUpBanner = false }
        }
    }

    private var gameHUD: some View {
        HStack {
            Button {
                isPresented = false
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
            }
            .padding(.leading, 16)

            Spacer()

            VStack(spacing: 0) {
                Text("SCORE")
                    .font(.caption2.bold())
                    .foregroundStyle(.white.opacity(0.5))
                Text("\(session.score)")
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(.white)
            }

            Spacer()

            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: i < session.lives ? "heart.fill" : "heart")
                        .foregroundStyle(i < session.lives ? .red : .white.opacity(0.3))
                        .font(.caption)
                }
            }
            .padding(.trailing, 16)
        }
        .padding(.top, 56)
    }

    private var idleOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Level \(session.level)")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                Button {
                    session.state = .playing
                    scene?.launchBall()
                    if hapticsEnabled { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
                } label: {
                    Label("Launch Ball", systemImage: "play.fill")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 36)
                        .padding(.vertical, 14)
                        .background(Color(red: 1, green: 0.6, blue: 0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }

    private var pausedOverlay: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Paused")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                Button {
                    session.state = .playing
                } label: {
                    Label("Resume", systemImage: "play.fill")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 36)
                        .padding(.vertical, 14)
                        .background(Color(red: 1, green: 0.6, blue: 0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                Button("Exit") { isPresented = false }
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    private var deadOverlay: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
            VStack(spacing: 16) {
                Text("Game Over")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                Text("Score: \(session.score)")
                    .font(.title2.monospacedDigit())
                    .foregroundStyle(Color(red: 1, green: 0.6, blue: 0.1))
                Button {
                    saveScore()
                    setupScene()
                } label: {
                    Label("Try Again", systemImage: "arrow.clockwise")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 36)
                        .padding(.vertical, 14)
                        .background(Color(red: 1, green: 0.6, blue: 0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                Button("Exit") { saveScore(); isPresented = false }
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    private var levelCompleteOverlay: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "star.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.yellow)
                Text("Level Complete!")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                Text("Score: \(session.score)")
                    .font(.title2.monospacedDigit())
                    .foregroundStyle(Color(red: 1, green: 0.6, blue: 0.1))
                if session.level < BrickLayout.levels.count {
                    Button {
                        saveScore()
                        let nextLevel = session.level + 1
                        let layout = BrickLayout.levels[nextLevel - 1]
                        let brickCount = layout.grid.flatMap { $0 }.filter { $0 > 0 }.count
                        session.level = nextLevel
                        session.bricksRemaining = brickCount
                        session.state = .idle
                        scene?.nextLevel(layout)
                    } label: {
                        Label("Next Level", systemImage: "forward.fill")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .padding(.horizontal, 36)
                            .padding(.vertical, 14)
                            .background(Color(red: 1, green: 0.6, blue: 0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                } else {
                    Text("You beat all levels!")
                        .font(.headline)
                        .foregroundStyle(.yellow)
                }
                Button("Exit") { saveScore(); isPresented = false }
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    private func saveScore() {
        let existing = allScores.first { $0.level == session.level }
        if let existing {
            if session.score > existing.score {
                existing.score = session.score
            }
        } else if session.score > 0 {
            modelContext.insert(BrickHighScore(level: session.level, score: session.score))
        }
    }
}

private final class BrickDelegateAdapter: BrickSceneDelegate {
    let session: BrickSession
    let onPowerUp: (String) -> Void
    let hapticsEnabled: Bool

    init(session: BrickSession, onPowerUp: @escaping (String) -> Void, hapticsEnabled: Bool) {
        self.session = session
        self.onPowerUp = onPowerUp
        self.hapticsEnabled = hapticsEnabled
    }

    func brickDestroyed(points: Int) {
        DispatchQueue.main.async {
            self.session.brickDestroyed(points: points)
            if self.hapticsEnabled { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
        }
    }

    func lifeLost() {
        DispatchQueue.main.async {
            if self.hapticsEnabled { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
            if self.session.lives > 1 {
                self.session.loseLife()
                self.session.state = .idle
            } else {
                self.session.loseLife()
            }
        }
    }

    func powerUpCollected(_ kind: PowerUpKind) {
        DispatchQueue.main.async {
            let text: String
            switch kind {
            case .widePaddle:  text = "Wide Paddle!"
            case .multiBall:   text = "Multi-Ball!"
            case .laserPaddle: text = "Laser Paddle!"
            case .slowBall:    text = "Slow Ball!"
            }
            self.onPowerUp(text)
            if self.hapticsEnabled { UINotificationFeedbackGenerator().notificationOccurred(.success) }
        }
    }
}
