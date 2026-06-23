import SwiftUI

/// The animated breathing pacer. Draws concentric glowing rings on a `Canvas`
/// whose radius tracks `fill` (0 contracted ... 1 expanded). Under Reduce Motion
/// the scale animation is suppressed and the orb holds a steady mid-size while the
/// surrounding text cues carry the pacing instead.
struct BreathingOrb: View {
    /// 0...1 expansion.
    var fill: Double
    var tint: Color
    var reduceMotion: Bool
    /// Big centered label (e.g. seconds remaining or phase cue).
    var centerText: String
    var caption: String

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let effectiveFill = reduceMotion ? 0.55 : fill
            ZStack {
                Canvas { context, size in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let maxR = min(size.width, size.height) / 2
                    let minR = maxR * 0.28
                    let r = minR + (maxR - minR) * CGFloat(effectiveFill)

                    // Outer glow halo.
                    let halo = Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r,
                                                      width: r * 2, height: r * 2))
                    context.fill(halo, with: .color(tint.opacity(0.16)))

                    // Layered rings for depth.
                    let rings: [(CGFloat, Double)] = [(1.0, 0.9), (0.78, 0.55), (0.55, 0.35)]
                    for (scale, opacity) in rings {
                        let rr = r * scale
                        let rect = CGRect(x: center.x - rr, y: center.y - rr, width: rr * 2, height: rr * 2)
                        context.stroke(Path(ellipseIn: rect),
                                       with: .color(tint.opacity(opacity)),
                                       lineWidth: 3)
                    }

                    // Soft solid core.
                    let coreR = r * 0.42
                    let core = Path(ellipseIn: CGRect(x: center.x - coreR, y: center.y - coreR,
                                                      width: coreR * 2, height: coreR * 2))
                    context.fill(core, with: .radialGradient(
                        Gradient(colors: [tint.opacity(0.55), tint.opacity(0.08)]),
                        center: center, startRadius: 0, endRadius: coreR))
                }
                .frame(width: side, height: side)

                VStack(spacing: 6) {
                    Text(centerText)
                        .font(.system(size: 52, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Theme.textPrimary)
                        .contentTransition(.numericText())
                    Text(caption)
                        .font(.headline)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Breathing pacer")
        .accessibilityValue("\(caption). \(centerText)")
    }
}
