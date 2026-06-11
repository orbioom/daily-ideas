import SwiftUI

// Memorize highlighted cells in a grid, then recreate them from memory
struct MemoryGridGameView: View {
    let onComplete: (Int, Double, Int) -> Void

    @State private var phase: Phase = .intro
    @State private var gridSize = 3         // 3x3 → 4x4 → 5x5
    @State private var highlighted: Set<Int> = []
    @State private var userSelected: Set<Int> = []
    @State private var showCount = 3        // seconds grid is shown
    @State private var countdown = 3
    @State private var roundsPlayed = 0
    @State private var correctRounds = 0
    @State private var startTime = Date()
    @State private var level = 1

    enum Phase { case intro, showing, input, result }

    private var totalCells: Int { gridSize * gridSize }

    var body: some View {
        VStack(spacing: 24) {
            switch phase {
            case .intro:
                introView
            case .showing:
                showingView
            case .input:
                inputView
            case .result:
                resultView
            }
        }
        .padding()
        .navigationTitle("Memory")
    }

    // MARK: Intro
    private var introView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundStyle(NimbleTheme.gameBlue)
                .accessibilityHidden(true)
            Text("Memory Grid")
                .font(.system(size: 28, weight: .black, design: .rounded))
            Text("Watch which cells light up, then tap them from memory. You have 10 rounds.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
            Spacer()
            Button("Start") {
                beginRound()
            }
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(NimbleTheme.gameBlue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: Showing
    private var showingView: some View {
        VStack(spacing: 20) {
            Text("Memorize!")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .accessibilityAddTraits(.isHeader)
            Text("Showing in \(countdown)…")
                .foregroundStyle(.secondary)
                .font(.system(size: 15, weight: .medium, design: .rounded))
            grid(tappable: false, selected: highlighted)
        }
    }

    // MARK: Input
    private var inputView: some View {
        VStack(spacing: 20) {
            Text("Tap the cells that were highlighted")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            grid(tappable: true, selected: userSelected)
            Button("Submit") {
                checkAnswer()
            }
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(NimbleTheme.gameBlue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .disabled(userSelected.isEmpty)
            .opacity(userSelected.isEmpty ? 0.5 : 1)
        }
    }

    // MARK: Result
    private var resultView: some View {
        VStack(spacing: 20) {
            Spacer()
            let score = roundsPlayed > 0 ? min(100, Int(Double(correctRounds) / Double(roundsPlayed) * 100)) : 0
            Image(systemName: score >= 70 ? "checkmark.seal.fill" : "chart.bar.fill")
                .font(.system(size: 56))
                .foregroundStyle(NimbleTheme.scoreColor(score))
                .accessibilityHidden(true)
            Text("\(score)")
                .font(.system(size: 72, weight: .black, design: .rounded))
                .foregroundStyle(NimbleTheme.scoreColor(score))
                .accessibilityLabel("Score: \(score) out of 100")
            Text("\(correctRounds)/\(roundsPlayed) rounds correct")
                .foregroundStyle(.secondary)
            Spacer()
            Button("Done") {
                let duration = Date().timeIntervalSince(startTime)
                let score2 = min(100, Int(Double(correctRounds) / Double(roundsPlayed) * 100))
                onComplete(score2, duration, level)
            }
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(NimbleTheme.gameBlue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: Grid view

    @ViewBuilder
    private func grid(tappable: Bool, selected: Set<Int>) -> some View {
        let cols = Array(repeating: GridItem(.flexible(), spacing: 8), count: gridSize)
        LazyVGrid(columns: cols, spacing: 8) {
            ForEach(0..<totalCells, id: \.self) { idx in
                RoundedRectangle(cornerRadius: 8)
                    .fill(selected.contains(idx) ? NimbleTheme.gameBlue : Color(.tertiarySystemBackground))
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
                    .onTapGesture {
                        guard tappable else { return }
                        if userSelected.contains(idx) {
                            userSelected.remove(idx)
                        } else {
                            userSelected.insert(idx)
                        }
                    }
                    .accessibilityLabel("Cell \(idx + 1). \(selected.contains(idx) ? "Highlighted." : "")")
                    .accessibilityAddTraits(tappable ? .isButton : [])
            }
        }
        .padding(.horizontal, 8)
    }

    // MARK: Logic

    private func beginRound() {
        startTime = Date()
        highlighted = randomHighlighted()
        userSelected = []
        phase = .showing
        countdown = showCount
        runCountdown()
    }

    private func runCountdown() {
        guard countdown > 0 else {
            phase = .input
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            countdown -= 1
            runCountdown()
        }
    }

    private func checkAnswer() {
        roundsPlayed += 1
        if userSelected == highlighted {
            correctRounds += 1
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }

        if roundsPlayed >= 10 {
            phase = .result
        } else {
            // Increase difficulty every 3 correct rounds
            if correctRounds > 0 && correctRounds % 3 == 0 {
                if gridSize < 5 { gridSize += 1; level = min(10, level + 1) }
                else { showCount = max(1, showCount - 1) }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                highlighted = randomHighlighted()
                userSelected = []
                phase = .showing
                countdown = showCount
                runCountdown()
            }
        }
    }

    private func randomHighlighted() -> Set<Int> {
        let count = max(2, min(totalCells / 2, 2 + level / 2))
        var all = Array(0..<totalCells)
        var result = Set<Int>()
        for _ in 0..<count {
            guard !all.isEmpty else { break }
            let pick = Int.random(in: 0..<all.count)
            result.insert(all[pick])
            all.remove(at: pick)
        }
        return result
    }
}
