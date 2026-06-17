import SwiftUI

/// A subtle starfield backdrop. Static under Reduce Motion (or when the user disables the
/// starfield); otherwise stars twinkle very gently. Deterministic layout so it doesn't
/// reshuffle every redraw. Decorative — hidden from VoiceOver.
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
        var gen = SplitMix64(seed: 42)
        var made: [Star] = []
        for _ in 0..<starCount {
            made.append(Star(
                x: CGFloat(gen.unit()),
                y: CGFloat(gen.unit()),
                radius: CGFloat(0.6 + gen.unit() * 1.6),
                baseOpacity: 0.25 + gen.unit() * 0.55,
                phase: gen.unit() * 6.28
            ))
        }
        self.stars = made
    }

    var body: some View {
        let animate = !settings.reduceStarfield && !reduceMotion
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
