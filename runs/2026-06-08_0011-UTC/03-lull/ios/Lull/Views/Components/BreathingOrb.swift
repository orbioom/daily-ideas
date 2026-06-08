import SwiftUI

/// The Orbioom orb, breathing. A radial silver core with soft rings that scale
/// with the breath. Honors Reduce Motion (falls back to a gentle opacity cue).
struct BreathingOrb: View {
    var scale: CGFloat          // 0.45 ... 1.0
    var tint: Color
    var reduceMotion: Bool

    var body: some View {
        ZStack {
            // Outer glow rings
            ForEach(0..<3) { i in
                Circle()
                    .stroke(tint.opacity(0.25 - Double(i) * 0.06), lineWidth: 2)
                    .scaleEffect(scale * (1.0 + CGFloat(i) * 0.16))
            }
            // Halo
            Circle()
                .fill(
                    RadialGradient(
                        colors: [tint.opacity(0.45), tint.opacity(0.05), .clear],
                        center: .center, startRadius: 4, endRadius: 220)
                )
                .scaleEffect(scale * 1.25)
                .blur(radius: 8)
            // Core orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.95), tint.opacity(0.85), tint.opacity(0.6)],
                        center: UnitPoint(x: 0.38, y: 0.32), startRadius: 6, endRadius: 180)
                )
                .overlay(
                    Circle().strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
                )
                .scaleEffect(reduceMotion ? 0.8 : scale)
                .shadow(color: tint.opacity(0.5), radius: 30)
        }
        .frame(width: 260, height: 260)
        .opacity(reduceMotion ? 0.6 + 0.4 * Double(scale) : 1)
        .accessibilityHidden(true)
    }
}

struct StatTile: View {
    var value: String
    var label: String
    var tint: Color = Brand.text
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(Brand.mono(22, weight: .semibold))
                .foregroundStyle(tint).monospacedDigit()
                .minimumScaleFactor(0.6).lineLimit(1)
            Text(label).font(.caption).foregroundStyle(Brand.text2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
