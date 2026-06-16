import SwiftUI

/// A lightweight, deterministic confetti burst. Honors Reduce Motion by falling back
/// to a static celebratory sparkle arrangement (no animation).
struct ConfettiView: View {
    var isActive: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let pieces: [ConfettiPiece] = ConfettiView.makePieces()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { piece in
                    if reduceMotion {
                        // Static fallback: a calm scattered sparkle, no motion.
                        Image(systemName: "sparkle")
                            .font(.system(size: piece.size))
                            .foregroundStyle(piece.color)
                            .position(
                                x: piece.startX * geo.size.width,
                                y: piece.startY * geo.size.height
                            )
                            .opacity(0.85)
                    } else {
                        ConfettiPieceView(piece: piece, isActive: isActive, size: geo.size)
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    static func makePieces() -> [ConfettiPiece] {
        var rng = SeededRNG(seed: 0xC0FFEE)
        let colors: [Color] = [
            Color(hex: 0xE0654E), Color(hex: 0xE08A2E), Color(hex: 0x4FA773),
            Color(hex: 0x3E86C9), Color(hex: 0x8A63C9)
        ]
        var result: [ConfettiPiece] = []
        for i in 0..<36 {
            let color = rng.pick(colors) ?? Theme.accent
            result.append(
                ConfettiPiece(
                    id: i,
                    startX: Double(rng.int(upperBound: 100)) / 100.0,
                    startY: Double(rng.int(upperBound: 40)) / 100.0,
                    drift: Double(rng.int(upperBound: 60) - 30) / 100.0,
                    size: CGFloat(10 + rng.int(upperBound: 10)),
                    delay: Double(rng.int(upperBound: 40)) / 100.0,
                    color: color
                )
            )
        }
        return result
    }
}

struct ConfettiPiece: Identifiable {
    let id: Int
    let startX: Double
    let startY: Double
    let drift: Double
    let size: CGFloat
    let delay: Double
    let color: Color
}

private struct ConfettiPieceView: View {
    let piece: ConfettiPiece
    let isActive: Bool
    let size: CGSize
    @State private var animate = false

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(piece.color)
            .frame(width: piece.size, height: piece.size * 0.6)
            .rotationEffect(.degrees(animate ? 220 : 0))
            .position(
                x: (piece.startX + (animate ? piece.drift : 0)) * size.width,
                y: (animate ? 1.1 : piece.startY) * size.height
            )
            .opacity(animate ? 0 : 1)
            .onChange(of: isActive) { _, newValue in
                if newValue { trigger() }
            }
            .onAppear {
                if isActive { trigger() }
            }
    }

    private func trigger() {
        animate = false
        withAnimation(.easeIn(duration: 1.6).delay(piece.delay)) {
            animate = true
        }
    }
}
