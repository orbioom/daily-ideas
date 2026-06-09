import SwiftUI

/// A small upright/reversed orientation badge.
struct OrientationBadge: View {
    let reversed: Bool
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: reversed ? "arrow.uturn.down" : "arrow.up")
                .font(.system(size: 9, weight: .bold))
                .accessibilityHidden(true)
            Text(reversed ? "Reversed" : "Upright")
                .font(Brand.mono(11, weight: .semibold))
        }
        .foregroundStyle(reversed ? Brand.warn : Brand.magic)
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background((reversed ? Brand.warn : Brand.magic).opacity(0.15), in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(reversed ? "Reversed" : "Upright")
    }
}

/// The illustrated "face" of a tarot card: symbol, name, arcana, orientation.
/// `size` controls the overall scale (.large for hero placements, .compact for
/// grids/lists). Reversed cards flip their glyph 180°.
struct CardFace: View {
    let card: TarotCard
    var reversed: Bool = false
    var size: Size = .large

    enum Size { case large, medium, compact }

    private var glyphSize: CGFloat {
        switch size {
        case .large: return 64
        case .medium: return 44
        case .compact: return 30
        }
    }
    private var height: CGFloat {
        switch size {
        case .large: return 300
        case .medium: return 200
        case .compact: return 150
        }
    }

    private var accentGradient: LinearGradient {
        LinearGradient(colors: [Brand.magic.opacity(0.22), Brand.info.opacity(0.10)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var body: some View {
        VStack(spacing: size == .compact ? 8 : 14) {
            Eyebrow(text: card.arcana == .major ? "Major Arcana" : (card.suit?.title ?? "Minor Arcana"))

            Image(systemName: card.symbol)
                .font(.system(size: glyphSize, weight: .light))
                .foregroundStyle(Brand.magic)
                .rotationEffect(.degrees(reversed ? 180 : 0))
                .accessibilityHidden(true)

            Text(card.name)
                .font(size == .compact ? .subheadline.weight(.semibold) : .title3.weight(.semibold))
                .foregroundStyle(Brand.text)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)

            if size != .compact {
                OrientationBadge(reversed: reversed)
            }
        }
        .padding(size == .compact ? 12 : 20)
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(accentGradient))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: Brand.cardShadow, radius: 12, x: 0, y: 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(card.name), \(reversed ? "reversed" : "upright")")
        .accessibilityHint(card.arcana == .major ? "Major Arcana card" : "\(card.suit?.title ?? "Minor Arcana") card")
    }
}

/// The reverse (un-revealed) side of a card, using the selected deck-back style.
struct CardBack: View {
    var deckBack: DeckBack = .midnight
    var height: CGFloat = 300

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(deckBack.gradient)
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(.white.opacity(0.85))
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.white.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: Brand.cardShadow, radius: 12, x: 0, y: 6)
        .accessibilityHidden(true)
    }
}

/// A row of keyword chips wrapping with FlowLayout.
struct KeywordChips: View {
    let keywords: [String]
    var tint: Color = Brand.info
    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(keywords, id: \.self) { word in
                TagChip(text: word, tint: tint)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Keywords: \(keywords.joined(separator: ", "))")
    }
}
