import SwiftUI

// Tap the green dot as fast as possible; avoid the red dot
struct ReactionGameView: View {
    let onComplete: (Int, Double, Int) -> Void

    @State private var phase: Phase = .intro
    @State private var dotColor: DotColor = .green
    @State private var dotPosition: CGPoint = .zero
    @State private var roundsPlayed = 0
    @State private var correctTaps = 0
    @State private var totalReactionTime: Double = 0
    @State private var roundStartTime = Date()
    @State private var level = 1
    @State private var startTime = Date()
    @State private var pendingTimer: DispatchWorkItem? = nil
    @State private var containerSize: CGSize = .zero

    enum DotColor { case green, red }
    enum Phase { case intro, waiting, dotVisible, result }

    private let dotRadius: CGFloat = 44

    var body: some View {
        VStack(spacing: 0) {
            switch phase {
            case .intro: introView
            case .waiting: waitingView
            case .dotVisible: dotView
            case .result: resultView
            }
        }
        .navigationTitle("Reaction")
    }

    private var introView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "bolt.fill")
                .font(.system(size: 60))
                .foregroundStyle(NimbleTheme.gameYellow)
                .accessibilityHidden(true)
            Text("Reaction")
                .font(.system(size: 28, weight: .black, design: .rounded))
            Text("Tap the GREEN dot as fast as you can. Avoid the RED dot — that costs a point!")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
            Spacer()
            Button("Start") {
                startTime = Date()
                showNextDot()
            }
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(NimbleTheme.gameYellow)
            .foregroundStyle(.primary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }

    private var waitingView: some View {
        VStack {
            Text("Get ready…")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .padding(.top, 20)
            Spacer()
            Text("\(roundsPlayed)/\(totalRounds)")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 20)
        }
    }

    private var dotView: some View {
        GeometryReader { geo in
            ZStack {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { tappedBackground() }

                Circle()
                    .fill(dotColor == .green ? Color.green : Color.red)
                    .frame(width: dotRadius * 2, height: dotRadius * 2)
                    .shadow(color: (dotColor == .green ? Color.green : Color.red).opacity(0.5), radius: 12)
                    .position(dotPosition)
                    .onTapGesture { tappedDot() }
                    .accessibilityLabel(dotColor == .green ? "Green dot — tap it!" : "Red dot — don't tap!")
                    .accessibilityAddTraits(.isButton)
            }
            .onAppear {
                containerSize = geo.size
            }
        }
    }

    private var resultView: some View {
        VStack(spacing: 20) {
            Spacer()
            let score = computeScore()
            Image(systemName: "bolt.fill")
                .font(.system(size: 56))
                .foregroundStyle(NimbleTheme.scoreColor(score))
                .accessibilityHidden(true)
            Text("\(score)")
                .font(.system(size: 72, weight: .black, design: .rounded))
                .foregroundStyle(NimbleTheme.scoreColor(score))
                .accessibilityLabel("Score: \(score) out of 100")
            if correctTaps > 0 {
                Text("Avg reaction: \(Int(totalReactionTime / Double(correctTaps) * 1000))ms")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Done") {
                let duration = Date().timeIntervalSince(startTime)
                onComplete(computeScore(), duration, level)
            }
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(NimbleTheme.gameYellow)
            .foregroundStyle(.primary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }

    private var totalRounds: Int { 10 }

    // MARK: Logic

    private func showNextDot() {
        phase = .waiting
        let redFreq = level <= 3 ? 0.2 : level <= 6 ? 0.35 : 0.45
        let delay = Double.random(in: 0.8...2.2)
        let work = DispatchWorkItem {
            guard phase == .waiting else { return }
            dotColor = Double.random(in: 0...1) < redFreq ? .red : .green
            dotPosition = randomPosition()
            roundStartTime = Date()
            phase = .dotVisible

            // Auto-miss after 2 seconds
            let missWork = DispatchWorkItem {
                guard phase == .dotVisible else { return }
                roundsPlayed += 1
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                nextOrFinish()
            }
            pendingTimer = missWork
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: missWork)
        }
        pendingTimer = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    private func tappedDot() {
        pendingTimer?.cancel()
        let rt = Date().timeIntervalSince(roundStartTime)
        roundsPlayed += 1
        if dotColor == .green {
            correctTaps += 1
            totalReactionTime += rt
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        nextOrFinish()
    }

    private func tappedBackground() {
        guard phase == .dotVisible else { return }
        // Missed — count as incorrect
        pendingTimer?.cancel()
        roundsPlayed += 1
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        nextOrFinish()
    }

    private func nextOrFinish() {
        if roundsPlayed >= totalRounds {
            phase = .result
        } else {
            if correctTaps > 0 && correctTaps % 3 == 0 { level = min(10, level + 1) }
            showNextDot()
        }
    }

    private func randomPosition() -> CGPoint {
        let w = max(containerSize.width, 300)
        let h = max(containerSize.height, 400)
        let margin = dotRadius + 10
        let x = CGFloat.random(in: margin...(w - margin))
        let y = CGFloat.random(in: margin...(h - margin))
        return CGPoint(x: x, y: y)
    }

    private func computeScore() -> Int {
        guard roundsPlayed > 0 else { return 0 }
        // Base: accuracy
        let accuracy = Double(correctTaps) / Double(totalRounds)
        // Bonus: reaction speed (target <400ms = full bonus)
        let avgRT = correctTaps > 0 ? totalReactionTime / Double(correctTaps) : 2.0
        let speedBonus = max(0.0, 1.0 - avgRT / 0.8)
        return min(100, Int((accuracy * 70) + (speedBonus * 30)))
    }
}
