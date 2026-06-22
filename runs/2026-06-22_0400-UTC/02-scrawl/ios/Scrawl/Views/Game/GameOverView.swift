import SwiftUI
import SwiftData

struct GameOverView: View {
    @Bindable var engine: ScrawlGameEngine
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showContent = false
    @State private var confettiParticles: [ConfettiParticle] = []

    var body: some View {
        ZStack {
            Color(red: 1.0, green: 254 / 255, blue: 245 / 255)
                .ignoresSafeArea()

            // Confetti
            if !reduceMotion {
                ForEach(confettiParticles) { particle in
                    ConfettiPiece(particle: particle)
                }
            }

            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                // Winner display
                VStack(spacing: 16) {
                    Text("🏆")
                        .font(.system(size: 80))
                        .scaleEffect(showContent ? 1.0 : 0.3)
                        .animation(
                            reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.6),
                            value: showContent
                        )

                    VStack(spacing: 8) {
                        Text("Game Over!")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(
                                Color(red: 100 / 255, green: 100 / 255, blue: 102 / 255))

                        if engine.isTied {
                            Text("It's a Tie!")
                                .font(.system(size: 36, weight: .black, design: .rounded))
                                .foregroundStyle(
                                    Color(red: 74 / 255, green: 144 / 255, blue: 217 / 255))
                        } else if let winner = engine.winnerTeam {
                            Text(winner.name)
                                .font(.system(size: 36, weight: .black, design: .rounded))
                                .foregroundStyle(
                                    Color(red: 255 / 255, green: 107 / 255, blue: 107 / 255))
                            Text("wins!")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255))
                        }
                    }
                    .opacity(showContent ? 1.0 : 0)
                    .animation(
                        reduceMotion ? nil : .easeOut(duration: 0.4).delay(0.3), value: showContent)
                }

                Spacer().frame(height: 32)

                // Score table
                VStack(spacing: 12) {
                    Text("Final Scores")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255))

                    let sorted = engine.teams.sorted { $0.score > $1.score }
                    ForEach(Array(sorted.enumerated()), id: \.element.id) { index, team in
                        HStack {
                            Text(placeEmoji(index))
                                .font(.system(size: 20))

                            Text(team.name)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(
                                    Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255))

                            Spacer()

                            Text("\(team.score) pts")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    index == 0 && !engine.isTied
                                        ? Color(red: 255 / 255, green: 107 / 255, blue: 107 / 255)
                                        : Color(red: 74 / 255, green: 144 / 255, blue: 217 / 255)
                                )
                        }
                        .padding(14)
                        .background(
                            index == 0 && !engine.isTied
                                ? Color(red: 255 / 255, green: 107 / 255, blue: 107 / 255)
                                    .opacity(0.1)
                                : Color.white
                        )
                        .cornerRadius(12)
                    }
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
                .padding(.horizontal, 24)
                .opacity(showContent ? 1.0 : 0)
                .animation(
                    reduceMotion ? nil : .easeOut(duration: 0.4).delay(0.4), value: showContent)

                Spacer()

                // Buttons
                VStack(spacing: 12) {
                    Button {
                        saveRecord()
                        engine.resetGame()
                        dismiss()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Play Again")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(red: 255 / 255, green: 107 / 255, blue: 107 / 255))
                        .cornerRadius(16)
                        .shadow(
                            color: Color(red: 255 / 255, green: 107 / 255, blue: 107 / 255)
                                .opacity(0.4),
                            radius: 8, x: 0, y: 4
                        )
                    }
                    .accessibilityLabel("Play again")

                    Button {
                        saveRecord()
                        engine.resetGame()
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color(red: 74 / 255, green: 144 / 255, blue: 217 / 255))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Color(red: 74 / 255, green: 144 / 255, blue: 217 / 255).opacity(0.12)
                            )
                            .cornerRadius(16)
                    }
                    .accessibilityLabel("Done, return to home")
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
                .opacity(showContent ? 1.0 : 0)
                .animation(
                    reduceMotion ? nil : .easeOut(duration: 0.4).delay(0.5), value: showContent)
            }
        }
        .onAppear {
            withAnimation { showContent = true }
            if !reduceMotion {
                spawnConfetti()
            }
        }
    }

    private func placeEmoji(_ index: Int) -> String {
        switch index {
        case 0: return "🥇"
        case 1: return "🥈"
        case 2: return "🥉"
        default: return "\(index + 1)."
        }
    }

    private func saveRecord() {
        guard !engine.teams.isEmpty else { return }
        let record = ScrawlRecord(
            teamNames: engine.teams.map(\.name),
            finalScores: engine.teams.map(\.score),
            roundCount: engine.totalRounds,
            wordPackUsed: engine.currentWordPack
        )
        modelContext.insert(record)
        try? modelContext.save()
    }

    private func spawnConfetti() {
        confettiParticles = (0..<40).map { _ in ConfettiParticle() }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let x: CGFloat = CGFloat.random(in: 0...1)
    let delay: Double = Double.random(in: 0...2)
    let duration: Double = Double.random(in: 2...4)
    let color: Color = [
        Color(red: 74 / 255, green: 144 / 255, blue: 217 / 255),
        Color(red: 255 / 255, green: 107 / 255, blue: 107 / 255),
        Color(red: 52 / 255, green: 199 / 255, blue: 89 / 255),
        Color(red: 255 / 255, green: 149 / 255, blue: 0),
        .purple,
    ].randomElement()!
    let size: CGFloat = CGFloat.random(in: 6...14)
    let rotation: Double = Double.random(in: 0...360)
}

struct ConfettiPiece: View {
    let particle: ConfettiParticle
    @State private var yOffset: CGFloat = -50
    @State private var opacity: Double = 0

    var body: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(particle.color)
                .frame(width: particle.size, height: particle.size * 0.5)
                .rotationEffect(.degrees(particle.rotation))
                .position(
                    x: particle.x * geo.size.width,
                    y: yOffset
                )
                .opacity(opacity)
        }
        .onAppear {
            withAnimation(
                .easeIn(duration: particle.duration)
                    .delay(particle.delay)
            ) {
                yOffset = 900
                opacity = 1
            }
        }
        .ignoresSafeArea()
    }
}
