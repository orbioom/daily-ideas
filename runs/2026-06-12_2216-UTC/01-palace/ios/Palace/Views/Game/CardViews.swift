import SwiftUI

/// A single playing card. Ivory face, serif rank, brass-edged back.
struct CardView: View {
    let card: Card
    let width: CGFloat
    var shaking: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var height: CGFloat { width * 1.45 }
    private var inkColor: Color { card.isRed ? PalaceTheme.cardRed : PalaceTheme.cardInk }

    var body: some View {
        ZStack {
            if card.faceUp {
                face
            } else {
                back
            }
        }
        .frame(width: width, height: height)
        .offset(x: shaking && !reduceMotion ? -5 : 0)
        .animation(
            shaking && !reduceMotion
                ? .linear(duration: 0.06).repeatCount(5, autoreverses: true)
                : .default,
            value: shaking
        )
        .accessibilityLabel(card.faceUp ? card.accessibilityName : "Face-down card")
    }

    private var face: some View {
        RoundedRectangle(cornerRadius: width * 0.12, style: .continuous)
            .fill(PalaceTheme.cardFace)
            .overlay(
                RoundedRectangle(cornerRadius: width * 0.12, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.18), lineWidth: 0.8)
            )
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: -1) {
                    Text(card.rank.label)
                        .font(.system(size: width * 0.30, weight: .semibold, design: .serif))
                    Text(card.suit.symbol)
                        .font(.system(size: width * 0.24))
                }
                .foregroundStyle(inkColor)
                .padding(.leading, width * 0.10)
                .padding(.top, width * 0.06)
            }
            .overlay(alignment: .bottomTrailing) {
                Text(card.suit.symbol)
                    .font(.system(size: width * 0.42))
                    .foregroundStyle(inkColor.opacity(0.85))
                    .padding([.trailing, .bottom], width * 0.10)
            }
            .shadow(color: .black.opacity(0.25), radius: 1.5, y: 1)
    }

    private var back: some View {
        RoundedRectangle(cornerRadius: width * 0.12, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color(red: 0.16, green: 0.22, blue: 0.38), Color(red: 0.10, green: 0.14, blue: 0.26)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: width * 0.08, style: .continuous)
                    .strokeBorder(PalaceTheme.gold.opacity(0.55), lineWidth: 1.2)
                    .padding(width * 0.08)
            )
            .overlay(
                Image(systemName: "seal.fill")
                    .font(.system(size: width * 0.26))
                    .foregroundStyle(PalaceTheme.gold.opacity(0.45))
            )
            .overlay(
                RoundedRectangle(cornerRadius: width * 0.12, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.3), lineWidth: 0.8)
            )
            .shadow(color: .black.opacity(0.25), radius: 1.5, y: 1)
    }
}

/// Dashed outline for an empty pile, with an optional hint glyph.
struct PilePlaceholder: View {
    let width: CGFloat
    var glyph: String? = nil

    var body: some View {
        RoundedRectangle(cornerRadius: width * 0.12, style: .continuous)
            .strokeBorder(Color.white.opacity(0.35), style: StrokeStyle(lineWidth: 1.2, dash: [5, 4]))
            .frame(width: width, height: width * 1.45)
            .overlay {
                if let glyph {
                    Image(systemName: glyph)
                        .font(.system(size: width * 0.32))
                        .foregroundStyle(Color.white.opacity(0.3))
                }
            }
            .accessibilityHidden(true)
    }
}
