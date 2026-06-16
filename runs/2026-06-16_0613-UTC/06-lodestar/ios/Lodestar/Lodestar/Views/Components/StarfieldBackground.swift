import SwiftUI

/// A quiet decorative starfield. When Reduce Motion is on, it renders a still field
/// (no twinkle). Purely decorative — hidden from accessibility.
struct StarfieldBackground: View {
    let reduceMotion: Bool

    private struct Speck: Identifiable {
        let id = Int.random(in: 0...Int.max)
        let x: Double
        let y: Double
        let r: Double
        let baseOpacity: Double
        let phase: Double
    }

    private let specks: [Speck]

    init(reduceMotion: Bool, count: Int = 90) {
        self.reduceMotion = reduceMotion
        var rng = SystemRandomNumberGenerator()
        var arr: [Speck] = []
        for _ in 0..<count {
            arr.append(Speck(
                x: Double.random(in: 0...1, using: &rng),
                y: Double.random(in: 0...1, using: &rng),
                r: Double.random(in: 0.4...1.6, using: &rng),
                baseOpacity: Double.random(in: 0.2...0.9, using: &rng),
                phase: Double.random(in: 0...(2 * Double.pi), using: &rng)
            ))
        }
        self.specks = arr
    }

    var body: some View {
        if reduceMotion {
            Canvas { ctx, size in
                draw(ctx: ctx, size: size, twinkle: 0)
            }
        } else {
            TimelineView(.animation(minimumInterval: 0.1, paused: false)) { tl in
                let t = tl.date.timeIntervalSinceReferenceDate
                Canvas { ctx, size in
                    draw(ctx: ctx, size: size, twinkle: t)
                }
            }
        }
    }

    private func draw(ctx: GraphicsContext, size: CGSize, twinkle: Double) {
        for s in specks {
            let px = s.x * size.width
            let py = s.y * size.height
            var opacity = s.baseOpacity
            if twinkle != 0 {
                let flicker = 0.5 + 0.5 * sin(twinkle * 0.8 + s.phase)
                opacity = s.baseOpacity * (0.55 + 0.45 * flicker)
            }
            let rect = CGRect(x: px - s.r, y: py - s.r, width: s.r * 2, height: s.r * 2)
            ctx.fill(Path(ellipseIn: rect), with: .color(.white.opacity(opacity)))
        }
    }
}
