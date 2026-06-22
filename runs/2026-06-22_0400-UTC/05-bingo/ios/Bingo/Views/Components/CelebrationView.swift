import SwiftUI

struct CelebrationView: View {
    let cardLabel: String
    let pattern: String
    let calledCount: Int
    let onDismiss: () -> Void
    let onNewGame: () -> Void

    @State private var particles: [ConfettiParticle] = []
    @State private var isAnimating = false
    @State private var confettiTimer: Timer? = nil

    var patternDisplay: String {
        switch pattern {
        case "row": return "5 in a Row!"
        case "column": return "5 in a Column!"
        case "diagonal": return "Diagonal Win!"
        case "corners": return "Four Corners!"
        case "blackout": return "BLACKOUT!"
        default: return "Winner!"
        }
    }

    var body: some View {
        ZStack {
            BingoTheme.navy.ignoresSafeArea()

            // Confetti canvas
            Canvas { context, size in
                for particle in particles {
                    let rect = CGRect(
                        x: particle.x * size.width,
                        y: particle.y * size.height,
                        width: particle.size,
                        height: particle.size
                    )
                    context.fill(Path(ellipseIn: rect), with: .color(particle.color))
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 28) {
                Spacer()

                Text("🎉")
                    .font(.system(size: 80))
                    .scaleEffect(isAnimating ? 1.2 : 0.8)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.6).repeatCount(3, autoreverses: true),
                        value: isAnimating
                    )

                VStack(spacing: 12) {
                    Text("BINGO!")
                        .font(.system(size: 60, weight: .black))
                        .foregroundColor(BingoTheme.gold)

                    Text(patternDisplay)
                        .font(.title2.bold())
                        .foregroundColor(BingoTheme.red)

                    Text(cardLabel)
                        .font(.title3.bold())
                        .foregroundColor(.white)

                    Text("Won in \(calledCount) calls!")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                VStack(spacing: 12) {
                    Button("New Game 🎱") {
                        stopConfetti()
                        onNewGame()
                    }
                    .buttonStyle(GoldButtonStyle())

                    Button("Continue Playing") {
                        stopConfetti()
                        onDismiss()
                    }
                    .buttonStyle(NavyButtonStyle())
                }
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            isAnimating = true
            startConfetti()
        }
        .onDisappear {
            stopConfetti()
        }
    }

    private func startConfetti() {
        let colors: [Color] = [
            BingoTheme.gold, BingoTheme.red, .white,
            Color(hex: "#3B82F6"), Color(hex: "#10B981"), Color(hex: "#8B5CF6")
        ]
        particles = (0..<120).map { _ in
            ConfettiParticle(
                x: Double.random(in: 0...1),
                y: Double.random(in: -0.2...0.5),
                size: Double.random(in: 6...14),
                color: colors.randomElement() ?? BingoTheme.gold,
                velocity: Double.random(in: 0.001...0.004)
            )
        }

        confettiTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            for i in particles.indices {
                particles[i].y += particles[i].velocity
                particles[i].x += Double.random(in: -0.002...0.002)
                if particles[i].y > 1.1 {
                    particles[i].y = Double.random(in: -0.2...0)
                    particles[i].x = Double.random(in: 0...1)
                }
            }
        }
    }

    private func stopConfetti() {
        confettiTimer?.invalidate()
        confettiTimer = nil
        isAnimating = false
    }
}

struct ConfettiParticle {
    var x: Double
    var y: Double
    var size: Double
    var color: Color
    var velocity: Double
}
