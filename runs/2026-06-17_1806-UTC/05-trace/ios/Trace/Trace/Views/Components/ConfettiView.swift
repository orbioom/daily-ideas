import SwiftUI

/// A gentle burst of stars/confetti for success. Respects Reduce Motion by
/// showing a calm static cluster of stars instead of animating.
struct ConfettiView: View {
    var isActive: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pieces: [Piece] = []

    private struct Piece: Identifiable {
        let id = UUID()
        var x: CGFloat
        var startY: CGFloat
        var endY: CGFloat
        var symbol: String
        var color: Color
        var size: CGFloat
        var rotation: Double
    }

    private static let symbols = ["star.fill", "sparkle", "heart.fill", "circle.fill"]
    private static let palette: [Color] = [Theme.star, Theme.accent, Theme.berry, Theme.grass, Theme.sky]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if reduceMotion {
                    // Static, calm reward.
                    HStack(spacing: 14) {
                        ForEach(0..<5, id: \.self) { i in
                            Image(systemName: "star.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(Self.palette[i % Self.palette.count])
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 24)
                    .opacity(isActive ? 1 : 0)
                } else {
                    ForEach(pieces) { piece in
                        Image(systemName: piece.symbol)
                            .font(.system(size: piece.size, weight: .bold))
                            .foregroundStyle(piece.color)
                            .rotationEffect(.degrees(piece.rotation))
                            .position(x: piece.x * geo.size.width,
                                      y: isActive ? piece.endY * geo.size.height : piece.startY * geo.size.height)
                            .opacity(isActive ? 0 : 1)
                            .animation(.easeOut(duration: 1.4), value: isActive)
                    }
                }
            }
            .onAppear { regenerate() }
            .onChange(of: isActive) { _, newValue in
                if newValue { regenerate() }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func regenerate() {
        guard !reduceMotion else { return }
        pieces = (0..<26).map { _ in
            Piece(
                x: CGFloat.random(in: 0.05...0.95),
                startY: CGFloat.random(in: 0.30...0.45),
                endY: CGFloat.random(in: -0.10...0.10),
                symbol: Self.symbols.randomElement() ?? "star.fill",
                color: Self.palette.randomElement() ?? Theme.star,
                size: CGFloat.random(in: 16...30),
                rotation: Double.random(in: 0...360)
            )
        }
    }
}
