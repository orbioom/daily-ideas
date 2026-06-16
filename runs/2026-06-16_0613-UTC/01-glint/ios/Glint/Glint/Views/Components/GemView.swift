import SwiftUI

/// A single faceted gem tile. Renders color + distinct glyph + optional power badge.
struct GemView: View {
    let gem: Gem
    var size: CGFloat
    var selected: Bool = false
    var hinted: Bool = false
    var clearing: Bool = false
    var reduceMotion: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.rGem, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [gem.color.opacity(0.95), gem.color.opacity(0.65)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    // Faceted highlight.
                    RoundedRectangle(cornerRadius: Theme.rGem, style: .continuous)
                        .stroke(Color.white.opacity(0.35), lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    Triangle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: size * 0.42, height: size * 0.42)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.rGem, style: .continuous))
                }

            Image(systemName: gem.color.symbol)
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.25), radius: 1, y: 1)

            if let badge = gem.power.badgeSymbol {
                Image(systemName: badge)
                    .font(.system(size: size * 0.26, weight: .black))
                    .foregroundStyle(Theme.gold)
                    .padding(3)
                    .background(Circle().fill(Color.black.opacity(0.35)))
                    .offset(x: size * 0.26, y: -size * 0.26)
            }
        }
        .frame(width: size, height: size)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.rGem, style: .continuous)
                .stroke(Theme.gold, lineWidth: selected ? 3 : 0)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.rGem, style: .continuous)
                .stroke(.white, lineWidth: hinted ? 2.5 : 0)
                .opacity(hinted ? 0.9 : 0)
        )
        .scaleEffect(scaleValue)
        .opacity(clearing ? (reduceMotion ? 0.15 : 0.0) : 1)
        .animation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.7), value: selected)
    }

    private var scaleValue: CGFloat {
        if clearing { return reduceMotion ? 1.0 : 0.2 }
        if selected { return 1.08 }
        return 1.0
    }
}

/// Simple triangle for the faceted highlight.
private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
