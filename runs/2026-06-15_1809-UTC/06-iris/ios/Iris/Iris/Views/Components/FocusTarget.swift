import SwiftUI

/// Iris's signature element: a calming focus dot with a soft halo.
/// Used both still (Reduce Motion / break completion) and moving along guided paths.
struct FocusDot: View {
    var size: CGFloat = 28
    var glow: Bool = true

    var body: some View {
        ZStack {
            if glow {
                Circle()
                    .fill(Theme.teal.opacity(0.30))
                    .frame(width: size * 2.4, height: size * 2.4)
                    .blur(radius: size * 0.4)
            }
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: 0x6FC8E8), Color(hex: 0x2F86B8)],
                        center: .center, startRadius: 0, endRadius: size * 0.7
                    )
                )
                .frame(width: size, height: size)
                .overlay(Circle().strokeBorder(Color.white.opacity(0.7), lineWidth: 1.5))
        }
        .accessibilityHidden(true)
    }
}

/// Computes a normalized point in [-1, 1] x [-1, 1] for a given exercise type and phase (0...1).
enum GuidedPath {
    /// `phase` is a looping 0...1 value (wall-clock driven).
    static func point(for type: ExerciseType, phase: Double) -> CGPoint {
        let t = phase.truncatingRemainder(dividingBy: 1)
        let angle = t * 2 * .pi
        switch type {
        case .figure8:
            // Lemniscate of Gerono: x = sin(t), y = sin(t)cos(t).
            let x = sin(angle)
            let y = sin(angle) * cos(angle) * 1.4
            return CGPoint(x: x, y: y)
        case .focusShift:
            // Smooth side-to-side sweep.
            return CGPoint(x: sin(angle), y: 0)
        case .rolling:
            // A wide circle.
            return CGPoint(x: cos(angle), y: sin(angle))
        case .nearFar:
            // A central pulse handled by scale, position stays centered.
            return .zero
        case .blinking, .palming:
            // Centered, no travel.
            return .zero
        }
    }

    /// Scale factor (used for near/far depth illusion), 0.55...1.0.
    static func scale(for type: ExerciseType, phase: Double) -> CGFloat {
        switch type {
        case .nearFar:
            let t = phase.truncatingRemainder(dividingBy: 1)
            // Ease between near (large) and far (small).
            let s = 0.55 + 0.45 * (0.5 + 0.5 * cos(t * 2 * .pi))
            return CGFloat(s)
        case .blinking:
            // A gentle pulse to pace blinks.
            let t = phase.truncatingRemainder(dividingBy: 1)
            return CGFloat(0.85 + 0.15 * (0.5 + 0.5 * sin(t * 2 * .pi)))
        default:
            return 1
        }
    }
}

/// The moving (or still) target an exercise asks the eyes to follow.
/// Under Reduce Motion the dot is centered and still; the instruction text guides instead.
struct GuidedTargetView: View {
    let type: ExerciseType
    /// A continuously increasing time value in seconds (from a TimelineView).
    let time: Double
    var travel: CGFloat = 120
    var reduceMotion: Bool = false

    /// One loop every `period` seconds for a slow, comfortable pace.
    private let period: Double = 5.0

    private var phase: Double {
        guard period > 0 else { return 0 }
        return (time / period).truncatingRemainder(dividingBy: 1)
    }

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let normalized: CGPoint = reduceMotion ? .zero : GuidedPath.point(for: type, phase: phase)
            let scale: CGFloat = reduceMotion ? 1 : GuidedPath.scale(for: type, phase: phase)
            let pos = CGPoint(x: center.x + normalized.x * travel,
                              y: center.y + normalized.y * travel)

            ZStack {
                // A faint guide path so the user knows where the dot travels.
                if !reduceMotion {
                    pathShape(in: geo.size)
                        .stroke(Theme.accent.opacity(0.18), style: StrokeStyle(lineWidth: 2, dash: [4, 7]))
                }
                FocusDot(size: 30 * scale)
                    .position(pos)
            }
        }
        .accessibilityHidden(true)
    }

    /// A faint dashed guide showing the travel path for the current type.
    private func pathShape(in size: CGSize) -> Path {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        switch type {
        case .figure8:
            return Path { p in
                var first = true
                for i in 0...60 {
                    let pt = GuidedPath.point(for: .figure8, phase: Double(i) / 60)
                    let cg = CGPoint(x: center.x + pt.x * travel, y: center.y + pt.y * travel)
                    if first { p.move(to: cg); first = false } else { p.addLine(to: cg) }
                }
            }
        case .rolling:
            return Path { p in
                p.addEllipse(in: CGRect(x: center.x - travel, y: center.y - travel,
                                        width: travel * 2, height: travel * 2))
            }
        case .focusShift:
            return Path { p in
                p.move(to: CGPoint(x: center.x - travel, y: center.y))
                p.addLine(to: CGPoint(x: center.x + travel, y: center.y))
            }
        default:
            return Path()
        }
    }
}
