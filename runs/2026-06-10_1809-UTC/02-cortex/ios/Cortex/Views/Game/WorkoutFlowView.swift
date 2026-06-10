import SwiftUI
import SwiftData

/// The daily workout: runs three deterministic games back-to-back, with a short
/// interstitial between each, then a combined summary.
struct WorkoutFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let games: [Game]
    let difficulty: Difficulty
    let duration: Int

    @State private var stepIndex = 0
    @State private var results: [PlayResult] = []
    @State private var showingInterstitial = true
    @State private var finished = false
    private let workoutID = UUID()

    private var currentGame: Game? {
        stepIndex < games.count ? games[stepIndex] : nil
    }

    var body: some View {
        ZStack {
            if finished {
                summary
            } else if showingInterstitial, let g = currentGame {
                interstitial(g)
            } else if let g = currentGame {
                GamePlayer(game: g, difficulty: difficulty, duration: duration) { r in
                    complete(r)
                }
                .id(stepIndex)
            }
        }
    }

    private func interstitial(_ g: Game) -> some View {
        ZStack {
            Brand.pageBackground
            VStack(spacing: 18) {
                Spacer()
                Text("EXERCISE \(stepIndex + 1) OF \(games.count)")
                    .font(Brand.mono(12, weight: .medium)).tracking(1.6)
                    .foregroundStyle(Brand.text3)
                ZStack {
                    Circle().fill(g.tint.opacity(0.16)).frame(width: 110, height: 110)
                    Image(systemName: g.icon).font(.system(size: 44, weight: .light)).foregroundStyle(g.tint)
                }
                .accessibilityHidden(true)
                Text(g.title).font(.title.bold()).foregroundStyle(Brand.text)
                Text(g.blurb).font(.body).foregroundStyle(Brand.text2)
                    .multilineTextAlignment(.center).padding(.horizontal, 32)
                Spacer()
                Button { withAnimation(Brand.ease()) { showingInterstitial = false } } label: {
                    Label("Start", systemImage: "play.fill")
                }
                .buttonStyle(InkButtonStyle())
                .padding(.horizontal, 28)
                Button("Quit workout") { dismiss() }
                    .font(.subheadline).foregroundStyle(Brand.text3)
                    .padding(.bottom, 24)
            }
        }
    }

    private var summary: some View {
        let total = results.map(\.score).reduce(0, +)
        let avgAcc = results.isEmpty ? 0 : results.map(\.accuracy).reduce(0, +) / Double(results.count)
        return ZStack {
            Brand.pageBackground
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 56)).foregroundStyle(Brand.magic)
                        .accessibilityHidden(true)
                    Text("Workout complete").font(.title.bold()).foregroundStyle(Brand.text)
                    Text("\(total)").font(Brand.mono(60, weight: .bold)).foregroundStyle(Brand.info)
                    Text("brain score").font(.subheadline).foregroundStyle(Brand.text2)

                    HStack(spacing: 12) {
                        StatTile(value: "\(games.count)", label: "Games")
                        StatTile(value: "\(Int(avgAcc * 100))%", label: "Avg accuracy")
                    }
                    .padding(.horizontal, 4)

                    VStack(spacing: 10) {
                        ForEach(results.indices, id: \.self) { i in
                            HStack {
                                Image(systemName: results[i].game.icon)
                                    .foregroundStyle(results[i].game.tint).frame(width: 26)
                                Text(results[i].game.title).foregroundStyle(Brand.text)
                                Spacer()
                                Text("\(results[i].score)")
                                    .font(Brand.mono(16, weight: .semibold)).foregroundStyle(Brand.text2)
                            }
                            .padding(.vertical, 6)
                        }
                    }
                    .padding(18).glassCard()

                    Button("Done") { dismiss() }
                        .buttonStyle(InkButtonStyle())
                }
                .padding(20)
            }
        }
    }

    private func complete(_ r: PlayResult) {
        results.append(r)
        context.insert(GameResult(game: r.game, score: r.score, accuracy: r.accuracy,
                                  correct: r.correct, attempted: r.attempted,
                                  difficulty: difficulty, workoutID: workoutID))
        try? context.save()
        if stepIndex + 1 < games.count {
            stepIndex += 1
            showingInterstitial = true
        } else {
            withAnimation(Brand.ease()) { finished = true }
            Haptics.success()
        }
    }
}
