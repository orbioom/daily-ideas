import SwiftUI
import SwiftData

struct NumbleGameView: View {
    @Query private var prefs: [NumblePrefs]
    @Environment(\.modelContext) private var ctx
    @State private var engine = NumbleEngine()
    @State private var didSave = false

    private var pref: NumblePrefs? { prefs.first }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                guessGrid
                    .padding(.horizontal)
                    .padding(.top, 8)

                if !engine.errorMessage.isEmpty {
                    Text(engine.errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                if engine.isGameOver {
                    gameOverBanner
                        .padding(.horizontal)
                }

                Spacer()
                numberPad
                    .padding(.horizontal)
                    .padding(.bottom, 20)
            }
            .navigationTitle("Numble")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("New") { engine.startRandom(); didSave = false }
                        .foregroundStyle(.purple)
                }
            }
            .onAppear { engine.startDaily() }
            .onChange(of: engine.isGameOver) { _, over in
                if over && !didSave { saveResult(); didSave = true }
            }
        }
    }

    // MARK: - Grid

    private var guessGrid: some View {
        VStack(spacing: 6) {
            ForEach(engine.rows.indices, id: \.self) { r in
                HStack(spacing: 6) {
                    ForEach(engine.rows[r].tiles.indices, id: \.self) { c in
                        let tile = engine.rows[r].tiles[c]
                        tileView(tile, active: r == engine.currentRow && !engine.isGameOver)
                    }
                }
            }
        }
    }

    private func tileView(_ tile: NumbleTile, active: Bool) -> some View {
        let bg: Color = {
            switch tile.state {
            case .correct: return .green
            case .present: return .orange
            case .absent: return Color(.systemGray3)
            case .empty: return active ? Color(.systemGray6) : Color(.systemGray6)
            }
        }()
        let fg: Color = tile.state == .empty ? .primary : .white
        return Text(tile.char == " " ? "" : String(tile.char))
            .font(.system(size: 24, weight: .bold, design: .monospaced))
            .frame(width: 56, height: 56)
            .background(bg)
            .foregroundStyle(fg)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                if active && tile.char == " " {
                    RoundedRectangle(cornerRadius: 8).stroke(Color.purple.opacity(0.4), lineWidth: 1.5)
                }
            }
    }

    // MARK: - Game Over

    private var gameOverBanner: some View {
        VStack(spacing: 8) {
            if engine.isSolved {
                Text("Correct! 🎉").font(.title2.weight(.bold)).foregroundStyle(.green)
            } else {
                Text("Answer: \(engine.target)").font(.title2.weight(.bold)).foregroundStyle(.red)
            }
            Button("Play Again") { engine.startRandom(); didSave = false }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 10)
                .background(.purple)
                .clipShape(Capsule())
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Keyboard

    private let digits: [[Character]] = [
        ["1","2","3","4","5"],
        ["6","7","8","9","0"],
        ["+","-","×","÷","="],
    ]

    private var numberPad: some View {
        VStack(spacing: 8) {
            ForEach(digits.indices, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(digits[row], id: \.self) { ch in
                        keyButton(ch)
                    }
                }
            }
            HStack(spacing: 8) {
                Button(action: { engine.deleteChar() }) {
                    Image(systemName: "delete.backward")
                        .font(.title3)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color(.systemGray4))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                Button(action: {
                    engine.submit()
                    if pref?.hapticsEnabled ?? true {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                }) {
                    Text("Enter")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(.purple)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    private func keyButton(_ ch: Character) -> some View {
        let state = engine.charStates[ch]
        let bg: Color = {
            switch state {
            case .correct: return .green
            case .present: return .orange
            case .absent: return Color(.systemGray3)
            default: return Color(.systemGray5)
            }
        }()
        let fg: Color = state == nil ? .primary : .white
        return Button(action: { engine.appendChar(ch) }) {
            Text(String(ch))
                .font(.system(size: 18, weight: .semibold, design: .monospaced))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(bg)
                .foregroundStyle(fg)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func saveResult() {
        let r = NumbleResult(
            equation: engine.target,
            solved: engine.isSolved,
            attemptsUsed: engine.currentRow + (engine.isSolved ? 0 : 1),
            maxAttempts: engine.maxAttempts
        )
        ctx.insert(r)
    }
}
