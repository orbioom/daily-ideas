import SwiftUI

/// Fully generated, on-brand card art — no external/photographic assets. Each card is a cohesive
/// stylized vector keyed by suit/element: a bordered frame, a starry field, a central emblem,
/// pips (for spot cards) or a roman numeral/court mark, and the card name. Reversed cards render
/// rotated 180°.
struct CardArtView: View {
    let card: TarotCard
    var reversed: Bool = false
    /// Show the name strip at the bottom of the card.
    var showName: Bool = true

    private var keyColor: Color {
        card.suit?.color ?? Theme.accent
    }

    private var emblem: String {
        if let suit = card.suit { return suit.symbol }
        return CardArtView.majorEmblem(for: card.id)
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                // Parchment-on-night base
                RoundedRectangle(cornerRadius: w * 0.07, style: .continuous)
                    .fill(
                        LinearGradient(colors: [keyColor.opacity(0.22), Theme.surface],
                                       startPoint: .top, endPoint: .bottom)
                    )

                // Decorative inner frame
                RoundedRectangle(cornerRadius: w * 0.055, style: .continuous)
                    .strokeBorder(keyColor.opacity(0.55), lineWidth: max(1, w * 0.012))
                    .padding(w * 0.05)

                RoundedRectangle(cornerRadius: w * 0.045, style: .continuous)
                    .strokeBorder(Theme.gold.opacity(0.45), lineWidth: max(0.5, w * 0.006))
                    .padding(w * 0.075)

                VStack(spacing: 0) {
                    // Top rank label
                    Text(card.rankLabel)
                        .font(Theme.serif(w * 0.13, .semibold))
                        .foregroundStyle(Theme.gold)
                        .frame(maxWidth: .infinity)
                        .padding(.top, h * 0.07)

                    Spacer(minLength: 0)

                    // Central emblem + radiant halo + pips
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(colors: [keyColor.opacity(0.45), .clear],
                                               center: .center, startRadius: 0, endRadius: w * 0.4)
                            )
                            .frame(width: w * 0.7, height: w * 0.7)

                        // Spot-card pips arranged in a ring (Ace–10); else just the emblem.
                        if card.pipCount > 1 {
                            pipRing(in: w, color: keyColor)
                        }

                        Image(systemName: emblem)
                            .font(.system(size: w * 0.26, weight: .regular))
                            .foregroundStyle(keyColor)
                            .shadow(color: keyColor.opacity(0.5), radius: w * 0.03)
                    }
                    .frame(maxWidth: .infinity)

                    Spacer(minLength: 0)

                    if showName {
                        Text(card.name)
                            .font(Theme.serif(w * 0.085, .medium))
                            .foregroundStyle(Theme.ink)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.6)
                            .padding(.horizontal, w * 0.1)
                            .padding(.bottom, h * 0.07)
                    } else {
                        Spacer().frame(height: h * 0.07)
                    }
                }
            }
            .rotationEffect(.degrees(reversed ? 180 : 0))
        }
        .aspectRatio(0.62, contentMode: .fit)
        .accessibilityHidden(true)
    }

    /// A ring of small star pips representing the spot-card number.
    @ViewBuilder
    private func pipRing(in w: CGFloat, color: Color) -> some View {
        let n = card.pipCount
        ZStack {
            ForEach(0..<n, id: \.self) { i in
                let angle = Double(i) / Double(n) * 2 * .pi - .pi / 2
                Image(systemName: "sparkle")
                    .font(.system(size: w * 0.05))
                    .foregroundStyle(Theme.gold.opacity(0.8))
                    .offset(x: cos(angle) * w * 0.28, y: sin(angle) * w * 0.28)
            }
        }
    }

    /// A distinct SF Symbol emblem for each Major Arcana card, chosen to evoke its theme.
    static func majorEmblem(for id: Int) -> String {
        switch id {
        case 0: return "figure.walk"            // The Fool
        case 1: return "wand.and.stars"         // The Magician
        case 2: return "moon.stars"             // High Priestess
        case 3: return "leaf"                   // The Empress
        case 4: return "crown"                  // The Emperor
        case 5: return "building.columns"       // The Hierophant
        case 6: return "heart"                  // The Lovers
        case 7: return "shield.lefthalf.filled" // The Chariot
        case 8: return "infinity"               // Strength
        case 9: return "lantern"                // The Hermit
        case 10: return "circle.dotted"         // Wheel of Fortune
        case 11: return "scalemass"             // Justice
        case 12: return "arrow.down"            // The Hanged Man
        case 13: return "hourglass"             // Death
        case 14: return "drop.triangle"         // Temperance
        case 15: return "flame"                 // The Devil
        case 16: return "bolt"                  // The Tower
        case 17: return "star"                  // The Star
        case 18: return "moonphase.waning.gibbous" // The Moon
        case 19: return "sun.max"               // The Sun
        case 20: return "bell"                  // Judgement
        case 21: return "globe"                 // The World
        default: return "sparkles"
        }
    }
}

/// The decorative back of a card before it's revealed, themed by the user's deck choice.
struct CardBackView: View {
    var theme: DeckTheme = .midnight

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                RoundedRectangle(cornerRadius: w * 0.07, style: .continuous)
                    .fill(LinearGradient(colors: theme.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                RoundedRectangle(cornerRadius: w * 0.05, style: .continuous)
                    .strokeBorder(Theme.gold.opacity(0.6), lineWidth: max(1, w * 0.01))
                    .padding(w * 0.06)
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: w * 0.3))
                    .foregroundStyle(Theme.gold.opacity(0.85))
            }
        }
        .aspectRatio(0.62, contentMode: .fit)
        .accessibilityHidden(true)
    }
}
