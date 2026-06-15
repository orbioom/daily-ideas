import SwiftUI

/// The signature animated ring: expands on Squeeze, holds, contracts on Relax/Rest.
struct BreathingRing: View {
    let moment: SessionMoment

    /// Eased scale derived from the phase + progress within the phase.
    private var scale: CGFloat {
        let base: CGFloat = 0.42
        let full: CGFloat = 1.0
        switch moment.phase {
        case .squeeze:
            // Grow from base to full across the squeeze.
            let p = CGFloat(moment.stepProgress)
            return base + (full - base) * easeInOut(p)
        case .hold:
            return full
        case .relax:
            // Shrink from full back to base.
            let p = CGFloat(moment.stepProgress)
            return full - (full - base) * easeInOut(p)
        case .rest:
            return base
        }
    }

    private func easeInOut(_ x: CGFloat) -> CGFloat {
        let c = min(1, max(0, x))
        return c * c * (3 - 2 * c)
    }

    var body: some View {
        ZStack {
            // Soft glow behind.
            Circle()
                .fill(Theme.ringGlow)
                .frame(width: 280, height: 280)
                .accessibilityHidden(true)

            // Outer guide ring.
            Circle()
                .stroke(Theme.hairline, lineWidth: 2)
                .frame(width: 240, height: 240)
                .accessibilityHidden(true)

            // The breathing disc.
            Circle()
                .fill(moment.phase.color.opacity(0.18))
                .overlay(
                    Circle().strokeBorder(moment.phase.color, lineWidth: 4)
                )
                .frame(width: 240, height: 240)
                .scaleEffect(scale)
                .animation(.easeInOut(duration: 0.25), value: scale)
                .accessibilityHidden(true)

            // Phase symbol at center.
            Image(systemName: moment.phase.symbol)
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(moment.phase.color)
                .scaleEffect(scale * 0.9 + 0.1)
                .animation(.easeInOut(duration: 0.25), value: scale)
                .accessibilityHidden(true)
        }
        .frame(height: 300)
    }
}

/// A calm, non-scaling alternative for Reduce Motion: a progress arc + symbol, no pulsing.
struct ReducedMotionRing: View {
    let moment: SessionMoment

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.hairline, lineWidth: 14)
                .frame(width: 220, height: 220)
            Circle()
                .trim(from: 0, to: CGFloat(min(1, max(0, moment.stepProgress))))
                .stroke(moment.phase.color, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 220, height: 220)
            Image(systemName: moment.phase.symbol)
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(moment.phase.color)
        }
        .frame(height: 300)
        .accessibilityHidden(true)
    }
}
