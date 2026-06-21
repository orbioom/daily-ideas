import SwiftUI
import SwiftData

struct GameView: View {
    @Query private var settingsArr: [IvorySettings]
    @Environment(\.modelContext) private var ctx
    @State private var vm = GameViewModel()
    @State private var showNewGameSheet = false
    @State private var showGameOverAlert = false

    private var settings: IvorySettings {
        settingsArr.first ?? { let s = IvorySettings(); ctx.insert(s); return s }()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                IvoryTheme.background.ignoresSafeArea()
                VStack(spacing: 20) {
                    scoreHeader
                    BoardView(vm: vm)
                        .padding(.horizontal, 12)
                    statusBar
                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("Ivory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showNewGameSheet = true } label: {
                        Label("New Game", systemImage: "plus.circle")
                    }
                    .accessibilityLabel("Start new game")
                }
            }
            .sheet(isPresented: $showNewGameSheet) {
                NewGameSheet(vm: vm, settings: settings)
            }
            .onChange(of: vm.phase) { _, newPhase in
                if newPhase == .gameOver {
                    saveGame()
                    showGameOverAlert = true
                }
            }
            .alert("Game Over", isPresented: $showGameOverAlert) {
                Button("Play Again") { showNewGameSheet = true }
                Button("OK", role: .cancel) {}
            } message: {
                let s = vm.score
                let result: String
                if vm.winner == "draw" { result = "It's a draw! \(s.black)–\(s.white)" }
                else if vm.winner == vm.playerPiece.rawValue { result = "You win! \(s.black)–\(s.white)" }
                else { result = "AI wins! \(s.black)–\(s.white)" }
                return Text(result)
            }
            .onAppear {
                vm.playerPiece = settings.playerColor == "white" ? .white : .black
                vm.aiDepth = aiDepth(for: settings.difficulty)
                vm.showHints = settings.showHints
                vm.newGame(playerPiece: vm.playerPiece, depth: vm.aiDepth)
            }
        }
    }

    private var scoreHeader: some View {
        HStack {
            scoreCard(label: "Black", disc: "⚫", count: vm.score.black, highlight: vm.currentTurn == .black)
            Spacer()
            scoreCard(label: "White", disc: "⚪", count: vm.score.white, highlight: vm.currentTurn == .white)
        }
        .padding(.horizontal, 24)
    }

    private func scoreCard(label: String, disc: String, count: Int, highlight: Bool) -> some View {
        VStack(spacing: 4) {
            Text("\(disc) \(label)").font(.caption).foregroundStyle(IvoryTheme.secondaryText)
            Text("\(count)").font(.title.bold()).foregroundStyle(highlight ? IvoryTheme.accent : IvoryTheme.primaryText)
        }
        .padding(12)
        .background(highlight ? IvoryTheme.accent.opacity(0.1) : Color.clear, in: RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(count) discs\(highlight ? ", current turn" : "")")
    }

    private var statusBar: some View {
        Group {
            if vm.phase == .aiThinking {
                HStack(spacing: 8) {
                    ProgressView().tint(IvoryTheme.accent)
                    Text("AI is thinking\u{2026}").foregroundStyle(IvoryTheme.secondaryText)
                }
            } else if vm.phase == .playing {
                let turn = vm.currentTurn == vm.playerPiece ? "Your turn" : "AI's turn"
                Text(turn).font(.subheadline).foregroundStyle(IvoryTheme.secondaryText)
            } else {
                Text("Game Over").font(.headline).foregroundStyle(IvoryTheme.accent)
            }
        }
        .frame(height: 32)
        .accessibilityLabel(
            vm.phase == .aiThinking ? "AI is thinking" :
            vm.phase == .playing ? (vm.currentTurn == vm.playerPiece ? "Your turn" : "AI turn") :
            "Game over"
        )
    }

    private func saveGame() {
        let s = vm.score
        let rec = GameRecord(
            playerColor: vm.playerPiece.rawValue,
            winner: vm.winner,
            blackDiscs: s.black,
            whiteDiscs: s.white,
            difficulty: settings.difficulty,
            durationSeconds: vm.durationSeconds
        )
        ctx.insert(rec)
    }

    private func aiDepth(for difficulty: String) -> Int {
        switch difficulty {
        case "intermediate": return 4
        case "advanced": return 6
        default: return 2
        }
    }
}

struct NewGameSheet: View {
    let vm: GameViewModel
    let settings: IvorySettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                IvoryTheme.background.ignoresSafeArea()
                VStack(spacing: 24) {
                    Text("Choose your color and difficulty, then play!")
                        .font(.subheadline)
                        .foregroundStyle(IvoryTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Difficulty")
                            .font(.headline)
                            .foregroundStyle(IvoryTheme.primaryText)
                        Picker("Difficulty", selection: Binding(
                            get: { settings.difficulty },
                            set: { settings.difficulty = $0 }
                        )) {
                            Text("Beginner").tag("beginner")
                            Text("Intermediate").tag("intermediate")
                            Text("Advanced").tag("advanced")
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Play as")
                            .font(.headline)
                            .foregroundStyle(IvoryTheme.primaryText)
                        Picker("Color", selection: Binding(
                            get: { settings.playerColor },
                            set: { settings.playerColor = $0 }
                        )) {
                            Text("⚫ Black (first)").tag("black")
                            Text("⚪ White (second)").tag("white")
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.horizontal)

                    Button {
                        let depth: Int
                        switch settings.difficulty {
                        case "intermediate": depth = 4
                        case "advanced": depth = 6
                        default: depth = 2
                        }
                        let piece: Piece = settings.playerColor == "white" ? .white : .black
                        vm.showHints = settings.showHints
                        vm.newGame(playerPiece: piece, depth: depth)
                        dismiss()
                    } label: {
                        Text("Start Game")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(IvoryTheme.accent, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .padding(.top, 24)
            }
            .navigationTitle("New Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
