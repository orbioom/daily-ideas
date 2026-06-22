import SwiftUI
import SwiftData

struct MatchOverView: View {
    @Environment(\.modelContext) private var modelContext
    let engine: DominoEngine
    let onNewMatch: () -> Void
    let onChangeSettings: () -> Void

    @State private var hasRecorded = false

    private var didPlayerWin: Bool { engine.playerScore > engine.aiScore }
    private var matchDuration: Int {
        Int(Date().timeIntervalSince(engine.matchStartTime))
    }

    var body: some View {
        ZStack {
            DominoTheme.mahogany.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Trophy / result
                VStack(spacing: 16) {
                    Text(didPlayerWin ? "🏆" : "🎯")
                        .font(.system(size: 72))

                    Text(didPlayerWin ? "You Win!" : "AI Wins")
                        .font(DominoTheme.titleFont)
                        .foregroundStyle(DominoTheme.gold)

                    Text(didPlayerWin
                         ? "Congratulations! You won the match."
                         : "Better luck next time!")
                        .font(DominoTheme.bodyFont)
                        .foregroundStyle(DominoTheme.ivory.opacity(0.8))
                        .multilineTextAlignment(.center)
                }

                // Final scores
                HStack(spacing: 24) {
                    finalScoreCard(
                        label: "You",
                        score: engine.playerScore,
                        isWinner: didPlayerWin
                    )
                    finalScoreCard(
                        label: "AI",
                        score: engine.aiScore,
                        isWinner: !didPlayerWin
                    )
                }

                // Match stats
                VStack(spacing: 8) {
                    statRow(label: "Rounds Played", value: "\(engine.roundsPlayed)")
                    statRow(label: "Duration", value: formatDuration(matchDuration))
                    statRow(label: "Difficulty", value: engine.difficulty.displayName)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(DominoTheme.mahoganyDark.opacity(0.6))
                )
                .padding(.horizontal, 20)

                Spacer()

                // Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        onNewMatch()
                    }) {
                        Text("Play Again")
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .foregroundStyle(DominoTheme.mahogany)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(DominoTheme.gold)
                            )
                    }
                    .accessibilityLabel("Play again with same settings")

                    Button(action: onChangeSettings) {
                        Text("Change Difficulty")
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .foregroundStyle(DominoTheme.gold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(DominoTheme.gold.opacity(0.5), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            if !hasRecorded {
                recordGame()
                hasRecorded = true
            }
        }
    }

    private func finalScoreCard(label: String, score: Int, isWinner: Bool) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(isWinner ? DominoTheme.gold : DominoTheme.ivory.opacity(0.6))

            Text("\(score)")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(isWinner ? DominoTheme.gold : DominoTheme.ivory)

            if isWinner {
                Text("WINNER")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(DominoTheme.mahogany)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(DominoTheme.gold)
                    )
            }
        }
        .frame(width: 130)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(DominoTheme.mahoganyDark.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isWinner ? DominoTheme.gold.opacity(0.5) : Color.clear, lineWidth: 1.5)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(score) points\(isWinner ? ", winner" : "")")
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(DominoTheme.captionFont)
                .foregroundStyle(DominoTheme.ivory.opacity(0.6))
            Spacer()
            Text(value)
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(DominoTheme.gold)
        }
        .padding(.horizontal, 8)
    }

    private func formatDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return m > 0 ? "\(m)m \(s)s" : "\(s)s"
    }

    private func recordGame() {
        let record = GameRecord(
            playerFinalScore: engine.playerScore,
            aiFinalScore: engine.aiScore,
            didPlayerWin: didPlayerWin,
            roundsPlayed: engine.roundsPlayed,
            difficulty: engine.difficulty.rawValue,
            matchDurationSeconds: matchDuration
        )
        modelContext.insert(record)
        try? modelContext.save()
    }
}
