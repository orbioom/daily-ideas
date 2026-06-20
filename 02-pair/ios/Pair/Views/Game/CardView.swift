import SwiftUI
import CoreHaptics

struct CardView: View {
    let card: FlipEngine.Card
    let theme: CardTheme
    let gridSize: GridSize
    let hapticEnabled: Bool
    let colorBlindMode: Bool
    let onTap: () -> Void

    private var cardSize: CGFloat { PairTheme.cardSize(for: gridSize) }
    private var fontSize: CGFloat { PairTheme.fontSize(for: gridSize) }
    private var isFlipped: Bool { card.state == .faceUp || card.state == .matched }
    private var isClassic: Bool { theme == .classic }

    var body: some View {
        ZStack {
            // Back face
            cardBack
                .rotation3DEffect(
                    .degrees(isFlipped ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.5
                )
                .opacity(isFlipped ? 0 : 1)

            // Front face
            cardFront
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : -180),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.5
                )
                .opacity(isFlipped ? 1 : 0)
        }
        .frame(width: cardSize, height: cardSize)
        .opacity(card.state == .matched ? 0.45 : 1.0)
        .overlay {
            if card.state == .matched {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.white.opacity(0.7))
                    .font(.system(size: fontSize * 0.6))
            }
        }
        .animation(.spring(duration: 0.4), value: card.state)
        .onTapGesture {
            if card.state == .faceDown {
                if hapticEnabled {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }
                onTap()
            }
        }
    }

    private var cardBack: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(theme.cardBackColor)
            .overlay {
                ZStack {
                    // Subtle pattern
                    ForEach(0..<3) { i in
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            .padding(CGFloat(i + 1) * 6)
                    }
                    Image(systemName: "sparkles")
                        .font(.system(size: fontSize * 0.5))
                        .foregroundStyle(Color.white.opacity(0.2))
                }
            }
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
    }

    private var cardFront: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(theme.accentColor.opacity(0.15))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(theme.accentColor.opacity(0.5), lineWidth: 1.5)
            }
            .overlay {
                if isClassic {
                    Image(systemName: card.symbol)
                        .font(.system(size: fontSize))
                        .foregroundStyle(theme.accentColor)
                } else {
                    Text(card.symbol)
                        .font(.system(size: fontSize))
                }
            }
            .shadow(color: theme.accentColor.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    HStack(spacing: 12) {
        CardView(
            card: FlipEngine.Card(id: UUID(), pairID: 0, symbol: "🐶", state: .faceDown),
            theme: .animals,
            gridSize: .easy,
            hapticEnabled: false,
            colorBlindMode: false,
            onTap: {}
        )
        CardView(
            card: FlipEngine.Card(id: UUID(), pairID: 1, symbol: "🐱", state: .faceUp),
            theme: .animals,
            gridSize: .easy,
            hapticEnabled: false,
            colorBlindMode: false,
            onTap: {}
        )
        CardView(
            card: FlipEngine.Card(id: UUID(), pairID: 2, symbol: "🦊", state: .matched),
            theme: .animals,
            gridSize: .easy,
            hapticEnabled: false,
            colorBlindMode: false,
            onTap: {}
        )
    }
    .padding()
    .background(PairTheme.background)
}
