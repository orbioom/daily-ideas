import SwiftUI
import SwiftData

struct GameView: View {
    @Environment(\.modelContext) private var ctx
    @Query private var prefs: [GomokuPrefs]
    @State private var engine = GomokuEngine()
    @State private var showNewGame = false
    @State private var showResult = false
    @State private var elapsed = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var pref: GomokuPrefs? { prefs.first }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                statusBar
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                BoardView(
                    board: engine.board,
                    lastMove: engine.lastMove,
                    winningCells: engine.winningCells,
                    showCoords: pref?.showCoordinates ?? true,
                    boardTheme: pref?.boardTheme ?? "Classic",
                    isThinking: engine.isThinking,
                    onTap: { row, col in
                        guard case .playing = engine.phase else { return }
                        if pref?.hapticsEnabled ?? true {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                        engine.handleTap(row: row, col: col)
                        if case .playing = engine.phase {} else { endGame() }
                    }
                )
                .padding(8)
            }
            .navigationTitle("Gomoku")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("New Game") { showNewGame = true }
                }
            }
            .onAppear { startGame() }
            .sheet(isPresented: $showNewGame) { newGameSheet }
            .alert(resultTitle, isPresented: $showResult) {
                Button("Play Again") { startGame() }
                Button("Dismiss", role: .cancel) {}
            } message: {
                Text(resultMessage)
            }
        }
    }

    // MARK: Status Bar

    private var statusBar: some View {
        HStack {
            stoneIndicator(stone: .black, label: "Black")
            Spacer()
            turnLabel
            Spacer()
            stoneIndicator(stone: .white, label: "White")
        }
    }

    private func stoneIndicator(stone: GomokuEngine.Stone, label: String) -> some View {
        let isHuman = stone == engine.humanStone
        return VStack(spacing: 2) {
            Circle()
                .fill(stone == .black ? Color.black : Color.white)
                .overlay { if stone == .white { Circle().stroke(Color.gray, lineWidth: 1) } }
                .frame(width: 28, height: 28)
            Text(isHuman ? "You" : "AI")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var turnLabel: some View {
        Group {
            switch engine.phase {
            case .playing:
                if engine.isThinking {
                    Label("Thinking…", systemImage: "ellipsis")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.secondary)
                } else {
                    let isYourTurn: Bool = {
                        switch engine.phase {
                        case .playing:
                            let cur = engine.moveCount % 2 == 0 ? GomokuEngine.Stone.black : .white
                            return cur == engine.humanStone
                        default: return false
                        }
                    }()
                    Text(isYourTurn ? "Your turn" : "AI's turn")
                        .font(.callout.weight(.semibold))
                }
            case .won(let s):
                Text(s == engine.humanStone ? "You won! 🎉" : "AI won")
                    .font(.callout.weight(.bold))
                    .foregroundStyle(s == engine.humanStone ? Color.green : Color.red)
            case .draw:
                Text("Draw!")
                    .font(.callout.weight(.bold))
                    .foregroundStyle(.orange)
            }
        }
    }

    // MARK: Helpers

    private var resultTitle: String {
        switch engine.phase {
        case .won(let s): return s == engine.humanStone ? "You Win!" : "AI Wins"
        case .draw: return "Draw!"
        default: return ""
        }
    }

    private var resultMessage: String {
        switch engine.phase {
        case .won(let s):
            if s == engine.humanStone {
                return "Excellent play! \(engine.moveCount) moves in \(engine.elapsedSeconds)s."
            } else {
                return "The AI won this time. Try again!"
            }
        case .draw: return "All squares filled — nicely contested."
        default: return ""
        }
    }

    private func startGame() {
        engine.reset(
            humanColor: pref?.humanColor ?? "Black",
            difficulty: pref?.difficulty ?? "Normal"
        )
    }

    private func endGame() {
        let outcome: String
        switch engine.phase {
        case .won(let s): outcome = s == engine.humanStone ? "win" : "loss"
        case .draw: outcome = "draw"
        default: return
        }
        let result = GomokuResult(
            outcome: outcome,
            difficulty: pref?.difficulty ?? "Normal",
            moves: engine.moveCount,
            durationSeconds: engine.elapsedSeconds
        )
        ctx.insert(result)
        showResult = true
    }

    private var newGameSheet: some View {
        NavigationStack {
            Form {
                Section("Difficulty") {
                    Picker("Difficulty", selection: Binding(
                        get: { pref?.difficulty ?? "Normal" },
                        set: { pref?.difficulty = $0 }
                    )) {
                        ForEach(["Easy", "Normal", "Hard"], id: \.self) { Text($0) }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Play As") {
                    Picker("Color", selection: Binding(
                        get: { pref?.humanColor ?? "Black" },
                        set: { pref?.humanColor = $0 }
                    )) {
                        Text("Black (1st)").tag("Black")
                        Text("White (2nd)").tag("White")
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("New Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showNewGame = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Start") {
                        showNewGame = false
                        startGame()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
