import SwiftUI
import SwiftData

struct FarkleGameView: View {
    @Query private var prefs: [FarklePrefs]
    @Environment(\.modelContext) private var ctx
    @State private var engine = FarkleEngine()
    @State private var showResult = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var pref: FarklePrefs? { prefs.first }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.08, green: 0.05, blue: 0.05).ignoresSafeArea()

                VStack(spacing: 0) {
                    scoreBoard
                        .padding(.horizontal)
                        .padding(.top, 8)

                    Divider().padding(.vertical, 8)

                    diceArea
                        .padding(.horizontal)

                    Spacer()

                    turnInfo
                        .padding(.horizontal)
                        .padding(.bottom, 8)

                    actionButtons
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                }
            }
            .navigationTitle("Farkle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("New") { startGame() }
                        .foregroundStyle(.red)
                }
            }
            .onAppear { startGame() }
            .alert(resultTitle, isPresented: $showResult) {
                Button("Play Again") { startGame() }
                Button("Dismiss", role: .cancel) {}
            } message: { Text(resultMessage) }
        }
    }

    // MARK: - Subviews

    private var scoreBoard: some View {
        HStack {
            scoreBox("You", score: engine.playerScore, isActive: engine.isPlayerTurn)
            Spacer()
            VStack(spacing: 2) {
                Text("Goal")
                    .font(.caption2)
                    .foregroundStyle(.gray)
                Text("\(engine.targetScore)")
                    .font(.callout.weight(.bold))
                    .foregroundStyle(.orange)
            }
            Spacer()
            scoreBox("AI", score: engine.aiScore, isActive: !engine.isPlayerTurn)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func scoreBox(_ label: String, score: Int, isActive: Bool) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(isActive ? Color.red : Color.gray)
            Text("\(score)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(isActive ? Color.white : Color.gray)
            if isActive {
                Circle()
                    .fill(Color.red)
                    .frame(width: 5, height: 5)
            }
        }
    }

    private var diceArea: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 14) {
            ForEach(engine.dice.indices, id: \.self) { i in
                DiceFaceView(
                    value: engine.dice[i].value,
                    held: engine.dice[i].held,
                    locked: engine.dice[i].locked,
                    color: pref?.diceColor ?? "Red"
                )
                .onTapGesture {
                    guard engine.isPlayerTurn, !engine.isAIThinking else { return }
                    if pref?.hapticsEnabled ?? true {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    engine.toggleHold(index: i)
                }
            }
        }
        .padding(.vertical, 12)
    }

    private var turnInfo: some View {
        VStack(spacing: 6) {
            if engine.isAIThinking {
                Text(engine.aiActionMessage)
                    .font(.callout)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
            } else {
                switch engine.phase {
                case .farkled:
                    Text("💥 FARKLE! No scoring dice.")
                        .font(.callout.weight(.bold))
                        .foregroundStyle(.red)
                case .rolled:
                    if engine.pendingScore > 0 {
                        Text("Held: +\(engine.pendingScore) pts")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(.green)
                    } else {
                        Text("Tap dice to hold scoring ones")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                case .banked, .idle:
                    Text("Roll to start your turn")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                case .gameOver:
                    Text(engine.playerScore >= engine.targetScore ? "You win! 🎉" : "AI wins!")
                        .font(.callout.weight(.bold))
                        .foregroundStyle(engine.playerScore >= engine.targetScore ? .green : .red)
                }
            }
            if engine.turnScore > 0 {
                Text("Turn banked so far: \(engine.turnScore)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 44)
    }

    private var actionButtons: some View {
        HStack(spacing: 14) {
            Button(action: { engine.bank() }) {
                Label("Bank", systemImage: "banknote.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(canBank ? Color.green.opacity(0.8) : Color.gray.opacity(0.2))
                    .foregroundStyle(canBank ? .white : .gray)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!canBank)

            Button(action: { engine.roll() }) {
                Label(rollLabel, systemImage: "die.face.3.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(canRoll ? Color.red : Color.gray.opacity(0.2))
                    .foregroundStyle(canRoll ? .white : .gray)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!canRoll)
        }
    }

    private var rollLabel: String {
        switch engine.phase {
        case .idle: return "Roll"
        default: return engine.pendingScore > 0 ? "Roll Again" : "Roll"
        }
    }

    private var canBank: Bool {
        guard engine.isPlayerTurn, !engine.isAIThinking else { return false }
        return engine.pendingScore > 0 && (engine.turnScore + engine.pendingScore) > 0
    }

    private var canRoll: Bool {
        guard engine.isPlayerTurn, !engine.isAIThinking else { return false }
        switch engine.phase {
        case .gameOver, .farkled: return false
        case .idle: return true
        case .rolled: return engine.pendingScore > 0
        default: return false
        }
    }

    private func startGame() {
        engine.startGame(
            target: pref?.targetScore ?? 10000,
            difficulty: pref?.aiDifficulty ?? "Normal"
        )
    }

    private var resultTitle: String {
        engine.playerScore >= engine.targetScore ? "You Win! 🎉" : "AI Wins"
    }
    private var resultMessage: String {
        engine.playerScore >= engine.targetScore
            ? "You reached \(engine.playerScore) in \(engine.turnsPlayed) turns!"
            : "The AI reached \(engine.aiScore). Better luck next time!"
    }
}

struct DiceFaceView: View {
    let value: Int
    let held: Bool
    let locked: Bool
    let color: String

    private var faceColor: Color {
        if locked { return Color.orange.opacity(0.9) }
        if held { return Color.green.opacity(0.9) }
        switch color {
        case "Blue": return Color(red: 0.15, green: 0.25, blue: 0.55)
        case "Black": return Color(red: 0.15, green: 0.15, blue: 0.15)
        default: return Color(red: 0.65, green: 0.08, blue: 0.10)
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(faceColor)
                .shadow(color: (held || locked) ? .green.opacity(0.4) : .black.opacity(0.4), radius: 6, x: 0, y: 3)

            DicePipsView(value: value)
                .padding(10)
        }
        .frame(width: 90, height: 90)
        .overlay {
            if held || locked {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(locked ? Color.orange : Color.green, lineWidth: 2)
            }
        }
        .accessibilityLabel("Die showing \(value)\(held ? ", held" : "")")
    }
}

struct DicePipsView: View {
    let value: Int

    private let layouts: [Int: [(CGFloat, CGFloat)]] = [
        1: [(0.5, 0.5)],
        2: [(0.25, 0.25), (0.75, 0.75)],
        3: [(0.25, 0.25), (0.5, 0.5), (0.75, 0.75)],
        4: [(0.25, 0.25), (0.75, 0.25), (0.25, 0.75), (0.75, 0.75)],
        5: [(0.25, 0.25), (0.75, 0.25), (0.5, 0.5), (0.25, 0.75), (0.75, 0.75)],
        6: [(0.25, 0.25), (0.75, 0.25), (0.25, 0.5), (0.75, 0.5), (0.25, 0.75), (0.75, 0.75)]
    ]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let pips = layouts[max(1, min(6, value))] ?? []
            ForEach(pips.indices, id: \.self) { i in
                Circle()
                    .fill(.white)
                    .frame(width: w * 0.2, height: h * 0.2)
                    .position(x: pips[i].0 * w, y: pips[i].1 * h)
            }
        }
    }
}
