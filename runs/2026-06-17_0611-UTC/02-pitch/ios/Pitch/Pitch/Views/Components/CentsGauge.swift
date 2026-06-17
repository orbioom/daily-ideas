import SwiftUI

/// A precise tuner gauge: an arc with tick marks and a needle that swings from
/// −50 cents (left) to +50 cents (right). Glows green when in tune. Honors
/// Reduce Motion by snapping the needle instead of animating it.
struct CentsGauge: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Cents offset to display (−50…+50). nil == no signal (needle centered, dim).
    let cents: Double?
    /// Whether the current reading is within the in-tune tolerance.
    let inTune: Bool
    /// Tolerance band (± cents) to shade behind the needle.
    let tolerance: Double

    private var clampedCents: Double { min(max(cents ?? 0, -50), 50) }
    private var hasSignal: Bool { cents != nil }

    /// Map cents (−50…50) to a needle angle (−45°…+45°).
    private var needleAngle: Angle { .degrees(clampedCents / 50.0 * 45.0) }

    private var tintColor: Color {
        guard hasSignal else { return PitchTheme.secondaryText(scheme) }
        if inTune { return PitchTheme.inTune }
        let mag = abs(clampedCents)
        return mag < 15 ? PitchTheme.nearTune : PitchTheme.offTune
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                arc
                ticks
                centerTolerance
                needle
            }
            .frame(height: 150)
            .frame(maxWidth: .infinity)

            // Numeric cents readout below the gauge in monospaced numerals.
            HStack(spacing: 6) {
                Text(centsText)
                    .font(PitchTheme.mono(20, weight: .semibold))
                    .foregroundStyle(tintColor)
                Text("cents")
                    .font(.caption)
                    .foregroundStyle(PitchTheme.secondaryText(scheme))
            }
        }
        .accessibilityHidden(true) // The textual readout above carries the value.
    }

    private var centsText: String {
        guard hasSignal else { return "—" }
        let rounded = Int(clampedCents.rounded())
        return rounded > 0 ? "+\(rounded)" : "\(rounded)"
    }

    private var arc: some View {
        Arc(startAngle: .degrees(180 + 45), endAngle: .degrees(360 - 45))
            .strokeBorder(PitchTheme.track(scheme), lineWidth: 10)
    }

    private var ticks: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height)
            let radius = min(geo.size.width, geo.size.height * 2) / 2 - 14
            ZStack {
                ForEach(-5...5, id: \.self) { i in
                    let frac = Double(i) / 5.0       // −1…1
                    let deg = frac * 45.0
                    tick(center: center, radius: radius, degrees: deg, major: i == 0)
                }
            }
        }
    }

    private func tick(center: CGPoint, radius: CGFloat, degrees: Double, major: Bool) -> some View {
        let rad = (degrees - 90) * .pi / 180
        let inner = radius - (major ? 16 : 9)
        let p1 = CGPoint(x: center.x + CGFloat(cos(rad)) * inner,
                         y: center.y + CGFloat(sin(rad)) * inner)
        let p2 = CGPoint(x: center.x + CGFloat(cos(rad)) * radius,
                         y: center.y + CGFloat(sin(rad)) * radius)
        return Path { path in
            path.move(to: p1)
            path.addLine(to: p2)
        }
        .stroke(major ? PitchTheme.indigo : PitchTheme.secondaryText(scheme).opacity(0.6),
                lineWidth: major ? 3 : 1.5)
    }

    /// A subtle shaded wedge marking the in-tune tolerance band.
    private var centerTolerance: some View {
        let span = min(tolerance, 50) / 50.0 * 45.0
        return Arc(startAngle: .degrees(270 - span), endAngle: .degrees(270 + span))
            .strokeBorder(PitchTheme.inTune.opacity(hasSignal && inTune ? 0.45 : 0.18), lineWidth: 10)
    }

    private var needle: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height)
            let length = min(geo.size.width, geo.size.height * 2) / 2 - 18
            ZStack {
                Capsule()
                    .fill(tintColor)
                    .frame(width: 4, height: length)
                    .offset(y: -length / 2)
                    .rotationEffect(needleAngle, anchor: .bottom)
                    .opacity(hasSignal ? 1 : 0.4)
                    .shadow(color: inTune ? PitchTheme.inTune.opacity(0.7) : .clear,
                            radius: inTune ? 8 : 0)
                Circle()
                    .fill(tintColor)
                    .frame(width: 14, height: 14)
            }
            .position(center)
            .animation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.7),
                       value: clampedCents)
        }
    }
}

/// A simple arc shape between two angles.
private struct Arc: InsettableShape {
    var startAngle: Angle
    var endAngle: Angle
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.maxY)
        let radius = min(rect.width, rect.height * 2) / 2 - insetAmount
        var path = Path()
        path.addArc(center: center,
                    radius: max(radius, 0),
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: false)
        return path
    }

    func inset(by amount: CGFloat) -> some InsettableShape {
        var copy = self
        copy.insetAmount += amount
        return copy
    }
}
