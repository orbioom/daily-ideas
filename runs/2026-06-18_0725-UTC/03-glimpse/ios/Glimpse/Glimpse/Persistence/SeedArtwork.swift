import UIKit

/// Renders tasteful gradient + film-grain JPEG images at seed time, since the
/// app ships with no real photos. Deterministic per seed so a moment keeps a
/// consistent look.
enum SeedArtwork {
    /// Palette of warm, editorial gradient pairs.
    private static let palettes: [(UInt, UInt)] = [
        (0xF2664B, 0xE0567E),
        (0xF09A5A, 0xE0567E),
        (0x5C86C0, 0x8E6FB0),
        (0xCBA94B, 0xE08A4E),
        (0x2E9E6B, 0x5C86C0),
        (0xE0567E, 0x8E6FB0),
        (0xE08A4E, 0xCBA94B),
        (0x8E6FB0, 0x5C86C0)
    ]

    static func make(seed: Int, size: CGSize = CGSize(width: 1000, height: 1000)) -> UIImage {
        let index = abs(seed) % palettes.count
        let (a, b) = palettes[index]
        var generator = SeededRandom(seed: UInt64(abs(seed) &+ 1))

        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = true
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            let cg = ctx.cgContext
            let rect = CGRect(origin: .zero, size: size)

            // Diagonal gradient base.
            let colors = [Self.cgColor(a), Self.cgColor(b)] as CFArray
            if let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors,
                locations: [0, 1]
            ) {
                cg.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: size.width, y: size.height),
                    options: []
                )
            } else {
                Self.uiColor(a).setFill()
                cg.fill(rect)
            }

            // A couple of soft radial blooms for depth.
            for _ in 0..<3 {
                let cx = CGFloat(generator.nextUnit()) * size.width
                let cy = CGFloat(generator.nextUnit()) * size.height
                let radius = (0.25 + CGFloat(generator.nextUnit()) * 0.35) * size.width
                let bloomColor = Self.uiColor(generator.nextUnit() > 0.5 ? a : b)
                    .withAlphaComponent(0.30)
                let bloom = [bloomColor.cgColor, bloomColor.withAlphaComponent(0).cgColor] as CFArray
                if let g = CGGradient(
                    colorsSpace: CGColorSpaceCreateDeviceRGB(),
                    colors: bloom,
                    locations: [0, 1]
                ) {
                    cg.drawRadialGradient(
                        g,
                        startCenter: CGPoint(x: cx, y: cy), startRadius: 0,
                        endCenter: CGPoint(x: cx, y: cy), endRadius: radius,
                        options: []
                    )
                }
            }

            // Subtle film grain.
            cg.setBlendMode(.overlay)
            let dots = 1400
            for _ in 0..<dots {
                let x = CGFloat(generator.nextUnit()) * size.width
                let y = CGFloat(generator.nextUnit()) * size.height
                let w = 1.0 + CGFloat(generator.nextUnit()) * 1.5
                let bright = generator.nextUnit() > 0.5
                let alpha = 0.04 + CGFloat(generator.nextUnit()) * 0.06
                (bright ? UIColor.white : UIColor.black)
                    .withAlphaComponent(alpha)
                    .setFill()
                cg.fill(CGRect(x: x, y: y, width: w, height: w))
            }

            // Gentle vignette.
            cg.setBlendMode(.normal)
            let vignette = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.22).cgColor] as CFArray
            if let g = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: vignette,
                locations: [0.55, 1]
            ) {
                let c = CGPoint(x: size.width / 2, y: size.height / 2)
                cg.drawRadialGradient(
                    g,
                    startCenter: c, startRadius: 0,
                    endCenter: c, endRadius: max(size.width, size.height) * 0.72,
                    options: []
                )
            }
        }
    }

    private static func uiColor(_ hex: UInt) -> UIColor {
        UIColor(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }

    private static func cgColor(_ hex: UInt) -> CGColor { uiColor(hex).cgColor }
}

/// Tiny deterministic PRNG (SplitMix64) so seeded art is reproducible.
struct SeededRandom {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    /// Uniform Double in [0, 1).
    mutating func nextUnit() -> Double {
        Double(next() >> 11) * (1.0 / 9007199254740992.0)
    }

    /// Uniform Int in `range` (non-empty range assumed by callers).
    mutating func nextInt(in range: Range<Int>) -> Int {
        guard range.lowerBound < range.upperBound else { return range.lowerBound }
        let span = UInt64(range.upperBound - range.lowerBound)
        return range.lowerBound + Int(next() % span)
    }
}
