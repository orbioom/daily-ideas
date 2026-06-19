import SwiftUI

struct RoundEndView: View {
    @Bindable var engine: HeartsEngine
    let onNextRound: () -> Void
    let onSaveAndExit: () -> Void
    @AppStorage("heartsHaptics") private var hapticsEnabled = true

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            let lastRound = engine.completedRounds.last

            VStack(spacing: 8) {
                if let shooter = lastRound?.shooterIndex {
                    Text("🌙 \(engine.playerNames[shooter]) Shot the Moon!")
                        .font(.title2.bold())
                        .foregroundStyle(.yellow)
                        .multilineTextAlignment(.center)
                } else {
                    Text("Round Complete")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                }
                Text("Round \(engine.completedRounds.count)")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
            }

            scoreTable(lastRound: lastRound)
                .padding(.horizontal, 24)

            Spacer()

            if engine.phase != .gameOver {
                Button {
                    onNextRound()
                    if hapticsEnabled { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
                } label: {
                    Text("Next Round (\(engine.passDirection.label) →)")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(red: 0.85, green: 0.1, blue: 0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
            }

            Button("Save & Exit") { onSaveAndExit() }
                .foregroundStyle(.white.opacity(0.6))
                .padding(.bottom, 40)
        }
    }

    private func scoreTable(lastRound: CompletedRound?) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("Player").font(.caption.bold()).foregroundStyle(.white.opacity(0.5)).frame(maxWidth: .infinity, alignment: .leading)
                Text("Round").font(.caption.bold()).foregroundStyle(.white.opacity(0.5)).frame(width: 56, alignment: .trailing)
                Text("Total").font(.caption.bold()).foregroundStyle(.white.opacity(0.5)).frame(width: 56, alignment: .trailing)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider().background(Color.white.opacity(0.1))

            ForEach(0..<4, id: \.self) { i in
                HStack {
                    HStack(spacing: 6) {
                        if i == 0 { Image(systemName: "person.fill").foregroundStyle(.white.opacity(0.7)).font(.caption) }
                        Text(engine.playerNames[i])
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text("+\(lastRound?.scores[i] ?? 0)")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle((lastRound?.scores[i] ?? 0) == 0 ? .green : .red)
                        .frame(width: 56, alignment: .trailing)

                    Text("\(engine.totalScores[i])")
                        .font(.subheadline.bold().monospacedDigit())
                        .foregroundStyle(.white)
                        .frame(width: 56, alignment: .trailing)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(i == 0 ? Color.white.opacity(0.08) : Color.clear)
            }
        }
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
