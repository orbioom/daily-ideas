import SwiftUI
import SwiftData

struct GameView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HighScore.score, order: .reverse) private var highScores: [HighScore]

    @State private var engine: CrawlEngine
    @AppStorage("crawlMode") private var savedMode = GameMode.classic.rawValue
    @AppStorage("crawlHaptics") private var hapticsEnabled = true

    init(mode: GameMode = .classic) {
        _engine = State(initialValue: CrawlEngine(mode: mode))
    }

    private var topScore: Int {
        highScores.filter { $0.mode == engine.mode.rawValue }.first?.score ?? 0
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(red: 0.04, green: 0.06, blue: 0.04).ignoresSafeArea()

                VStack(spacing: 0) {
                    scoreBar
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    Spacer(minLength: 8)

                    boardCanvas(geo: geo)
                        .gesture(swipeGesture)
                        .accessibilityLabel("Snake game board")
                        .accessibilityAddTraits(.allowsDirectInteraction)

                    Spacer(minLength: 8)

                    controlBar
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                }

                if engine.gameState == .idle {
                    idleOverlay
                }
                if engine.gameState == .paused {
                    pausedOverlay
                }
                if engine.gameState == .dead {
                    deadOverlay
                }
            }
        }
        .onChange(of: engine.gameState) { _, newState in
            if newState == .dead {
                saveHighScore()
            }
        }
    }

    // MARK: - Board

    private func boardCanvas(geo: GeometryProxy) -> some View {
        let availW = geo.size.width - 32
        let cellSize = availW / CGFloat(engine.cols)
        let boardH = cellSize * CGFloat(engine.rows)

        return Canvas { ctx, size in
            let bg = Path(CGRect(origin: .zero, size: size))
            ctx.fill(bg, with: .color(Color(red: 0.06, green: 0.10, blue: 0.06)))

            for pt in engine.snake {
                let rect = cellRect(pt, cellSize: cellSize)
                let isHead = pt == engine.snake.first
                let color: Color = isHead
                    ? Color(red: 0.5, green: 1.0, blue: 0.5)
                    : Color(red: 0.22, green: 0.78, blue: 0.30)
                ctx.fill(Path(roundedRect: rect.insetBy(dx: 1.5, dy: 1.5), cornerRadius: cellSize * 0.25), with: .color(color))
            }

            let appleRect = cellRect(engine.apple, cellSize: cellSize).insetBy(dx: 2, dy: 2)
            ctx.fill(Path(ellipseIn: appleRect), with: .color(Color(red: 1.0, green: 0.2, blue: 0.2)))
        }
        .frame(width: availW, height: boardH)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.green.opacity(0.25), lineWidth: 1))
    }

    private func cellRect(_ pt: GridPoint, cellSize: CGFloat) -> CGRect {
        CGRect(x: CGFloat(pt.x) * cellSize, y: CGFloat(pt.y) * cellSize, width: cellSize, height: cellSize)
    }

    // MARK: - Gestures

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .onEnded { val in
                let dx = val.translation.width
                let dy = val.translation.height
                let dir: Direction
                if abs(dx) > abs(dy) {
                    dir = dx > 0 ? .right : .left
                } else {
                    dir = dy > 0 ? .down : .up
                }
                engine.handleSwipe(direction: dir)
                if hapticsEnabled {
                    UISelectionFeedbackGenerator().selectionChanged()
                }
            }
    }

    // MARK: - UI

    private var scoreBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("SCORE")
                    .font(.caption2.bold())
                    .foregroundStyle(.green.opacity(0.7))
                Text("\(engine.score)")
                    .font(.title2.bold().monospacedDigit())
                    .foregroundStyle(.white)
            }
            Spacer()
            VStack(alignment: .center, spacing: 2) {
                Text(engine.mode == .classic ? "CLASSIC" : "WALL WRAP")
                    .font(.caption2.bold())
                    .foregroundStyle(.green.opacity(0.6))
                Text("🍎 \(engine.applesEaten)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.white)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("BEST")
                    .font(.caption2.bold())
                    .foregroundStyle(.green.opacity(0.7))
                Text("\(max(topScore, engine.highScore))")
                    .font(.title2.bold().monospacedDigit())
                    .foregroundStyle(.white)
            }
        }
    }

    private var controlBar: some View {
        HStack(spacing: 20) {
            if engine.gameState == .playing {
                Button {
                    engine.pauseGame()
                } label: {
                    Label("Pause", systemImage: "pause.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else {
                Button {
                    engine.startGame()
                    if hapticsEnabled { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
                } label: {
                    Label(engine.gameState == .dead ? "Restart" : "Play", systemImage: engine.gameState == .dead ? "arrow.clockwise" : "play.fill")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    // MARK: - Overlays

    private var idleOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "tortoise.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.green)
                Text("Crawl")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                Text("Swipe to steer · Don't crash")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
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
                    engine.resumeGame()
                } label: {
                    Label("Resume", systemImage: "play.fill")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }

    private var deadOverlay: some View {
        ZStack {
            Color.black.opacity(0.70).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Game Over")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                VStack(spacing: 6) {
                    Text("Score: \(engine.score)")
                        .font(.title2.monospacedDigit())
                        .foregroundStyle(.green)
                    Text("Apples: \(engine.applesEaten)")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.7))
                }
                Button {
                    engine.startGame()
                    if hapticsEnabled { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
                } label: {
                    Label("Play Again", systemImage: "arrow.clockwise")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 36)
                        .padding(.vertical, 14)
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }

    // MARK: - Persistence

    private func saveHighScore() {
        let best = highScores.filter { $0.mode == engine.mode.rawValue }.first?.score ?? 0
        if engine.score > best {
            let hs = HighScore(score: engine.score, mode: engine.mode.rawValue, applesEaten: engine.applesEaten)
            modelContext.insert(hs)
        }
    }
}
