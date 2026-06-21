import SwiftUI
import SwiftData

struct SalvoGameView: View {
    @Query private var prefs: [SalvoPrefs]
    @Environment(\.modelContext) private var ctx
    @State private var engine = SalvoEngine()
    @State private var didSave = false

    private var pref: SalvoPrefs? { prefs.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    statusBar.padding(.horizontal)

                    Text("YOUR FLEET")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                    gridView(cells: engine.playerGrid, isPlayer: true)
                        .padding(.horizontal)

                    if case .playing = engine.phase {
                        Text(engine.isAITurn ? "AI is thinking…" : "TAP TO FIRE")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(engine.isAITurn ? .orange : Color(red: 0.2, green: 0.6, blue: 1.0))
                    }

                    Text("ENEMY WATERS")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                    gridView(cells: engine.aiGrid, isPlayer: false)
                        .padding(.horizontal)

                    if !engine.aiMessage.isEmpty {
                        Text(engine.aiMessage)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }

                    if case .gameOver(let outcome) = engine.phase {
                        gameOverView(outcome: outcome)
                            .padding(.horizontal)
                    }

                    shipStatus.padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Salvo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("New") { startGame() }.foregroundStyle(Color(red: 0.2, green: 0.6, blue: 1.0))
                }
            }
            .onAppear { startGame() }
            .onChange(of: engine.phase.isGameOver) { _, over in
                if over && !didSave { saveResult(); didSave = true }
            }
        }
    }

    // MARK: - Grid

    private func gridView(cells: [CellState], isPlayer: Bool) -> some View {
        GeometryReader { geo in
            let size = (geo.size.width - 9) / 10
            Canvas { ctx, _ in
                for row in 0..<10 {
                    for col in 0..<10 {
                        let x = CGFloat(col) * (size + 1)
                        let y = CGFloat(row) * (size + 1)
                        let rect = CGRect(x: x, y: y, width: size, height: size)
                        let cell = cells[row * 10 + col]
                        let color: Color = {
                            switch cell {
                            case .empty: return Color(.systemGray5)
                            case .ship: return isPlayer ? Color(red: 0.2, green: 0.4, blue: 0.7) : Color(.systemGray5)
                            case .hit: return .red
                            case .miss: return Color(.systemGray3)
                            }
                        }()
                        ctx.fill(Path(roundedRect: rect, cornerRadius: 3), with: .color(color))
                    }
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0).onEnded { val in
                    guard !isPlayer, case .playing = engine.phase, !engine.isAITurn else { return }
                    let col = max(0, min(9, Int(val.location.x / (size + 1))))
                    let row = max(0, min(9, Int(val.location.y / (size + 1))))
                    engine.playerShoot(row: row, col: col)
                    if pref?.hapticsEnabled ?? true {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                }
            )
        }
        .frame(height: UIScreen.main.bounds.width - 32)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Status

    private var statusBar: some View {
        HStack {
            VStack(spacing: 2) {
                Text("Your Shots").font(.caption2).foregroundStyle(.secondary)
                Text("\(engine.shotsPlayer)").font(.title3.weight(.bold))
                    .foregroundStyle(Color(red: 0.2, green: 0.6, blue: 1.0))
            }
            Spacer()
            VStack(spacing: 2) {
                Text("Ships Left").font(.caption2).foregroundStyle(.secondary)
                Text("\(engine.aiShips.filter { !$0.isSunk }.count)")
                    .font(.title3.weight(.bold)).foregroundStyle(.orange)
                Text("vs \(engine.playerShips.filter { !$0.isSunk }.count)")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(spacing: 2) {
                Text("AI Shots").font(.caption2).foregroundStyle(.secondary)
                Text("\(engine.shotsAI)").font(.title3.weight(.bold)).foregroundStyle(.red)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var shipStatus: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Enemy Fleet").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            HStack(spacing: 12) {
                ForEach(engine.aiShips) { ship in
                    VStack(spacing: 2) {
                        Image(systemName: ship.isSunk ? "xmark.circle.fill" : "circle")
                            .foregroundStyle(ship.isSunk ? .red : .secondary)
                            .font(.caption)
                        Text(String(ship.name.prefix(3))).font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func gameOverView(outcome: String) -> some View {
        VStack(spacing: 8) {
            Text(outcome == "win" ? "Victory! 🎖️" : "Defeated!")
                .font(.title2.weight(.bold))
                .foregroundStyle(outcome == "win" ? .green : .red)
            Text(outcome == "win"
                 ? "You sank all enemy ships in \(engine.shotsPlayer) shots!"
                 : "The AI sank your fleet in \(engine.shotsAI) shots.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Play Again") { startGame() }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.1, green: 0.35, blue: 0.75))
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func startGame() {
        engine.startGame(difficulty: pref?.difficulty ?? "Normal")
        didSave = false
    }

    private func saveResult() {
        guard case .gameOver(let outcome) = engine.phase else { return }
        let r = SalvoResult(
            outcome: outcome,
            shotsPlayer: engine.shotsPlayer,
            shotsAI: engine.shotsAI,
            difficulty: engine.difficulty
        )
        ctx.insert(r)
    }
}

extension SalvoEngine.GamePhase {
    var isGameOver: Bool {
        if case .gameOver = self { return true }
        return false
    }
}
