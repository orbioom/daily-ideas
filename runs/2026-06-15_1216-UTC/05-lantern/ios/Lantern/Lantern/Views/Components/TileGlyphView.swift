import SwiftUI

/// Draws the face glyph of a tile (suit symbol + value). Resolution-independent,
/// scales to fill its frame. Decorative for VoiceOver (the parent labels it).
struct TileGlyphView: View {
    let face: TileFace
    var tint: Color = Theme.accent

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            content(side: side)
                .frame(width: geo.size.width, height: geo.size.height)
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func content(side: CGFloat) -> some View {
        switch face {
        case .circles(let n):
            DotsGlyph(count: n, color: tint)
        case .bamboo(let n):
            BambooGlyph(count: n, color: Theme.good)
        case .characters(let n):
            CharactersGlyph(value: n, color: tint)
        case .wind(let w):
            HonorGlyph(text: windText(w), color: tint, side: side)
        case .dragon(let d):
            DragonGlyph(dragon: d, side: side)
        case .flower(let f):
            FlowerGlyph(flower: f, side: side)
        case .season(let s):
            SeasonGlyph(season: s, side: side)
        }
    }

    private func windText(_ w: TileFace.Wind) -> String {
        switch w {
        case .east: return "E"
        case .south: return "S"
        case .west: return "W"
        case .north: return "N"
        }
    }
}

// MARK: - Circles (dots) — arranged dot patterns

private struct DotsGlyph: View {
    let count: Int
    let color: Color
    var body: some View {
        GeometryReader { g in
            let s = min(g.size.width, g.size.height)
            let positions = DotsGlyph.layout(for: max(1, min(9, count)))
            ZStack {
                ForEach(Array(positions.enumerated()), id: \.offset) { _, p in
                    Circle()
                        .fill(color)
                        .overlay(Circle().strokeBorder(color.opacity(0.4), lineWidth: s * 0.012))
                        .frame(width: s * 0.22, height: s * 0.22)
                        .position(x: g.size.width * p.x, y: g.size.height * p.y)
                }
            }
        }
        .padding(2)
    }

    /// Normalized dot positions (0...1) per count, in a 3×3 feel.
    static func layout(for n: Int) -> [CGPoint] {
        let l: CGFloat = 0.25, m: CGFloat = 0.5, r: CGFloat = 0.75
        switch n {
        case 1: return [CGPoint(x: m, y: m)]
        case 2: return [CGPoint(x: m, y: l), CGPoint(x: m, y: r)]
        case 3: return [CGPoint(x: l, y: l), CGPoint(x: m, y: m), CGPoint(x: r, y: r)]
        case 4: return [CGPoint(x: l, y: l), CGPoint(x: r, y: l), CGPoint(x: l, y: r), CGPoint(x: r, y: r)]
        case 5: return [CGPoint(x: l, y: l), CGPoint(x: r, y: l), CGPoint(x: m, y: m), CGPoint(x: l, y: r), CGPoint(x: r, y: r)]
        case 6: return [CGPoint(x: l, y: l), CGPoint(x: r, y: l), CGPoint(x: l, y: m), CGPoint(x: r, y: m), CGPoint(x: l, y: r), CGPoint(x: r, y: r)]
        case 7: return [CGPoint(x: l, y: 0.18), CGPoint(x: m, y: 0.34), CGPoint(x: r, y: 0.5),
                        CGPoint(x: l, y: r), CGPoint(x: m, y: r), CGPoint(x: r, y: r), CGPoint(x: r, y: 0.5)]
        case 8: return [CGPoint(x: l, y: 0.2), CGPoint(x: r, y: 0.2), CGPoint(x: l, y: 0.4), CGPoint(x: r, y: 0.4),
                        CGPoint(x: l, y: 0.6), CGPoint(x: r, y: 0.6), CGPoint(x: l, y: 0.8), CGPoint(x: r, y: 0.8)]
        default: return [CGPoint(x: l, y: l), CGPoint(x: m, y: l), CGPoint(x: r, y: l),
                         CGPoint(x: l, y: m), CGPoint(x: m, y: m), CGPoint(x: r, y: m),
                         CGPoint(x: l, y: r), CGPoint(x: m, y: r), CGPoint(x: r, y: r)]
        }
    }
}

