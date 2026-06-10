import SwiftUI

/// Memory Grid: a pattern of tiles lights up briefly; the player taps them back.
/// Each cleared level adds one tile and scores points; a wrong tap ends the
/// level's recall and starts the next (easier) round. Runs for a fixed time.
struct MemoryGameView: View {
    let difficulty: Difficulty
    let duration: Int
    let onComplete: (PlayResult) -> Void

    private let game = Game.memory
    private var gridSize: Int { difficulty == .hard ? 5 : 4 }

    enum Phase { case showing, recall, between }

    @State private var pattern: Set<Int> = []
    @State private var tapped: Set<Int> = []
    @State private var phase: Phase = .between
    @State private var level = 1
    @State private var score = 0
    @State private var correct = 0
    @State private var attempted = 0
    @State private var timeRemaining: Int
    @State private var timer: Timer?
    @State private var message = "Get ready…"
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(difficulty: Difficulty, duration: Int, onComplete: @escaping (PlayResult) -> Void) {
        self.difficulty = difficulty
        self.duration = duration
        self.onComplete = onComplete
        _timeRemaining = State(initialValue: duration)
    }

    private var tileCount: Int { gridSize * gridSize }
    private var patternSize: Int {
        let base = difficulty == .easy ? 2 : 3
        return min(tileCount - 1, base + (level - 1))
    }

    var body: some View {
        ZStack {
            Brand.pageBackground
            VStack(spacing: 0) {
                GameHUD(game: game, timeRemaining: timeRemaining, totalTime: duration,
                        score: score, onQuit: finish)
                Spacer()
                Text(message)
                    .font(.headline)
                    .foregroundStyle(phaseColor)
                    .padding(.bottom, 18)
                    .animation(Brand.ease(0.3), value: message)
                grid
                Text("Level \(level)")
                    .font(Brand.mono(14, weight: .medium))
                    .foregroundStyle(Brand.text3)
                    .padding(.top, 18)
                Spacer()
            }
            .padding(.bottom, 24)
        }
        .onAppear {
            startTimer()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { newRound() }
        }
        .onDisappear { timer?.invalidate() }
    }

    private var phaseColor: Color {
        switch phase { case .showing: game.tint; case .recall: Brand.text; case .between: Brand.text2 }
    }

    private var grid: some View {
        let cols = Array(repeating: GridItem(.flexible(), spacing: 10), count: gridSize)
        return LazyVGrid(columns: cols, spacing: 10) {
            ForEach(0..<tileCount, id: \.self) { i in
                Button { tap(i) } label: {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(fill(for: i))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Brand.glassStroke.opacity(0.4), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(phase != .recall)
                .accessibilityLabel("Tile \(i + 1)")
                .accessibilityAddTraits(tapped.contains(i) ? .isSelected : [])
            }
        }
        .padding(.horizontal, 28)
        .animation(reduceMotion ? nil : Brand.ease(0.25), value: phase)
        .animation(reduceMotion ? nil : Brand.ease(0.2), value: tapped)
    }

    private func fill(for i: Int) -> Color {
        if phase == .showing && pattern.contains(i) { return game.tint }
        if phase == .recall && tapped.contains(i) {
            return pattern.contains(i) ? Brand.live : Brand.danger
        }
        return Brand.dynamic(0xDCDEE6, 0x262931)
    }

    // MARK: - Rounds

    private func newRound() {
        guard timeRemaining > 0 else { return }
        tapped = []
        pattern = []
        while pattern.count < patternSize {
            pattern.insert(Int.random(in: 0..<tileCount))
        }
        phase = .showing
        message = "Memorize"
        let showTime = difficulty == .hard ? 0.7 : 1.0
        DispatchQueue.main.asyncAfter(deadline: .now() + showTime + Double(patternSize) * 0.12) {
            guard timeRemaining > 0 else { return }
            withAnimation { phase = .recall; message = "Tap the tiles" }
        }
    }

    private func tap(_ i: Int) {
        guard phase == .recall, !tapped.contains(i) else { return }
        tapped.insert(i)
        if pattern.contains(i) {
            Haptics.tap()
            if tapped.intersection(pattern) == pattern {
                // Completed the pattern.
                attempted += 1; correct += 1
                score += Int(Double(patternSize * 12) * difficulty.scoreMultiplier)
                Haptics.success()
                phase = .between
                message = "Nice! Level up"
                level += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { newRound() }
            }
        } else {
            // Wrong tile — end this round, drop a level (min 1).
            attempted += 1
            Haptics.warning()
            phase = .between
            message = "Missed — try again"
            level = max(1, level - 1)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { newRound() }
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 { timeRemaining -= 1 } else { finish() }
        }
    }

    private func finish() {
        timer?.invalidate(); timer = nil
        onComplete(PlayResult(game: game, score: score,
                              correct: correct, attempted: max(attempted, correct)))
    }
}
