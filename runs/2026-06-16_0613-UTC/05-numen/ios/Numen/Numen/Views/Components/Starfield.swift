import SwiftUI

/// A subtle deterministic starfield for headers — decorative, Reduce-Motion safe.
struct Starfield: View {
    var count: Int = 40
    var twinkle: Bool = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Star: Identifiable {
        let id: Int
        let x: CGFloat
        let y: CGFloat
        let r: CGFloat
        let baseOpacity: Double
        let phase: Double
    }

    private var stars: [Star] {
        var generator = SeededGenerator(seed: 7)
        return (0..<count).map { i in
            Star(
                id: i,
                x: CGFloat(Double.random(in: 0...1, using: &generator)),
                y: CGFloat(Double.random(in: 0...1, using: &generator)),
                r: CGFloat(Double.random(in: 0.6...1.8, using: &generator)),
                baseOpacity: Double.random(in: 0.15...0.7, using: &generator),
                phase: Double.random(in: 0...1, using: &generator)
            )
        }
    }

    var body: some View {
        GeometryReader { geo in
            if twinkle && !reduceMotion {
                TimelineView(.animation(minimumInterval: 0.5, paused: false)) { timeline in
                    Canvas { ctx, size in
                        let t = timeline.date.timeIntervalSinceReferenceDate
                        draw(ctx: ctx, size: size, time: t)
                    }
                }
            } else {
                Canvas { ctx, size in
                    draw(ctx: ctx, size: size, time: 0)
                }
            }
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    private func draw(ctx: GraphicsContext, size: CGSize, time: Double) {
        for star in stars {
            let twinkleFactor = 0.5 + 0.5 * sin(time * 0.8 + star.phase * 6.28)
            let opacity = reduceMotion ? star.baseOpacity : star.baseOpacity * (0.55 + 0.45 * twinkleFactor)
            let rect = CGRect(x: star.x * size.width, y: star.y * size.height, width: star.r, height: star.r)
            ctx.fill(Path(ellipseIn: rect), with: .color(Theme.accent.opacity(opacity)))
        }
    }
}

/// A tiny deterministic RNG so the starfield is stable across redraws.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed &+ 0x9E3779B97F4A7C15 }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