// MARK: - Bamboo — vertical sticks

private struct BambooGlyph: View {
    let count: Int
    let color: Color
    var body: some View {
        let n = max(1, min(9, count))
        VStack(spacing: 3) {
            if n == 1 {
                Stick(color: color).frame(maxWidth: .infinity)
            } else {
                // Arrange in up to two rows.
                let topCount = n <= 4 ? n : (n + 1) / 2
                let bottomCount = n - topCount
                row(topCount)
                if bottomCount > 0 { row(bottomCount) }
            }
        }
        .padding(4)
    }
    private func row(_ k: Int) -> some View {
        HStack(spacing: 3) {
            ForEach(0..<max(0, k), id: \.self) { _ in
                Stick(color: color)
            }
        }
    }
    private struct Stick: View {
        let color: Color
        var body: some View {
            GeometryReader { g in
                let w = g.size.width
                RoundedRectangle(cornerRadius: w * 0.35, style: .continuous)
                    .fill(color)
                    .overlay(
                        Rectangle()
                            .fill(color.opacity(0.55))
                            .frame(height: max(1, g.size.height * 0.06))
                            .position(x: w / 2, y: g.size.height / 2)
                    )
            }
        }
    }
}

// MARK: - Characters — Chinese numeral + 萬

private struct CharactersGlyph: View {
    let value: Int
    let color: Color
    private let numerals = ["一", "二", "三", "四", "五", "六", "七", "八", "九"]
    var body: some View {
        GeometryReader { g in
            let s = min(g.size.width, g.size.height)
            VStack(spacing: 0) {
                Text(numerals[safe: value - 1] ?? "\(value)")
                    .font(.system(size: s * 0.46, weight: .bold, design: .serif))
                    .foregroundStyle(color)
                Text("萬")
                    .font(.system(size: s * 0.4, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
            }
            .frame(width: g.size.width, height: g.size.height)
        }
    }
}

// MARK: - Honors (winds)

private struct HonorGlyph: View {
    let text: String
    let color: Color
    let side: CGFloat
    var body: some View {
        Text(text)
            .font(.system(size: side * 0.5, weight: .heavy, design: .rounded))
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Dragons

private struct DragonGlyph: View {
    let dragon: TileFace.Dragon
    let side: CGFloat
    var body: some View {
        switch dragon {
        case .red:
            Text("中")
                .font(.system(size: side * 0.62, weight: .bold, design: .serif))
                .foregroundStyle(Theme.accent)
        case .green:
            Text("發")
                .font(.system(size: side * 0.56, weight: .bold, design: .serif))
                .foregroundStyle(Theme.good)
        case .white:
            RoundedRectangle(cornerRadius: side * 0.12, style: .continuous)
                .strokeBorder(Theme.accent, lineWidth: max(2, side * 0.06))
                .padding(side * 0.18)
        }
    }
}

// MARK: - Flowers & Seasons (SF Symbols)

private struct FlowerGlyph: View {
    let flower: TileFace.Flower
    let side: CGFloat
    private var symbol: String {
        switch flower {
        case .plum: return "camera.macro"
        case .orchid: return "leaf.fill"
        case .bamboo: return "tree.fill"
        case .chrysanthemum: return "fan.fill"
        }
    }
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: "laurel.leading")
                .font(.system(size: side * 0.16))
                .foregroundStyle(Theme.gold)
                .accessibilityHidden(true)
            Image(systemName: symbol)
                .font(.system(size: side * 0.4))
                .foregroundStyle(Theme.gold)
        }
    }
}

private struct SeasonGlyph: View {
    let season: TileFace.Season
    let side: CGFloat
    private var symbol: String {
        switch season {
        case .spring: return "sun.max.fill"
        case .summer: return "sun.haze.fill"
        case .autumn: return "wind"
        case .winter: return "snowflake"
        }
    }
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: symbol)
                .font(.system(size: side * 0.42))
                .foregroundStyle(Theme.warn)
            Image(systemName: "laurel.trailing")
                .font(.system(size: side * 0.16))
                .foregroundStyle(Theme.warn)
                .accessibilityHidden(true)
        }
    }
}

// MARK: - Safe array indexing

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
