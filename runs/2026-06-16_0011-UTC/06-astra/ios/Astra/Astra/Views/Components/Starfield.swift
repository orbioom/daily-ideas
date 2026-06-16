import SwiftUI

/// A subtle starfield backdrop. Static under Reduce Motion (or when the user disables
/// star animation); otherwise stars twinkle very gently. Deterministic layout so it
/// doesn't reshuffle every redraw.
struct Starfield: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var settings: AppSettings

    var starCount: Int = 70

    private struct Star {
        let x: CGFloat
        let y: CGFloat
        let radius: CGFloat
        let baseOpacity: Double
        let phase: Double
    }

    private let stars: [Star]

    init(starCount: Int = 70) {
        self.starCount = starCount
        var generator = SeededRandom(seed: 42)
        var made: [Star] = []
        for _ in 0..<starCount {
            made.append(Star(
                x: CGFloat(generator.next()),
                y: CGFloat(generator.next()),
                radius: CGFloat(0.6 + generator.next() * 1.6),
                baseOpacity: 0.25 + generator.next() * 0.55,
                phase: generator.next() * 6.28
            ))
        }
        self.stars = made
    }

    var body: some View {
        let animate = settings.animateStars && !reduceMotion
        TimelineView(.animation(minimumInterval: animate ? 1.0 / 20.0 : nil, paused: !animate)) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                for star in stars {
                    let px = star.x * size.width
                    let py = star.y * size.height
                    let twinkle = animate ? (0.5 + 0.5 * sin(t * 1.5 + star.phase)) : 1
                    let opacity = star.baseOpacity * (0.5 + 0.5 * twinkle)
                    let rect = CGRect(x: px - star.radius, y: py - star.radius,
                                      width: star.radius * 2, height: star.radius * 2)
                    context.fill(Path(ellipseIn: rect),
                                 with: .color(Theme.gold.opacity(opacity)))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// A tiny deterministic PRNG so the starfield is stable across redraws.
struct SeededRandom {
    private var state: UInt64
    init(seed: UInt64) { state = seed &+ 0x9E3779B97F4A7C15 }
    /// Returns a Double in 0..<1.
    mutating func next() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        let bits = (state >> 11)
        return Double(bits) / Double(UInt64(1) << 53)
    }
}
